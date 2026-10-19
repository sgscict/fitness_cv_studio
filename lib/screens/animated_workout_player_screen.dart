import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pose_landmark.dart';
import '../models/user_fitness_profile.dart';
import '../models/workout_plan.dart';
import '../services/exercise_tracker.dart';
import '../services/pose_camera/pose_camera.dart';
import '../services/synthetic_pose_generator.dart';
import '../services/voice_coach_service.dart';
import '../theme/studio_colors.dart';
import '../widgets/exercise_demo.dart';
import '../widgets/form_feedback_banner.dart';
import '../widgets/skeleton_canvas_overlay.dart';

/// Gen Z High-Energy Athletic Workout Player.
/// Places the Live Camera / Computer Vision Guide on TOP,
/// and the Animated Avatar Coach Guide directly BELOW,
/// with live calorie calculation, concentric rep ring counting, and voice coaching.
class AnimatedWorkoutPlayerScreen extends StatefulWidget {
  final WorkoutPlan workout;
  final UserFitnessProfile profile;
  final Function(int reps, int seconds, double kcal)? onWorkoutCompleted;

  const AnimatedWorkoutPlayerScreen({
    super.key,
    required this.workout,
    required this.profile,
    this.onWorkoutCompleted,
  });

  @override
  State<AnimatedWorkoutPlayerScreen> createState() => _AnimatedWorkoutPlayerScreenState();
}

class _AnimatedWorkoutPlayerScreenState extends State<AnimatedWorkoutPlayerScreen>
    with SingleTickerProviderStateMixin {
  late UserFitnessProfile _profile = widget.profile;

  // Session & Counting State
  bool _isPlaying = true;
  int _activeSeconds = 0;
  int _currentReps = 0;
  final int _targetRepsPerSet = 10;
  int _currentSet = 1;
  final int _totalSets = 3;
  double _burnedCalories = 0.0;
  bool _voiceEnabled = true;

  // Rest Timer State
  bool _isResting = false;
  int _restSecondsRemaining = 30;
  Timer? _sessionTimer;

  // AI Camera & CV State
  PoseCamera? _camera;
  ExerciseTracker? _tracker;
  StreamSubscription? _frameSub;
  StreamSubscription? _statusSub;
  List<PoseLandmark> _currentLandmarks = [];
  CoachFrameResult? _lastResult;
  bool _isCameraActive = false;

  // Synthetic Kinematics fallback stream
  Timer? _simTimer;
  double _simPhase = 0.0;

  // Cadence timing for auto-counting
  int _cadenceTick = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startSessionTimer();

    // Initial Gen Z voice greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speak('Let\'s crush ${widget.workout.title}! Set 1 starts now.', force: true);
    });
  }

  void _initCamera() {
    final coachEx = widget.workout.cvExercise;
    // Always start simulation fallback first so skeleton is instantly active
    _startSimulationFallback();

    if (coachEx != null) {
      _camera = PoseCamera();
      _tracker = ExerciseTracker(_profile, exercise: coachEx);
      _frameSub = _camera!.frames.listen(_onCvFrame);
      _statusSub = _camera!.status.listen((status) {
        if (!mounted) return;
        if (status == 'ready') {
          setState(() => _isCameraActive = true);
          _simTimer?.cancel();
        } else if (status.startsWith('error') || status == 'stopped') {
          if (_isCameraActive) {
            setState(() => _isCameraActive = false);
          }
          if (_simTimer == null || !_simTimer!.isActive) {
            _startSimulationFallback();
          }
          if (status.startsWith('error')) {
            final msg = status.replaceFirst('error: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: StudioColors.coral, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
                  ],
                ),
                backgroundColor: const Color(0xFF191C2B),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      });

      if (_camera!.isSupported) {
        _camera!.start().catchError((_) {
          if (mounted) {
            setState(() => _isCameraActive = false);
            _startSimulationFallback();
          }
        });
      }
    }
  }

  Future<void> _toggleCameraMode() async {
    if (_isCameraActive) {
      _camera?.stop();
      setState(() => _isCameraActive = false);
      _startSimulationFallback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to 3D BlazePose Kinematics Mode'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF131520),
          ),
        );
      }
    } else {
      if (_camera == null) {
        final coachEx = widget.workout.cvExercise;
        if (coachEx != null) {
          _camera = PoseCamera();
          _tracker = ExerciseTracker(_profile, exercise: coachEx);
          _frameSub = _camera!.frames.listen(_onCvFrame);
        }
      }
      if (_camera != null && _camera!.isSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Requesting camera... please click Allow in Chrome prompt'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF131520),
            ),
          );
        }
        try {
          await _camera!.start();
        } catch (e) {
          if (mounted) {
            setState(() => _isCameraActive = false);
            _startSimulationFallback();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not start camera: $e'),
                backgroundColor: const Color(0xFF191C2B),
              ),
            );
          }
        }
      }
    }
  }

  void _startSimulationFallback() {
    _simTimer?.cancel();
    final coachEx = widget.workout.cvExercise;
    if (coachEx == null) return;

    _simTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!_isPlaying || _isResting) return;
      _simPhase = (_simPhase + 0.016) % 1.0;
      final landmarks = SyntheticPoseGenerator.generateFrame(
        exercise: coachEx,
        t: _simPhase * 3.0,
      );
      final tracker = _tracker;
      if (tracker == null) return;

      final result = tracker.update(landmarks, _activeSeconds.toDouble());
      if (mounted) {
        setState(() {
          _currentLandmarks = landmarks;
          _lastResult = result;
        });
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;

      if (_isResting) {
        if (_restSecondsRemaining > 1) {
          setState(() => _restSecondsRemaining--);
          if (_restSecondsRemaining <= 3) {
            _speak('$_restSecondsRemaining', force: true);
          }
        } else {
          _endRest();
        }
        return;
      }

      setState(() {
        _activeSeconds++;
        _burnedCalories = _calculateCalories(_activeSeconds);
      });

      // Cadence auto-increment if in simulation/avatar mode
      _cadenceTick++;
      if (_cadenceTick % 3 == 0) {
        _registerRep();
      }
    });
  }

  void _onCvFrame((List<PoseLandmark>, double) frame) {
    if (!_isPlaying || _isResting) return;
    final tracker = _tracker;
    if (tracker == null) return;

    // Real landmarks detected from webcam!
    if (frame.$1.isNotEmpty) {
      if (!_isCameraActive && mounted) {
        setState(() => _isCameraActive = true);
      }
      _simTimer?.cancel();
    }

    final result = tracker.update(frame.$1, frame.$2);
    _currentLandmarks = frame.$1;

    // Detect rep completion from CV
    if (result.reps > _currentReps) {
      final newReps = result.reps;
      setState(() {
        _currentReps = newReps;
        _lastResult = result;
      });
      _onRepCounted(_currentReps);
    } else {
      setState(() => _lastResult = result);
    }

    if (result.cue.isNotEmpty && (result.cueKind == CueKind.rep || result.safetyWarning)) {
      _speak(result.cue, force: result.safetyWarning);
    }
  }

  double _met() {
    switch (widget.workout.category) {
      case FitnessCategory.walking:
        return 3.5;
      case FitnessCategory.chairAssisted:
        return 2.5;
      case FitnessCategory.jointFriendlyStrength:
        return widget.workout.isDumbbell ? 3.8 : 3.5;
      case FitnessCategory.balanceAndFallPrevention:
        return 2.8;
      case FitnessCategory.swimming:
        return 5.3;
      case FitnessCategory.mobility:
        return 2.5;
    }
  }

  double _calculateCalories(int seconds) {
    final minutes = seconds / 60.0;
    return _met() * 3.5 * _profile.weightKg / 200.0 * minutes;
  }

  void _registerRep() {
    if (_isResting) return;
    setState(() => _currentReps++);
    _onRepCounted(_currentReps);
  }

  void _onRepCounted(int count) {
    if (count == _targetRepsPerSet) {
      _onSetCompleted();
    } else if (count == (_targetRepsPerSet / 2).round()) {
      _speak('Halfway! Keep the energy high!');
    } else if (count == _targetRepsPerSet - 2) {
      _speak('Two more, finish strong!');
    } else {
      _speak('$count');
    }
  }

  void _onSetCompleted() {
    if (_currentSet >= _totalSets) {
      _completeWorkout();
    } else {
      _speak('Set $_currentSet crushed! Rest for 30 seconds.', force: true);
      setState(() {
        _isResting = true;
        _restSecondsRemaining = 30;
      });
    }
  }

  void _endRest() {
    setState(() {
      _isResting = false;
      _currentSet++;
      _currentReps = 0;
      _lastResult = null;
      if (widget.workout.cvExercise != null) {
        _tracker = ExerciseTracker(_profile, exercise: widget.workout.cvExercise!);
      }
    });
    _speak('Rest over. Let\'s go for Set $_currentSet!', force: true);
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _speak(String text, {bool force = false}) {
    if (!_voiceEnabled) return;
    VoiceCoachService.instance.speak(
      text,
      camera: _camera,
      currentT: _activeSeconds.toDouble(),
      force: force,
    );
  }

  void _completeWorkout() {
    _sessionTimer?.cancel();
    _simTimer?.cancel();
    _camera?.stop();

    _speak(
      'Workout complete! You crushed $_totalSets sets and burned ${_burnedCalories.toStringAsFixed(1)} calories! Pure energy.',
      force: true,
    );

    widget.onWorkoutCompleted?.call(_currentReps, _activeSeconds, _burnedCalories);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: StudioColors.volt, width: 1.5),
        ),
        title: const Row(
          children: [
            Text('⚡', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text(
              'SESSION CRUSHED!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.workout.title,
              style: const TextStyle(color: StudioColors.volt, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStatTile(
                    label: 'CALORIES',
                    value: '${_burnedCalories.toStringAsFixed(1)} kcal',
                    color: StudioColors.coral,
                  ),
                  _SummaryStatTile(
                    label: 'TIME',
                    value: '${(_activeSeconds ~/ 60)}m ${(_activeSeconds % 60)}s',
                    color: StudioColors.electricBlue,
                  ),
                  _SummaryStatTile(
                    label: 'SETS',
                    value: '$_totalSets/$_totalSets',
                    color: StudioColors.volt,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: StudioColors.volt,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('DONE & SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _simTimer?.cancel();
    _frameSub?.cancel();
    _statusSub?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _activeSeconds ~/ 60;
    final seconds = _activeSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final repProgress = (_currentReps / _targetRepsPerSet).clamp(0.0, 1.0);
    final angles = _lastResult?.angles ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF090A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10121C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.workout.title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StudioColors.volt.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SET $_currentSet OF $_totalSets',
                    style: const TextStyle(color: StudioColors.volt, fontSize: 9.5, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'MET ${_met().toStringAsFixed(1)} · Borg RPE ${widget.workout.rpeBorgScore}/10',
                  style: const TextStyle(fontSize: 10, color: StudioColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice Coach Toggle
          IconButton(
            tooltip: _voiceEnabled ? 'Mute Voice' : 'Enable Voice',
            icon: Icon(
              _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceEnabled ? StudioColors.volt : StudioColors.textMuted,
            ),
            onPressed: () => setState(() => _voiceEnabled = !_voiceEnabled),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. TOP STAGE: LIVE AI CAMERA GUIDE
            // -----------------------------------------------------------------
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _lastResult?.safetyWarning == true
                        ? StudioColors.crimson
                        : StudioColors.volt.withValues(alpha: 0.4),
                    width: _lastResult?.safetyWarning == true ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StudioColors.volt.withValues(alpha: 0.08),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base Camera View (always in DOM so stream attaches instantly)
                    if (_camera != null)
                      Opacity(
                        opacity: _isCameraActive ? 1.0 : 0.0,
                        child: _camera!.view(),
                      ),

                    // Cyber MoCap Stage Grid Backdrop (shown when in simulation kinematics mode)
                    if (!_isCameraActive)
                      _buildCameraBackdrop(),

                    // 33-point skeleton overlay with floating angle badges (shown only in simulator mode)
                    if (!_isCameraActive)
                      SkeletonCanvasOverlay(
                        landmarks: _currentLandmarks,
                        angles: angles,
                        hasSafetyWarning: _lastResult?.safetyWarning ?? false,
                        isMultiplePeople: _lastResult?.multiplePeopleDetected ?? false,
                      ),

                    // Top Left AI / Kinematics Badge (Interactive Mode Switcher)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: InkWell(
                        onTap: _toggleCameraMode,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isCameraActive ? StudioColors.volt : StudioColors.electricBlue,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _isCameraActive ? StudioColors.volt : StudioColors.electricBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isCameraActive ? 'AI CAMERA LIVE' : '3D BLAZEPOSE KINEMATICS',
                                style: TextStyle(
                                  color: _isCameraActive ? StudioColors.volt : StudioColors.electricBlue,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 12,
                                color: _isCameraActive ? StudioColors.volt : StudioColors.electricBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Right Controls (Flip Camera or Enable Webcam)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _isCameraActive && _camera != null
                          ? IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.flip_camera_ios_rounded, size: 16),
                              onPressed: () => _camera!.flipCamera(),
                            )
                          : InkWell(
                              onTap: _toggleCameraMode,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: StudioColors.volt.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: StudioColors.volt.withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam_rounded, color: StudioColors.volt, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'ENABLE WEBCAM',
                                      style: TextStyle(
                                        color: StudioColors.volt,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Rest Countdown Overlay
                    if (_isResting)
                      _buildRestOverlay(),

                    // Form coaching banner
                    if (_lastResult != null && _lastResult!.cue.isNotEmpty && !_isResting)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: FormFeedbackBanner(
                          cue: _lastResult!.cue,
                          cueKind: _lastResult!.cueKind,
                          isSafetyWarning: _lastResult!.safetyWarning,
                          isMultiplePeople: _lastResult!.multiplePeopleDetected,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 2. MIDDLE STAGE: ANIMATED AVATAR GUIDE (DIRECTLY BELOW CAMERA)
            // -----------------------------------------------------------------
            Container(
              height: 140,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131520),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF262A3D)),
              ),
              child: Row(
                children: [
                  // Animated Character Demonstrator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 120,
                      height: double.infinity,
                      color: Colors.black,
                      child: ExerciseDemo.photo(
                        photo: widget.workout.demoPhotoKey ?? 'Bodyweight_Squat',
                        sex: _profile.sex,
                        height: 120,
                        showCvOverlay: true,
                        showNoteBelow: false,
                        compact: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar Guide Details & Controls
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.accessibility_new_rounded, color: StudioColors.coral, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  'AVATAR FORM GUIDE',
                                  style: TextStyle(
                                    color: StudioColors.coral,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            // Female / Male switch pill
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _profile = _profile.copyWith(
                                    sex: _profile.sex == BiologicalSex.female
                                        ? BiologicalSex.male
                                        : BiologicalSex.female,
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  _profile.sex == BiologicalSex.female ? '👩 Female' : '👨 Male',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.workout.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.workout.jointSafetyNote,
                          style: const TextStyle(color: StudioColors.textMuted, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: StudioColors.electricBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sync_rounded, size: 11, color: StudioColors.electricBlue),
                                  SizedBox(width: 4),
                                  Text(
                                    'SYNC CADENCE IN REAL TIME',
                                    style: TextStyle(color: StudioColors.electricBlue, fontSize: 8.5, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // 3. BOTTOM HUD: CALORIES, REP RING COUNTING, AND VOICE COACH
            // -----------------------------------------------------------------
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: Column(
                  children: [
                    // Concentric Rep Ring and Stats Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131520),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF262A3D)),
                        ),
                        child: Row(
                          children: [
                            // Neon Concentric Rep Ring
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: repProgress,
                                    strokeWidth: 9,
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation(StudioColors.volt),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_currentReps',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        '/ $_targetRepsPerSet REPS',
                                        style: const TextStyle(
                                          color: StudioColors.volt,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Dynamic Live Calorie Burn & Time
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _GenZStatTile(
                                    emoji: '🔥',
                                    label: 'CALORIES BURNED',
                                    value: '${_burnedCalories.toStringAsFixed(1)} kcal',
                                    valueColor: StudioColors.coral,
                                  ),
                                  _GenZStatTile(
                                    emoji: '⏱️',
                                    label: 'ACTIVE DURATION',
                                    value: timeStr,
                                    valueColor: StudioColors.electricBlue,
                                  ),
                                  _GenZStatTile(
                                    emoji: '⚡',
                                    label: 'SET TARGET',
                                    value: 'Set $_currentSet of $_totalSets',
                                    valueColor: StudioColors.volt,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Controls Bar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF262A3D)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            label: Text(
                              _isPlaying ? 'PAUSE' : 'RESUME',
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: StudioColors.volt,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 22),
                            label: const Text('+1 REP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            onPressed: _registerRep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: StudioColors.coral.withValues(alpha: 0.15),
                            foregroundColor: StudioColors.coral,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 20),
                          tooltip: 'Finish Workout',
                          onPressed: _completeWorkout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraBackdrop() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _MoCapGridPainter(
            accentColor: _lastResult?.safetyWarning == true
                ? StudioColors.coral
                : StudioColors.volt,
          ),
        ),
        // Bottom Action to Enable Webcam if desired
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: InkWell(
              onTap: _toggleCameraMode,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: StudioColors.volt.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: StudioColors.volt.withValues(alpha: 0.22),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, color: StudioColors.volt, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'ACTIVATE WEBCAM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.86),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: StudioColors.volt, size: 48),
            const SizedBox(height: 6),
            const Text(
              'SET COMPLETE! REST & BREATHE',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            Text(
              '$_restSecondsRemaining',
              style: const TextStyle(
                color: StudioColors.volt,
                fontSize: 58,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const Text(
              'seconds remaining',
              style: TextStyle(color: StudioColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: StudioColors.volt,
                side: const BorderSide(color: StudioColors.volt),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('SKIP REST & CONTINUE', style: TextStyle(fontWeight: FontWeight.w900)),
              onPressed: _endRest,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenZStatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color valueColor;

  const _GenZStatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: StudioColors.textMuted, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 14.5, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: StudioColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MoCapGridPainter extends CustomPainter {
  final Color accentColor;
  const _MoCapGridPainter({this.accentColor = StudioColors.volt});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Deep athletic studio gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.0,
        colors: [
          Color(0xFF141724),
          Color(0xFF07080E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Floor perspective grid lines
    final horizonY = h * 0.70;
    final gridPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 6; i++) {
      final t = i / 6.0;
      final y = horizonY + (h - horizonY) * math.pow(t, 1.8);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final centerX = w / 2;
    for (int i = -6; i <= 6; i++) {
      final bottomX = centerX + (i * w * 0.15);
      canvas.drawLine(Offset(centerX, horizonY), Offset(bottomX, h), gridPaint);
    }

    // Concentric MoCap floor ring
    final ringPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, horizonY + (h - horizonY) * 0.52),
        width: w * 0.55,
        height: (h - horizonY) * 0.65,
      ),
      ringPaint,
    );

    final outerRingPaint = Paint()
      ..color = StudioColors.electricBlue.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, horizonY + (h - horizonY) * 0.52),
        width: w * 0.78,
        height: (h - horizonY) * 0.90,
      ),
      outerRingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MoCapGridPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
