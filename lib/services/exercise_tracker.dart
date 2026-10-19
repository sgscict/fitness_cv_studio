import 'dart:math';
import '../models/coach_exercise.dart';
import '../models/pose_landmark.dart';
import '../models/user_fitness_profile.dart';

/// What a coaching cue is about, independent of its language.
enum CueKind { position, info, rep, detected, warning }

class CoachFrameResult {
  final CoachExercise exercise;
  final bool exerciseLocked; // chosen by the user
  final int reps;
  final String cue;
  final CueKind cueKind;
  final bool safetyWarning;
  final bool bodyVisible;
  final int peopleCount;
  final bool multiplePeopleDetected;
  final double activeSeconds;
  final double kcal;
  final Map<String, double> angles;

  const CoachFrameResult({
    required this.exercise,
    required this.exerciseLocked,
    required this.reps,
    required this.cue,
    this.cueKind = CueKind.info,
    required this.safetyWarning,
    required this.bodyVisible,
    this.peopleCount = 1,
    this.multiplePeopleDetected = false,
    required this.activeSeconds,
    required this.kcal,
    required this.angles,
  });
}

class _Sample {
  final double t;
  final Map<String, double> f;
  _Sample(this.t, this.f);
}

/// Turns a stream of MediaPipe pose frames into exercise recognition, rep counts,
/// joint-safety cues and an energy estimate.
/// All kinematics run on 33 MediaPipe BlazePose world landmarks (meters).
class ExerciseTracker {
  final UserFitnessProfile profile;
  CoachExercise _locked;
  CoachExercise _current = CoachExercise.auto;
  CoachExercise? _candidate;
  double _candidateSince = 0;

  final Map<CoachExercise, int> repsByExercise = {};
  bool _down = false; // rep phase for single-signal exercises
  bool _leftUp = false, _rightUp = false; // marching / alternating leg lifts

  String _cue = 'Step back so your whole body is in view.';
  CueKind _cueKind = CueKind.position;
  bool _warn = false;
  bool _wasVisible = false;
  double _activeSeconds = 0;
  double _kcal = 0;
  double? _lastT;
  double _lastMotionT = -100;
  final List<_Sample> _window = [];
  Map<String, double>? _prev;

  ExerciseTracker(
    this.profile, {
    CoachExercise exercise = CoachExercise.auto,
  }) : _locked = exercise {
    if (exercise != CoachExercise.auto) _current = exercise;
  }

  void _say(CueKind kind, String text) {
    _cueKind = kind;
    _cue = text;
  }

  set exercise(CoachExercise e) {
    _locked = e;
    _current = e == CoachExercise.auto ? CoachExercise.auto : e;
    _down = false;
    _leftUp = false;
    _rightUp = false;
  }

  CoachExercise get exercise => _current;
  bool get isUserLocked => _locked != CoachExercise.auto;
  int get reps => _current == CoachExercise.auto ? totalReps : (repsByExercise[_current] ?? 0);
  int get totalReps => repsByExercise.values.fold(0, (a, b) => a + b);
  double get kcal => _kcal;
  double get activeSeconds => _activeSeconds;

  /// Knee bend limit: configured from user profile, stops short of deep compressive squat.
  double get minKneeAngle =>
      profile.hasKneeSensitivity || profile.age >= 60 ? profile.targetSquatMinAngle : 80.0;

  /// 3D angle at [b] in degrees using MediaPipe world landmarks (metres).
  static double angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ux = a.x - b.x, uy = a.y - b.y, uz = a.z - b.z;
    final vx = c.x - b.x, vy = c.y - b.y, vz = c.z - b.z;
    final nu = sqrt(ux * ux + uy * uy + uz * uz), nv = sqrt(vx * vx + vy * vy + vz * vz);
    if (nu == 0 || nv == 0) return 180.0;
    final cosA = ((ux * vx + uy * vy + uz * vz) / (nu * nv)).clamp(-1.0, 1.0);
    return acos(cosA) * 180.0 / pi;
  }

  static double _torso(List<PoseLandmark> p) => max(
        0.05,
        ((p[PoseIdx.lHip].y + p[PoseIdx.rHip].y) - (p[PoseIdx.lShoulder].y + p[PoseIdx.rShoulder].y)).abs() / 2,
      );

  static bool _visible(List<PoseLandmark> p, List<int> idx, {double minVis = 0.45}) =>
      idx.every((i) => i < p.length && p[i].visibility >= minVis);

  /// Extracts biomechanical features and synthesizes virtual hips if hips are occluded.
  static Map<String, double>? features(List<PoseLandmark> rawPose) {
    if (rawPose.length < 29) return null;
    final p = List<PoseLandmark>.from(rawPose);

    // If hips have very low visibility (e.g. phone on desk for upper-body curls/raises/presses),
    // synthesize stable virtual hips below the shoulders so shoulder angles remain accurate.
    if (p[PoseIdx.lHip].visibility < 0.3 &&
        p[PoseIdx.rHip].visibility < 0.3 &&
        (p[PoseIdx.lShoulder].visibility >= 0.45 || p[PoseIdx.rShoulder].visibility >= 0.45)) {
      final ls = p[PoseIdx.lShoulder];
      final rs = p[PoseIdx.rShoulder];
      p[PoseIdx.lHip] = PoseLandmark(ls.x, ls.y + 0.48, ls.z, 0.6);
      p[PoseIdx.rHip] = PoseLandmark(rs.x, rs.y + 0.48, rs.z, 0.6);
    }

    PoseLandmark l(int i) => p[i];
    final torsoLen = _torso(p);

    final f = <String, double>{
      'kneeL': angle(l(PoseIdx.lHip), l(PoseIdx.lKnee), l(PoseIdx.lAnkle)),
      'kneeR': angle(l(PoseIdx.rHip), l(PoseIdx.rKnee), l(PoseIdx.rAnkle)),
      'elbowL': angle(l(PoseIdx.lShoulder), l(PoseIdx.lElbow), l(PoseIdx.lWrist)),
      'elbowR': angle(l(PoseIdx.rShoulder), l(PoseIdx.rElbow), l(PoseIdx.rWrist)),
      'shoulderL': angle(l(PoseIdx.lHip), l(PoseIdx.lShoulder), l(PoseIdx.lElbow)),
      'shoulderR': angle(l(PoseIdx.rHip), l(PoseIdx.rShoulder), l(PoseIdx.rElbow)),
      'hipL': angle(l(PoseIdx.lShoulder), l(PoseIdx.lHip), l(PoseIdx.lKnee)),
      'hipR': angle(l(PoseIdx.rShoulder), l(PoseIdx.rHip), l(PoseIdx.rKnee)),
      // knee height below the hip, in torso lengths (standing ≈ 0.7–0.9;
      // knee lifted to hip level ≈ 0–0.5). Vertical only, so reliable from the front.
      'liftL': (l(PoseIdx.lKnee).y - l(PoseIdx.lHip).y) / torsoLen,
      'liftR': (l(PoseIdx.rKnee).y - l(PoseIdx.rHip).y) / torsoLen,
      // wrist height relative to shoulder, in torso lengths (+ = above shoulder)
      'wristRel': (((l(PoseIdx.lShoulder).y - l(PoseIdx.lWrist).y) + (l(PoseIdx.rShoulder).y - l(PoseIdx.rWrist).y)) / 2) /
          max(0.05, ((l(PoseIdx.lHip).y + l(PoseIdx.rHip).y) - (l(PoseIdx.lShoulder).y + l(PoseIdx.rShoulder).y)).abs() / 2),
    };

    // Side view: the far limb is hidden and its angles are guesses. Measure
    // both sides from whichever side the camera can see.
    double vis(List<int> idx) => idx.map((i) => p[i].visibility).reduce(min);
    void mirror(String key, List<int> left, List<int> right) {
      final vl = vis(left), vr = vis(right);
      if (vl < 0.45 && vr >= 0.45) f['${key}L'] = f['${key}R']!;
      if (vr < 0.45 && vl >= 0.45) f['${key}R'] = f['${key}L']!;
    }

    mirror('knee', [PoseIdx.lHip, PoseIdx.lKnee, PoseIdx.lAnkle], [PoseIdx.rHip, PoseIdx.rKnee, PoseIdx.rAnkle]);
    mirror('hip', [PoseIdx.lShoulder, PoseIdx.lHip, PoseIdx.lKnee], [PoseIdx.rShoulder, PoseIdx.rHip, PoseIdx.rKnee]);
    mirror('lift', [PoseIdx.lHip, PoseIdx.lKnee], [PoseIdx.rHip, PoseIdx.rKnee]);
    mirror('elbow', [PoseIdx.lShoulder, PoseIdx.lElbow, PoseIdx.lWrist], [PoseIdx.rShoulder, PoseIdx.rElbow, PoseIdx.rWrist]);
    mirror('shoulder', [PoseIdx.lHip, PoseIdx.lShoulder, PoseIdx.lElbow], [PoseIdx.rHip, PoseIdx.rShoulder, PoseIdx.rElbow]);

    // Convenience display keys for UI Gauges
    f['activeKnee'] = min(f['kneeL']!, f['kneeR']!);
    f['activeElbow'] = (f['elbowL']! + f['elbowR']!) / 2;
    f['shoulderElev'] = max(f['shoulderL']!, f['shoulderR']!);
    f['activeHip'] = min(f['hipL']!, f['hipR']!);
    f['lKnee'] = f['kneeL']!;
    f['rKnee'] = f['kneeR']!;
    f['lElbow'] = f['elbowL']!;
    f['rElbow'] = f['elbowR']!;
    f['lShoulder'] = f['shoulderL']!;
    f['rShoulder'] = f['shoulderR']!;

    return f;
  }

  double _range(String key) {
    if (_window.isEmpty) return 0;
    var lo = double.infinity, hi = -double.infinity;
    for (final s in _window) {
      final v = s.f[key]!;
      lo = min(lo, v);
      hi = max(hi, v);
    }
    return hi - lo;
  }

  /// Average left–right knee difference: ~0 when knees bend together (squat),
  /// large when they alternate (marching).
  double _kneeAsymmetry() =>
      _window.isEmpty ? 0 : _window.map((s) => (s.f['kneeL']! - s.f['kneeR']!).abs()).reduce((a, b) => a + b) / _window.length;

  double _liftAsymmetry() =>
      _window.isEmpty ? 0 : _window.map((s) => (s.f['liftL']! - s.f['liftR']!).abs()).reduce((a, b) => a + b) / _window.length;

  double _mean(String key) =>
      _window.isEmpty ? 0 : _window.map((s) => s.f[key]!).reduce((a, b) => a + b) / _window.length;

  /// Picks the exercise whose characteristic joint is moving most in the last ~3 s.
  CoachExercise? _classify() {
    if (_window.length < 8) return null;
    final knee = (_range('kneeL') + _range('kneeR')) / 2;
    final kneeAsym = _kneeAsymmetry();
    final liftAsym = _liftAsymmetry();
    final liftRange = max(_range('liftL'), _range('liftR'));
    final hipL = _range('hipL'), hipR = _range('hipR');
    final elbow = (_range('elbowL') + _range('elbowR')) / 2;
    final shoulder = (_range('shoulderL') + _range('shoulderR')) / 2;
    final wristRel = _mean('wristRel');
    final armForward = (_mean('shoulderL') + _mean('shoulderR')) / 2;

    final scores = <CoachExercise, double>{
      // both knees bend together
      CoachExercise.squat: knee > 35 && kneeAsym < 15 && liftAsym < 0.12 ? knee : 0,
      // hips flex alternately while knees are bending unevenly
      CoachExercise.marching:
          (hipL > 25 || hipR > 25 || liftRange > 0.2) && (kneeAsym >= 15 || liftAsym >= 0.12) ? max(max(hipL, hipR), liftRange * 100) : 0,
      // arm lifts away from the body
      CoachExercise.armRaise: shoulder > 45 && elbow < 40 ? shoulder : 0,
      // overhead press: wrists above shoulders + shoulder & elbow moving
      CoachExercise.shoulderPress: wristRel > 0.05 && shoulder > 35 && elbow > 25 ? shoulder + elbow : 0,
      // elbow bends with upper arm still and hands below shoulders
      CoachExercise.bicepCurl: elbow > 35 && shoulder < 35 && armForward < 48 && wristRel < -0.2 ? elbow : 0,
      // elbow bends with arms reaching forward to a wall or counter
      CoachExercise.wallPushUp: elbow > 35 && armForward >= 48 && shoulder < 60 ? elbow : 0,
    };
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.value > 0 ? best.key : null;
  }

  void _addRep(CoachExercise e) {
    repsByExercise[e] = (repsByExercise[e] ?? 0) + 1;
    final n = repsByExercise[e]!;
    if (profile.hasHypertension && n % 5 == 0) {
      _say(CueKind.rep, 'Rep $n — keep breathing, don\'t hold your breath.');
    } else {
      _say(CueKind.rep, 'Rep $n — excellent control!');
    }
  }

  /// Main frame processing loop. Accepts 33 landmarks and elapsed time in seconds.
  CoachFrameResult update(
    List<PoseLandmark> pose,
    double t, {
    int peopleCount = 1,
  }) {
    final dt = _lastT == null ? 0.0 : (t - _lastT!).clamp(0.0, 1.0);
    _lastT = t;
    _warn = false;

    // 1. Single-person enforcement: pause tracking and warn if >1 person is detected.
    if (peopleCount > 1) {
      _warn = true;
      _wasVisible = false;
      _say(
        CueKind.warning,
        '⚠️ Multiple people detected ($peopleCount). Only one person should be in the camera frame.',
      );
      return _buildResult(false, const {}, peopleCount: peopleCount, multipleDetected: true);
    }

    // 2. Check full-body and upper-body visibility.
    final f = features(pose);
    final fullBodySeen = f != null &&
        (_visible(pose, [PoseIdx.lShoulder, PoseIdx.lHip, PoseIdx.lKnee], minVis: 0.45) ||
            _visible(pose, [PoseIdx.rShoulder, PoseIdx.rHip, PoseIdx.rKnee], minVis: 0.45));
    final upperBodyExercise = _locked == CoachExercise.armRaise ||
        _locked == CoachExercise.frontRaise ||
        _locked == CoachExercise.bicepCurl ||
        _locked == CoachExercise.shoulderPress ||
        _locked == CoachExercise.dumbbellRow ||
        _locked == CoachExercise.wallPushUp;
    final upperBodySeen = f != null &&
        (_visible(pose, [PoseIdx.lShoulder, PoseIdx.lElbow, PoseIdx.lWrist], minVis: 0.45) ||
            _visible(pose, [PoseIdx.rShoulder, PoseIdx.rElbow, PoseIdx.rWrist], minVis: 0.45));

    final seen = fullBodySeen || (upperBodyExercise && upperBodySeen);

    if (f == null || !seen) {
      _wasVisible = false;
      if (pose.isEmpty) {
        _say(CueKind.position, 'No person detected. Step back 1.5 to 2.5 meters in front of the camera.');
      } else if (upperBodySeen && !fullBodySeen) {
        _say(CueKind.position, 'Upper body detected. Step back or tilt camera down so your hips and knees are in view.');
      } else {
        _say(CueKind.position, 'Step back so your body is in clear view of the camera.');
      }
      return _buildResult(false, f ?? const {}, peopleCount: pose.isEmpty ? 0 : peopleCount);
    }

    // 3. Emit confirmation as soon as the person is accurately locked in.
    if (!_wasVisible) {
      _wasVisible = true;
      _say(CueKind.detected, 'Person detected accurately! Ready to count reps.');
    }

    _window.add(_Sample(t, f));
    _window.removeWhere((s) => t - s.t > 3.0);

    // Motion detection for active time / calories
    if (_prev != null) {
      final motion = f.keys.where((k) => k != 'wristRel').map((k) => (f[k]! - _prev![k]!).abs()).reduce(max);
      if (motion > 2.0) _lastMotionT = t;
    }
    _prev = f;
    final active = t - _lastMotionT < 4.0;
    if (active) {
      _activeSeconds += dt;
      final met = _current == CoachExercise.auto ? 3.0 : _current.met;
      // kcal/min = MET × 3.5 × kg / 200 (ACSM)
      _kcal += met * 3.5 * profile.weightKg / 200.0 * dt / 60.0;
    }

    // Recognition (auto mode only), with 1 s of agreement before switching
    if (_locked == CoachExercise.auto) {
      final c = _classify();
      if (c != null && c != _current) {
        if (_candidate != c) {
          _candidate = c;
          _candidateSince = t;
        } else if (t - _candidateSince >= 1.0) {
          _current = c;
          _down = false;
          _say(CueKind.detected, 'Detected: ${c.label}! Rep counting active.');
        }
      } else {
        _candidate = null;
      }
    }

    _countAndCheck(f, pose);
    return _buildResult(true, f, peopleCount: 1);
  }

  void _countAndCheck(Map<String, double> f, List<PoseLandmark> pose) {
    final knee = min(f['kneeL']!, f['kneeR']!);
    final elbow = (f['elbowL']! + f['elbowR']!) / 2;
    final shoulder = max(f['shoulderL']!, f['shoulderR']!);
    final hip = min(f['hipL']!, f['hipR']!);
    final wristRel = f['wristRel'] ?? 0.0;

    switch (_current) {
      case CoachExercise.auto:
        if (_window.length >= 8 && _cueKind == CueKind.position) {
          _say(CueKind.info, 'Start moving — identifying exercise…');
        }
        break;

      case CoachExercise.squat:
        // Knee valgus warning
        if (pose.length > PoseIdx.rKnee) {
          final kneeDistance = (pose[PoseIdx.lKnee].x - pose[PoseIdx.rKnee].x).abs();
          final hipDistance = (pose[PoseIdx.lHip].x - pose[PoseIdx.rHip].x).abs();
          if (kneeDistance < hipDistance * 0.65 && knee < 125.0) {
            _warn = true;
            _say(CueKind.warning, '⚠️ Knees caving inward! Push knees gently outward.');
          }
        }
        if (knee < minKneeAngle) {
          _warn = true;
          _say(CueKind.warning, 'Safe depth reached (${knee.toInt()}°)! Stand back up.');
        }
        if (!_down && knee < 120) _down = true;
        if (_down && knee > 145) {
          _down = false;
          _addRep(CoachExercise.squat);
        }
        break;

      case CoachExercise.dumbbellSquat:
        if (knee < minKneeAngle) {
          _warn = true;
          _say(CueKind.warning, 'Stop at chair height (~${minKneeAngle.round()}°) with dumbbells.');
        } else if (hip < 70) {
          _warn = true;
          _say(CueKind.warning, 'Keep your chest proud — do not lean too far forward.');
        }
        if (!_down && knee < 122) _down = true;
        if (_down && knee > 145) {
          _down = false;
          _addRep(CoachExercise.dumbbellSquat);
        }
        break;

      case CoachExercise.armRaise:
      case CoachExercise.frontRaise:
        if (shoulder > 120 && profile.age >= 60) {
          _warn = true;
          _say(CueKind.warning, 'Shoulder height is enough — no need to go higher.');
        }
        if (!_down && shoulder > 72) _down = true;
        if (_down && shoulder < 35) {
          _down = false;
          _addRep(_current);
        }
        break;

      case CoachExercise.bicepCurl:
        if (max(f['shoulderL']!, f['shoulderR']!) > 55) {
          _warn = true;
          _say(CueKind.warning, 'Keep your elbows at your sides.');
        }
        if (!_down && elbow < 100) _down = true;
        if (_down && elbow > 135) {
          _down = false;
          _addRep(CoachExercise.bicepCurl);
        }
        break;

      case CoachExercise.shoulderPress:
        if ((f['shoulderL']! - f['shoulderR']!).abs() > 35) {
          _warn = true;
          _say(CueKind.warning, 'Push both dumbbells evenly at the same height.');
        }
        final pressedUp = (shoulder > 105 && elbow > 125) || wristRel > 0.18;
        final loweredDown = shoulder < 75 || (elbow < 105 && wristRel < 0.08);
        if (!_down && pressedUp) _down = true;
        if (_down && loweredDown) {
          _down = false;
          _addRep(CoachExercise.shoulderPress);
        }
        break;

      case CoachExercise.dumbbellRow:
        if (hip > 170) {
          _warn = true;
          _say(CueKind.warning, 'Hinge slightly forward from your hips so your back muscles work.');
        }
        if (!_down && elbow < 112) _down = true;
        if (_down && elbow > 138) {
          _down = false;
          _addRep(CoachExercise.dumbbellRow);
        }
        break;

      case CoachExercise.dumbbellLunge:
        if (knee < minKneeAngle) {
          _warn = true;
          _say(CueKind.warning, 'Keep your lunge shallow (~${minKneeAngle.round()}°) to protect your knee.');
        }
        if (!_down && knee < 125) _down = true;
        if (_down && knee > 148) {
          _down = false;
          _addRep(CoachExercise.dumbbellLunge);
        }
        break;

      case CoachExercise.wallPushUp:
        if (hip < 150) {
          _warn = true;
          _say(CueKind.warning, 'Keep your body straight from shoulders to knees.');
        }
        if (!_down && elbow < 110) _down = true;
        if (_down && elbow > 140) {
          _down = false;
          _addRep(CoachExercise.wallPushUp);
        }
        break;

      case CoachExercise.marching:
      case CoachExercise.legRaise:
        bool up(double h, double lift) => h < 138 || lift < 0.62;
        bool down(double h, double lift) => h > 150 && lift > 0.68;
        final hl = f['hipL']!, hr = f['hipR']!, ll = f['liftL']!, lr = f['liftR']!;
        if (!_leftUp && up(hl, ll)) _leftUp = true;
        if (_leftUp && down(hl, ll)) {
          _leftUp = false;
          _addRep(_current);
        }
        if (!_rightUp && up(hr, lr)) _rightUp = true;
        if (_rightUp && down(hr, lr)) {
          _rightUp = false;
          _addRep(_current);
        }
        break;

      case CoachExercise.gluteBridge:
        if (!_down && hip > 152) _down = true;
        if (_down && hip < 130) {
          _down = false;
          _addRep(CoachExercise.gluteBridge);
        }
        break;
    }
  }

  CoachFrameResult _buildResult(
    bool visible,
    Map<String, double> f, {
    int peopleCount = 1,
    bool multipleDetected = false,
  }) {
    return CoachFrameResult(
      exercise: _current,
      exerciseLocked: isUserLocked,
      reps: reps,
      cue: _cue,
      cueKind: _cueKind,
      safetyWarning: _warn,
      bodyVisible: visible,
      peopleCount: peopleCount,
      multiplePeopleDetected: multipleDetected,
      activeSeconds: _activeSeconds,
      kcal: double.parse(_kcal.toStringAsFixed(1)),
      angles: Map.unmodifiable(f),
    );
  }
}
