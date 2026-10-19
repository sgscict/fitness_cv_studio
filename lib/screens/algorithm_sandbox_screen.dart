import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/coach_exercise.dart';
import '../models/pose_landmark.dart';
import '../models/user_fitness_profile.dart';
import '../services/exercise_tracker.dart';
import '../services/synthetic_pose_generator.dart';
import '../theme/studio_colors.dart';
import '../widgets/angle_threshold_slider.dart';
import '../widgets/skeleton_canvas_overlay.dart';

/// Dedicated algorithm refinement & calibration sandbox.
/// Allows engineers and researchers to scrub landmark kinematics, adjust thresholds,
/// test edge cases (valgus collapse, elbow momentum), and export calibrated parameters.
class AlgorithmSandboxScreen extends StatefulWidget {
  final CoachExercise initialExercise;
  final UserFitnessProfile profile;
  final ValueChanged<UserFitnessProfile>? onProfileChanged;

  const AlgorithmSandboxScreen({
    super.key,
    this.initialExercise = CoachExercise.squat,
    this.profile = const UserFitnessProfile(),
    this.onProfileChanged,
  });

  @override
  State<AlgorithmSandboxScreen> createState() => _AlgorithmSandboxScreenState();
}

class _AlgorithmSandboxScreenState extends State<AlgorithmSandboxScreen> {
  late CoachExercise _exercise = widget.initialExercise;
  late UserFitnessProfile _profile = widget.profile;
  late ExerciseTracker _tracker = ExerciseTracker(_profile, exercise: _exercise);

  double _scrubPhase = 0.5; // 0.0 to 1.0 (phase through rep)
  bool _simulateValgus = false;
  bool _simulateElbowSwing = false;

  // Calibratable Thresholds
  double _squatMinDepth = 85.0;
  double _curlMinContraction = 65.0;
  final double _shoulderLockout = 145.0;

  CoachFrameResult? _result;
  List<PoseLandmark> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _squatMinDepth = _profile.targetSquatMinAngle;
    _curlMinContraction = _profile.targetCurlMinAngle;
    _recomputeFrame();
  }

  void _recomputeFrame() {
    // Generate synthetic landmark frame based on scrub phase
    // Convert 0..1 phase to synthetic time: t = phase * (3.0 / 2.0)
    final pts = SyntheticPoseGenerator.generateFrame(
      exercise: _exercise,
      t: _scrubPhase * 1.5,
      simulateValgus: _simulateValgus,
      simulateElbowSwing: _simulateElbowSwing,
    );

    _landmarks = pts;
    _result = _tracker.update(pts, _scrubPhase * 1.5, peopleCount: 1);
  }

  void _copyCalibratedCode() {
    final code = '''
// Calibrated Kinematic Thresholds for ExerciseTracker
const double kSquatMinSafeAngle = $_squatMinDepth;
const double kCurlMinContractionAngle = $_curlMinContraction;
const double kShoulderLockoutAngle = $_shoulderLockout;
// Applied for exercise: ${_exercise.label}
''';
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calibrated parameters copied to clipboard!'),
        backgroundColor: StudioColors.coral,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final angles = _result?.angles ?? {};

    return Scaffold(
      backgroundColor: StudioColors.background,
      appBar: AppBar(
        backgroundColor: StudioColors.surface,
        title: const Text(
          'Algorithm Calibration Sandbox',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: StudioColors.coral),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('EXPORT CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            onPressed: _copyCalibratedCode,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left: Visual Stage & Phase Scrubber
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 14, 7, 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: StudioColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        SkeletonCanvasOverlay(
                          landmarks: _landmarks,
                          angles: angles,
                          hasSafetyWarning: _result?.safetyWarning ?? false,
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: StudioColors.surfaceElevated.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: StudioColors.coral.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'PHASE: ${(_scrubPhase * 100).toInt()}%  •  REPS DETECTED: ${_result?.reps ?? 0}',
                              style: const TextStyle(
                                color: StudioColors.coral,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive Scrubber Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 7, 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudioColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StudioColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manual Landmark Motion Scrubber (0.0 to 1.0)',
                            style: TextStyle(
                              color: StudioColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _scrubPhase <= 0.2
                                ? 'TOP (Starting)'
                                : (_scrubPhase >= 0.8 ? 'BOTTOM / PEAK' : 'TRANSITION'),
                            style: const TextStyle(
                              color: StudioColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: StudioColors.coral,
                          inactiveTrackColor: StudioColors.surfaceElevated,
                          thumbColor: StudioColors.coral,
                          trackHeight: 5,
                        ),
                        child: Slider(
                          value: _scrubPhase,
                          onChanged: (v) {
                            setState(() {
                              _scrubPhase = v;
                              _recomputeFrame();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Kinematic Angle Inspector & Threshold Sliders
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(7, 14, 14, 14),
              children: [
                // Exercise Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudioColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StudioColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CoachExercise>(
                      value: _exercise,
                      isExpanded: true,
                      dropdownColor: StudioColors.surfaceElevated,
                      items: CoachExercise.values
                          .where((e) => e != CoachExercise.auto)
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  Text(e.emoji),
                                  const SizedBox(width: 8),
                                  Text(
                                    e.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (e) {
                        if (e != null) {
                          setState(() {
                            _exercise = e;
                            _tracker = ExerciseTracker(_profile, exercise: e);
                            _recomputeFrame();
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Kinematic Angles Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudioColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StudioColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE COMPUTED JOINT ANGLES',
                        style: TextStyle(
                          color: StudioColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final entry in angles.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(color: StudioColors.textSecondary, fontSize: 12),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Fault Injections
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudioColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StudioColors.border),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FAULT INJECTION SIMULATION',
                          style: TextStyle(
                            color: StudioColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate Knee Valgus Collapse', style: TextStyle(color: Colors.white, fontSize: 12)),
                          subtitle: const Text('Knees cave medially relative to hip anchor', style: TextStyle(color: StudioColors.textMuted, fontSize: 10)),
                          value: _simulateValgus,
                          activeTrackColor: StudioColors.amber,
                          activeThumbColor: Colors.white,
                          onChanged: (v) => setState(() {
                            _simulateValgus = v;
                            _recomputeFrame();
                          }),
                        ),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate Elbow Swing Momentum', style: TextStyle(color: Colors.white, fontSize: 12)),
                          subtitle: const Text('Elbow drifts forward during curl', style: TextStyle(color: StudioColors.textMuted, fontSize: 10)),
                          value: _simulateElbowSwing,
                          activeTrackColor: StudioColors.amber,
                          activeThumbColor: Colors.white,
                          onChanged: (v) => setState(() {
                            _simulateElbowSwing = v;
                            _recomputeFrame();
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Threshold Tuning Sliders
                AngleThresholdSlider(
                  title: 'Squat Safe Depth Limit',
                  description: 'Knee angles below this threshold trigger cartilage protection warning',
                  value: _squatMinDepth,
                  min: 70.0,
                  max: 105.0,
                  onChanged: (v) {
                    setState(() {
                      _squatMinDepth = v;
                      _profile = _profile.copyWith(targetSquatMinAngle: v);
                      _tracker = ExerciseTracker(_profile, exercise: _exercise);
                      widget.onProfileChanged?.call(_profile);
                      _recomputeFrame();
                    });
                  },
                ),

                const SizedBox(height: 10),

                AngleThresholdSlider(
                  title: 'Bicep Curl Peak Contraction',
                  description: 'Maximum elbow flexion required to register inflection',
                  value: _curlMinContraction,
                  min: 45.0,
                  max: 85.0,
                  onChanged: (v) {
                    setState(() {
                      _curlMinContraction = v;
                      _profile = _profile.copyWith(targetCurlMinAngle: v);
                      _tracker = ExerciseTracker(_profile, exercise: _exercise);
                      widget.onProfileChanged?.call(_profile);
                      _recomputeFrame();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
