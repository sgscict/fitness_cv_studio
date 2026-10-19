import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_cv_studio/models/coach_exercise.dart';
import 'package:fitness_cv_studio/models/pose_landmark.dart';
import 'package:fitness_cv_studio/models/user_fitness_profile.dart';
import 'package:fitness_cv_studio/services/exercise_tracker.dart';

/// Replays MediaPipe readings of real people (free-exercise-db photos) by
/// blending each exercise's start and end pose into a 6-rep set.
void main() {
  final poses = (jsonDecode(File('test/fixtures/real_poses.json').readAsStringSync())['poses'] as Map)
      .map((k, v) => MapEntry(k as String, (v as List).map((p) => (p as List).cast<num>()).toList()));

  List<PoseLandmark> blend(String a, String b, double t) => List.generate(33, (i) {
        final p = poses[a]![i], q = poses[b]![i];
        double mix(int j) => p[j] + (q[j] - p[j]) * t;
        return PoseLandmark(mix(0), mix(1), mix(2), min(p[3], q[3]).toDouble());
      });

  const profile = UserFitnessProfile(
    weightKg: 75,
    age: 40,
  );

  CoachFrameResult replay(ExerciseTracker t, String base, {bool startIsBent = false, int reps = 6}) {
    late CoachFrameResult r;
    for (var i = 0; i < reps * 30; i++) {
      var phase = (1 - cos(2 * pi * i / 30)) / 2; // 0 → 1 → 0
      if (startIsBent) phase = 1 - phase; // begin from the straight position
      r = t.update(blend('${base}_0', '${base}_1', phase), i / 15);
    }
    return r;
  }

  final cases = {
    'Bodyweight_Squat': (CoachExercise.squat, false),
    'Dumbbell_Bicep_Curl': (CoachExercise.bicepCurl, false),
    'Side_Lateral_Raise': (CoachExercise.armRaise, false),
    'Incline_Push-Up': (CoachExercise.wallPushUp, true),
  };

  cases.forEach((photo, c) {
    test('counts real-pose ${c.$1.label}', () {
      final r = replay(ExerciseTracker(profile, exercise: c.$1), photo, startIsBent: c.$2);
      expect(r.reps, inInclusiveRange(5, 6));
    });

    test('auto-detects real-pose ${c.$1.label}', () {
      final r = replay(ExerciseTracker(profile), photo, startIsBent: c.$2);
      expect(r.exercise, c.$1);
    });
  });

  test('the deep squat in the photo triggers the knee-safety warning', () {
    final t = ExerciseTracker(profile, exercise: CoachExercise.squat);
    expect(t.update(blend('Bodyweight_Squat_0', 'Bodyweight_Squat_1', 1), 0).safetyWarning, isTrue);
  });
}
