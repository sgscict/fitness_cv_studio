import 'dart:math';
import '../models/coach_exercise.dart';
import '../models/pose_landmark.dart';

/// Generates realistic synthetic 33-point MediaPipe BlazePose landmark streams.
/// Enables collaborators and researchers to test, refine, and calibrate algorithms
/// in simulators or desktops without requiring a physical camera.
class SyntheticPoseGenerator {
  /// Generates a 33-point pose landmark frame for the given exercise and time [t] (seconds).
  /// [simulateValgus] simulates knee caving inward during squats.
  /// [simulateElbowSwing] simulates momentum cheating during bicep curls.
  static List<PoseLandmark> generateFrame({
    required CoachExercise exercise,
    required double t,
    bool simulateValgus = false,
    bool simulateElbowSwing = false,
  }) {
    final pts = List<PoseLandmark>.generate(33, (_) => const PoseLandmark(0, 0, 0, 1.0));

    // Base body proportions in meters (hips at origin (0, 0, 0))
    const hipWidth = 0.32;
    const shoulderWidth = 0.44;
    const torsoHeight = 0.52;
    const thighLength = 0.44;
    const shinLength = 0.44;
    const upperArmLength = 0.32;
    const forearmLength = 0.28;

    // Standard cyclic motion phase: period = 3.0 seconds per rep
    final phase = (sin(t * (2 * pi / 3.0)) + 1.0) / 2.0; // 0.0 (top) to 1.0 (bottom/peak)

    // Nose & Head
    pts[PoseIdx.nose] = const PoseLandmark(0.0, -torsoHeight - 0.22, 0.0, 1.0);

    // Shoulders
    pts[PoseIdx.lShoulder] = const PoseLandmark(-shoulderWidth / 2, -torsoHeight, 0.0, 1.0);
    pts[PoseIdx.rShoulder] = const PoseLandmark(shoulderWidth / 2, -torsoHeight, 0.0, 1.0);

    // Hips
    pts[PoseIdx.lHip] = const PoseLandmark(-hipWidth / 2, 0.0, 0.0, 1.0);
    pts[PoseIdx.rHip] = const PoseLandmark(hipWidth / 2, 0.0, 0.0, 1.0);

    switch (exercise) {
      case CoachExercise.squat:
      case CoachExercise.dumbbellSquat:
        // Knee flexion oscillates between ~175° (standing) and ~82° (bottom squat)
        final kneeDrop = 0.22 * phase;
        final kneeInward = simulateValgus ? (0.09 * phase) : 0.0;
        final kneeForward = -0.36 * phase;

        pts[PoseIdx.lKnee] = PoseLandmark(
          -hipWidth / 2 + kneeInward,
          thighLength - kneeDrop,
          kneeForward,
          1.0,
        );
        pts[PoseIdx.rKnee] = PoseLandmark(
          hipWidth / 2 - kneeInward,
          thighLength - kneeDrop,
          kneeForward,
          1.0,
        );

        pts[PoseIdx.lAnkle] = PoseLandmark(-hipWidth / 2, thighLength + shinLength - kneeDrop, 0.0, 1.0);
        pts[PoseIdx.rAnkle] = PoseLandmark(hipWidth / 2, thighLength + shinLength - kneeDrop, 0.0, 1.0);

        // Arms at side or chest
        pts[PoseIdx.lElbow] = const PoseLandmark(-shoulderWidth / 2 - 0.05, -torsoHeight + upperArmLength, 0.0, 1.0);
        pts[PoseIdx.rElbow] = const PoseLandmark(shoulderWidth / 2 + 0.05, -torsoHeight + upperArmLength, 0.0, 1.0);
        pts[PoseIdx.lWrist] = const PoseLandmark(-shoulderWidth / 2 - 0.05, -torsoHeight + upperArmLength + forearmLength, 0.0, 1.0);
        pts[PoseIdx.rWrist] = const PoseLandmark(shoulderWidth / 2 + 0.05, -torsoHeight + upperArmLength + forearmLength, 0.0, 1.0);
        break;

      case CoachExercise.bicepCurl:
        // Stand straight
        pts[PoseIdx.lKnee] = const PoseLandmark(-hipWidth / 2, thighLength, 0.0, 1.0);
        pts[PoseIdx.rKnee] = const PoseLandmark(hipWidth / 2, thighLength, 0.0, 1.0);
        pts[PoseIdx.lAnkle] = const PoseLandmark(-hipWidth / 2, thighLength + shinLength, 0.0, 1.0);
        pts[PoseIdx.rAnkle] = const PoseLandmark(hipWidth / 2, thighLength + shinLength, 0.0, 1.0);

        // Elbows pinned (or swinging if cheat simulated)
        final swing = simulateElbowSwing ? (0.28 * phase) : 0.0;
        pts[PoseIdx.lElbow] = PoseLandmark(-shoulderWidth / 2 - 0.04 + swing, -torsoHeight + upperArmLength, 0.0, 1.0);
        pts[PoseIdx.rElbow] = PoseLandmark(shoulderWidth / 2 + 0.04 + swing, -torsoHeight + upperArmLength, 0.0, 1.0);

        // Curl angle: phase 0 (down: 155°) to phase 1 (up: 55°)
        final curlAngleRad = (155.0 - (100.0 * phase)) * pi / 180.0;
        final wristDY = -cos(curlAngleRad) * forearmLength;
        final wristDX = sin(curlAngleRad) * forearmLength;

        pts[PoseIdx.lWrist] = PoseLandmark(
          pts[PoseIdx.lElbow].x - 0.04,
          pts[PoseIdx.lElbow].y + wristDY,
          wristDX,
          1.0,
        );
        pts[PoseIdx.rWrist] = PoseLandmark(
          pts[PoseIdx.rElbow].x + 0.04,
          pts[PoseIdx.rElbow].y + wristDY,
          wristDX,
          1.0,
        );
        break;

      case CoachExercise.shoulderPress:
        // Standing legs
        pts[PoseIdx.lKnee] = const PoseLandmark(-hipWidth / 2, thighLength, 0.0, 1.0);
        pts[PoseIdx.rKnee] = const PoseLandmark(hipWidth / 2, thighLength, 0.0, 1.0);
        pts[PoseIdx.lAnkle] = const PoseLandmark(-hipWidth / 2, thighLength + shinLength, 0.0, 1.0);
        pts[PoseIdx.rAnkle] = const PoseLandmark(hipWidth / 2, thighLength + shinLength, 0.0, 1.0);

        // Overhead press motion
        final pressElevation = phase * 0.45; // meters upwards
        pts[PoseIdx.lElbow] = PoseLandmark(-shoulderWidth / 2 - 0.12, -torsoHeight + 0.05 - (pressElevation * 0.7), 0.0, 1.0);
        pts[PoseIdx.rElbow] = PoseLandmark(shoulderWidth / 2 + 0.12, -torsoHeight + 0.05 - (pressElevation * 0.7), 0.0, 1.0);
        pts[PoseIdx.lWrist] = PoseLandmark(-shoulderWidth / 2 - 0.05, -torsoHeight - 0.10 - pressElevation, 0.0, 1.0);
        pts[PoseIdx.rWrist] = PoseLandmark(shoulderWidth / 2 + 0.05, -torsoHeight - 0.10 - pressElevation, 0.0, 1.0);
        break;

      default:
        // Default standing posture
        pts[PoseIdx.lKnee] = const PoseLandmark(-hipWidth / 2, thighLength, 0.0, 1.0);
        pts[PoseIdx.rKnee] = const PoseLandmark(hipWidth / 2, thighLength, 0.0, 1.0);
        pts[PoseIdx.lAnkle] = const PoseLandmark(-hipWidth / 2, thighLength + shinLength, 0.0, 1.0);
        pts[PoseIdx.rAnkle] = const PoseLandmark(hipWidth / 2, thighLength + shinLength, 0.0, 1.0);
        pts[PoseIdx.lElbow] = const PoseLandmark(-shoulderWidth / 2 - 0.08, -torsoHeight + upperArmLength, 0.0, 1.0);
        pts[PoseIdx.rElbow] = const PoseLandmark(shoulderWidth / 2 + 0.08, -torsoHeight + upperArmLength, 0.0, 1.0);
        pts[PoseIdx.lWrist] = const PoseLandmark(-shoulderWidth / 2 - 0.08, -torsoHeight + upperArmLength + forearmLength, 0.0, 1.0);
        pts[PoseIdx.rWrist] = const PoseLandmark(shoulderWidth / 2 + 0.08, -torsoHeight + upperArmLength + forearmLength, 0.0, 1.0);
        break;
    }

    return pts;
  }
}
