import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_cv_studio/models/coach_exercise.dart';
import 'package:fitness_cv_studio/models/user_fitness_profile.dart';
import 'package:fitness_cv_studio/services/exercise_tracker.dart';
import 'package:fitness_cv_studio/services/synthetic_pose_generator.dart';
import 'package:fitness_cv_studio/services/pose_computer_vision_service.dart';
import 'package:fitness_cv_studio/models/body_joint_point.dart';

void main() {
  group('PoseComputerVisionService Angle Calculations', () {
    test('calculateAngleDegrees calculates 90 degrees correctly', () {
      const a = BodyJointPoint(x: 0, y: 1);
      const vertex = BodyJointPoint(x: 0, y: 0);
      const b = BodyJointPoint(x: 1, y: 0);

      final angle = PoseComputerVisionService.calculateAngleDegrees(a, vertex, b);
      expect(angle, closeTo(90.0, 0.1));
    });

    test('calculateAngleDegrees calculates 180 degrees (straight line)', () {
      const a = BodyJointPoint(x: 0, y: -1);
      const vertex = BodyJointPoint(x: 0, y: 0);
      const b = BodyJointPoint(x: 0, y: 1);

      final angle = PoseComputerVisionService.calculateAngleDegrees(a, vertex, b);
      expect(angle, closeTo(180.0, 0.1));
    });

    test('evaluateSquatDepthAndKneeSafety flags knee valgus', () {
      const hip = BodyJointPoint(x: -0.16, y: 0);
      const ankle = BodyJointPoint(x: -0.16, y: 0.88);
      // Knee caves medially toward opposite knee at x=0
      const knee = BodyJointPoint(x: -0.02, y: 0.44);
      const oppKnee = BodyJointPoint(x: 0.02, y: 0.44);

      final safety = PoseComputerVisionService.evaluateSquatDepthAndKneeSafety(
        hip: hip,
        knee: knee,
        ankle: ankle,
        oppositeKnee: oppKnee,
      );

      expect(safety.hasValgusKneeCollapse, isTrue);
      expect(safety.isSafe, isFalse);
    });
  });

  group('ExerciseTracker Rep Counter with Synthetic Poses', () {
    test('Counts squat reps over multiple cycles', () {
      const profile = UserFitnessProfile();
      final tracker = ExerciseTracker(profile, exercise: CoachExercise.squat);

      // Simulate 3 full squats (each rep is 3.0 seconds period)
      // Run at 20 FPS (dt = 0.05s) for 10 seconds
      for (double t = 0.0; t <= 10.0; t += 0.05) {
        final frame = SyntheticPoseGenerator.generateFrame(
          exercise: CoachExercise.squat,
          t: t,
        );
        tracker.update(frame, t, peopleCount: 1);
      }

      // 10 seconds / 3s per rep should yield around 3 completed reps
      expect(tracker.reps, greaterThanOrEqualTo(2));
    });

    test('Counts bicep curl reps over multiple cycles', () {
      const profile = UserFitnessProfile();
      final tracker = ExerciseTracker(profile, exercise: CoachExercise.bicepCurl);

      for (double t = 0.0; t <= 10.0; t += 0.05) {
        final frame = SyntheticPoseGenerator.generateFrame(
          exercise: CoachExercise.bicepCurl,
          t: t,
        );
        tracker.update(frame, t, peopleCount: 1);
      }

      expect(tracker.reps, greaterThanOrEqualTo(2));
    });

    test('Flags multiple people when peopleCount > 1', () {
      const profile = UserFitnessProfile();
      final tracker = ExerciseTracker(profile, exercise: CoachExercise.squat);
      final frame = SyntheticPoseGenerator.generateFrame(exercise: CoachExercise.squat, t: 0.5);

      final result = tracker.update(frame, 0.5, peopleCount: 2);
      expect(result.multiplePeopleDetected, isTrue);
      expect(result.cueKind, CueKind.warning);
    });
  });
}
