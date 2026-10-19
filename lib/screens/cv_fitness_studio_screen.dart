import 'dart:async';
import 'package:flutter/material.dart';
import '../models/coach_exercise.dart';
import '../models/pose_landmark.dart';
import '../models/user_fitness_profile.dart';
import '../services/exercise_tracker.dart';
import '../services/pose_camera/pose_camera.dart';
import '../services/synthetic_pose_generator.dart';
import '../services/voice_coach_service.dart';
import '../theme/studio_colors.dart';
import '../widgets/form_feedback_banner.dart';
import '../widgets/joint_angle_gauge.dart';
import '../widgets/rep_counter_card.dart';
import '../widgets/skeleton_canvas_overlay.dart';
import 'algorithm_sandbox_screen.dart';
import 'exercise_guide_screen.dart';

enum StudioInputMode { liveCamera, simulator }

/// Main Computer Vision Fitness Studio Screen.
/// Supports both live camera MediaPipe pose tracking and deterministic synthetic simulation.
class CvFitnessStudioScreen extends StatefulWidget {
  final PoseCamera? camera;
  const CvFitnessStudioScreen({super.key, this.camera});

  @override
  State<CvFitnessStudioScreen> createState() => _CvFitnessStudioScreenState();
}

class _CvFitnessStudioScreenState extends State<CvFitnessStudioScreen> {
  late final PoseCamera _camera = widget.camera ?? PoseCamera();
  UserFitnessProfile _profile = const UserFitnessProfile();
  late ExerciseTracker _tracker = ExerciseTracker(_profile, exercise: CoachExercise.squat);

  CoachExercise _selectedExercise = CoachExercise.squat;
  StudioInputMode _mode = StudioInputMode.liveCamera;
  bool _isRunning = false;
  bool _voiceEnabled = true;
  String _cameraStatus = 'idle';

  CoachFrameResult? _lastResult;
  List<PoseLandmark> _currentLandmarks = [];
  double _elapsedTime = 0.0;
  double? _sessionStartTime;

  StreamSubscription? _frameSub;
  StreamSubscription? _statusSub;
  Timer? _simTimer;

  @override
  void initState() {
    super.initState();
    _statusSub = _camera.status.listen((s) => setState(() => _cameraStatus = s));
    _frameSub = _camera.frames.listen(_onLiveFrame);

    // If live camera is not supported on this platform, automatically fallback to simulator
    if (!_camera.isSupported) {
      _mode = StudioInputMode.simulator;
    }
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _frameSub?.cancel();
    _statusSub?.cancel();
    _camera.dispose();
    super.dispose();
  }

  void _onLiveFrame((List<PoseLandmark>, double) frame) {
    if (!_isRunning || _mode != StudioInputMode.liveCamera) return;
    _sessionStartTime ??= frame.$2;
    final elapsed = frame.$2 - _sessionStartTime!;
    _currentLandmarks = frame.$1;
    _elapsedTime = elapsed;

    final result = _tracker.update(
      frame.$1,
      elapsed,
      peopleCount: _camera.peopleCount,
    );

    if (_voiceEnabled && result.cue.isNotEmpty) {
      VoiceCoachService.instance.speak(
        result.cue,
        camera: _camera,
        currentT: elapsed,
        force: result.cueKind == CueKind.rep || result.safetyWarning,
      );
    }

    setState(() => _lastResult = result);
  }

  Future<void> _startSession() async {
    _elapsedTime = 0.0;
    _sessionStartTime = null;
    _tracker = ExerciseTracker(_profile, exercise: _selectedExercise);
    VoiceCoachService.instance.reset();

    setState(() => _isRunning = true);

    if (_mode == StudioInputMode.liveCamera) {
      await _camera.start();
    } else {
      // Start 20 FPS synthetic simulator timer
      _simTimer?.cancel();
      _simTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!_isRunning) return;
        _elapsedTime += 0.05;

        final simPts = SyntheticPoseGenerator.generateFrame(
          exercise: _selectedExercise,
          t: _elapsedTime,
          simulateValgus: _selectedExercise == CoachExercise.squat && (_elapsedTime.toInt() % 8 == 4),
        );
        _currentLandmarks = simPts;

        final result = _tracker.update(simPts, _elapsedTime, peopleCount: 1);

        if (_voiceEnabled && result.cue.isNotEmpty) {
          VoiceCoachService.instance.speak(
            result.cue,
            camera: _camera,
            currentT: _elapsedTime,
            force: result.cueKind == CueKind.rep || result.safetyWarning,
          );
        }

        setState(() => _lastResult = result);
      });
    }
  }

  void _stopSession() {
    _simTimer?.cancel();
    if (_mode == StudioInputMode.liveCamera) {
      _camera.stop();
    }
    _sessionStartTime = null;
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final angles = _lastResult?.angles ?? {};
    final double activeAngle = angles['activeKnee'] ??
        (angles['activeElbow'] ??
            (angles['shoulderElev'] ?? (angles['lKnee'] ?? 160.0)));

    final targetRange = _selectedExercise.targetAngleRange;

    return Scaffold(
      backgroundColor: StudioColors.background,
      appBar: AppBar(
        backgroundColor: StudioColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: StudioColors.sunsetGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FITNESS CV STUDIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'MediaPipe On-Device Kinematics',
                  style: TextStyle(
                    color: StudioColors.cyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exercise Guide',
            icon: const Icon(Icons.menu_book_rounded, color: StudioColors.textSecondary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseGuideScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Algorithm Sandbox / Calibration',
            icon: const Icon(Icons.tune_rounded, color: StudioColors.coral),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlgorithmSandboxScreen(
                  initialExercise: _selectedExercise,
                  profile: _profile,
                  onProfileChanged: (p) => setState(() => _profile = p),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _voiceEnabled ? 'Mute Voice Coach' : 'Enable Voice Coach',
            icon: Icon(
              _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceEnabled ? StudioColors.cyan : StudioColors.textMuted,
            ),
            onPressed: () => setState(() => _voiceEnabled = !_voiceEnabled),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Mode Switcher Bar
            _buildModeSwitcher(),

            // Exercise Selection Carousel
            _buildExerciseSelector(),

            // Main Video / Skeleton Stage
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _lastResult?.safetyWarning == true
                        ? StudioColors.crimson
                        : StudioColors.border,
                    width: _lastResult?.safetyWarning == true ? 2.5 : 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base Video or Simulated Mat Backdrop
                    if (_mode == StudioInputMode.liveCamera)
                      _camera.view()
                    else
                      _buildSimulatorBackdrop(),

                    // Camera Setup Guidance Overlay when idle
                    if (_mode == StudioInputMode.liveCamera && !_isRunning)
                      Container(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: StudioColors.coral.withValues(alpha: 0.15),
                                border: Border.all(color: StudioColors.coral.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Icons.videocam_rounded, color: StudioColors.coral, size: 30),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_selectedExercise.emoji}  ${_selectedExercise.label}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'AI Target: ${_selectedExercise.targetMetricName}',
                              style: const TextStyle(
                                color: StudioColors.cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '1. Position your device 1.5–2.5m away.\n2. Ensure single-person view with key joints visible.\n3. Tap START CV REP TRACKING below to begin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: StudioColors.textSecondary,
                                fontSize: 11.5,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Skeleton Overlay with Joint Angle Badges (in simulator mode)
                    if (_mode == StudioInputMode.simulator)
                      SkeletonCanvasOverlay(
                        landmarks: _currentLandmarks,
                        angles: angles,
                        hasSafetyWarning: _lastResult?.safetyWarning ?? false,
                        isMultiplePeople: _lastResult?.multiplePeopleDetected ?? false,
                      ),

                    // Top Left Status Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildStatusPill(),
                    ),

                    // Top Right Camera Flip Button (Live Mode only)
                    if (_mode == StudioInputMode.liveCamera && _isRunning)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.flip_camera_ios_rounded, size: 18),
                          onPressed: () => _camera.flipCamera(),
                        ),
                      ),

                    // Bottom Floating Coaching Banner
                    if (_lastResult != null && _lastResult!.cue.isNotEmpty)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
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

            // Metrics & Rep Counter HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: RepCounterCard(
                reps: _lastResult?.reps ?? 0,
                activeSeconds: _lastResult?.activeSeconds ?? 0,
                kcal: _lastResult?.kcal ?? 0,
                exercise: _selectedExercise,
                isLocked: _selectedExercise != CoachExercise.auto,
              ),
            ),

            const SizedBox(height: 8),

            // Live Joint Angle Gauge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: JointAngleGauge(
                label: _selectedExercise.targetMetricName,
                currentAngle: activeAngle,
                minTargetAngle: targetRange.$1,
                maxTargetAngle: targetRange.$2,
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Start / Stop Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _buildControlButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudioColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StudioColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'LIVE WEBCAM (MediaPipe)',
              icon: Icons.camera_alt_outlined,
              isSelected: _mode == StudioInputMode.liveCamera,
              onTap: () {
                if (_isRunning) _stopSession();
                setState(() => _mode = StudioInputMode.liveCamera);
              },
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'POSE SIMULATOR (No Camera)',
              icon: Icons.science_outlined,
              isSelected: _mode == StudioInputMode.simulator,
              onTap: () {
                if (_isRunning) _stopSession();
                setState(() => _mode = StudioInputMode.simulator);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: CoachExercise.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final ex = CoachExercise.values[i];
          final bool isSelected = _selectedExercise == ex;
          return ChoiceChip(
            label: Text('${ex.emoji}  ${ex.label}'),
            selected: isSelected,
            selectedColor: StudioColors.coral,
            backgroundColor: StudioColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : StudioColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: isSelected ? StudioColors.coral : StudioColors.border,
            ),
            onSelected: (_) {
              setState(() {
                _selectedExercise = ex;
                if (_isRunning) {
                  _tracker = ExerciseTracker(_profile, exercise: ex);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSimulatorBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1117), Color(0xFF161B22)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StudioColors.cyan.withValues(alpha: 0.12),
                border: Border.all(color: StudioColors.cyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.motion_photos_on_rounded, color: StudioColors.cyan, size: 36),
            ),
            const SizedBox(height: 10),
            const Text(
              'Synthetic Kinematics Stream Running',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Simulating 33-point BlazePose world coordinates for ${_selectedExercise.label}',
              style: const TextStyle(color: StudioColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    final (String text, Color color) = switch (_isRunning) {
      true => (
          _mode == StudioInputMode.liveCamera
              ? (_cameraStatus.startsWith('error')
                  ? 'CAM ERROR: ${_cameraStatus.replaceFirst('error: ', '').toUpperCase()}'
                  : (_cameraStatus == 'ready' || _cameraStatus == 'ai_ready' || _cameraStatus == 'running'
                      ? 'LIVE CAMERA TRACKING'
                      : (_cameraStatus == 'loading_ai'
                          ? 'LOADING POSE ENGINE…'
                          : (_cameraStatus == 'requesting_camera'
                              ? 'REQUESTING CAMERA…'
                              : 'CAMERA: ${_cameraStatus.toUpperCase()}'))))
              : 'SIMULATION RUNNING',
          _cameraStatus.startsWith('error')
              ? StudioColors.crimson
              : (_cameraStatus == 'loading_ai' || _cameraStatus == 'requesting_camera'
                  ? StudioColors.amber
                  : StudioColors.emerald)
        ),
      false => ('READY TO START', StudioColors.cyan),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _isRunning ? StudioColors.crimson : StudioColors.coral,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(_isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
        label: Text(
          _isRunning ? 'STOP TRACKING SESSION' : 'START CV REP TRACKING',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
        ),
        onPressed: _isRunning ? _stopSession : _startSession,
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? StudioColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: StudioColors.coral.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? StudioColors.coral : StudioColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : StudioColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
