/// All supported exercises recognized and tracked by the Computer Vision pipeline.
enum CoachExercise {
  auto,
  squat,
  dumbbellSquat,
  bicepCurl,
  shoulderPress,
  dumbbellRow,
  frontRaise,
  armRaise,
  dumbbellLunge,
  wallPushUp,
  marching,
  legRaise,
  gluteBridge,
}

extension CoachExerciseX on CoachExercise {
  bool get isDumbbell {
    switch (this) {
      case CoachExercise.dumbbellSquat:
      case CoachExercise.bicepCurl:
      case CoachExercise.shoulderPress:
      case CoachExercise.dumbbellRow:
      case CoachExercise.frontRaise:
      case CoachExercise.dumbbellLunge:
        return true;
      case CoachExercise.auto:
      case CoachExercise.squat:
      case CoachExercise.armRaise:
      case CoachExercise.wallPushUp:
      case CoachExercise.marching:
      case CoachExercise.legRaise:
      case CoachExercise.gluteBridge:
        return false;
    }
  }

  String get label {
    switch (this) {
      case CoachExercise.auto:
        return 'Auto-Detect (Smart Classification)';
      case CoachExercise.squat:
        return 'Chair / Wall Squat';
      case CoachExercise.dumbbellSquat:
        return 'Dumbbell Chair Squat';
      case CoachExercise.armRaise:
        return 'Lateral Arm Raise';
      case CoachExercise.bicepCurl:
        return 'Bicep Curl';
      case CoachExercise.shoulderPress:
        return 'Dumbbell Shoulder Press';
      case CoachExercise.dumbbellRow:
        return 'Dumbbell Bent-Over Row';
      case CoachExercise.frontRaise:
        return 'Dumbbell Front Raise';
      case CoachExercise.dumbbellLunge:
        return 'Dumbbell Step Lunge';
      case CoachExercise.wallPushUp:
        return 'Wall Push-Up';
      case CoachExercise.marching:
        return 'Marching / Knee Lifts';
      case CoachExercise.legRaise:
        return 'Chair-Supported Leg Raise';
      case CoachExercise.gluteBridge:
        return 'Glute Bridge';
    }
  }

  String get emoji {
    switch (this) {
      case CoachExercise.auto:
        return '⚡';
      case CoachExercise.squat:
        return '🦵';
      case CoachExercise.dumbbellSquat:
        return '🏋️';
      case CoachExercise.armRaise:
        return '💪';
      case CoachExercise.bicepCurl:
        return '🦾';
      case CoachExercise.shoulderPress:
        return '🏋️‍♂️';
      case CoachExercise.dumbbellRow:
        return '🚣';
      case CoachExercise.frontRaise:
        return '🏹';
      case CoachExercise.dumbbellLunge:
        return '🏃';
      case CoachExercise.wallPushUp:
        return '🧱';
      case CoachExercise.marching:
        return '🚶';
      case CoachExercise.legRaise:
        return '🪑';
      case CoachExercise.gluteBridge:
        return '🧘';
    }
  }

  /// Target angle name tracked by the vision algorithm (e.g. Knee Flexion, Elbow Flexion).
  String get targetMetricName {
    switch (this) {
      case CoachExercise.auto:
        return 'General Motion Angle';
      case CoachExercise.squat:
      case CoachExercise.dumbbellSquat:
      case CoachExercise.dumbbellLunge:
        return 'Knee Flexion Angle';
      case CoachExercise.bicepCurl:
        return 'Elbow Flexion Angle';
      case CoachExercise.shoulderPress:
      case CoachExercise.frontRaise:
      case CoachExercise.armRaise:
        return 'Shoulder Elevation Angle';
      case CoachExercise.dumbbellRow:
        return 'Elbow Drive & Trunk Angle';
      case CoachExercise.wallPushUp:
        return 'Elbow Push Angle';
      case CoachExercise.marching:
      case CoachExercise.legRaise:
        return 'Hip Flexion Angle';
      case CoachExercise.gluteBridge:
        return 'Hip Extension Angle';
    }
  }

  /// Optimal joint angle range in degrees for safe repetition inflection.
  (double min, double max) get targetAngleRange {
    switch (this) {
      case CoachExercise.auto:
        return (60.0, 140.0);
      case CoachExercise.squat:
      case CoachExercise.dumbbellSquat:
        return (85.0, 115.0); // Joint safe zone avoiding deep patellar compressive force
      case CoachExercise.bicepCurl:
        return (50.0, 70.0); // Full curl contraction
      case CoachExercise.shoulderPress:
        return (145.0, 175.0); // Overhead lockout
      case CoachExercise.frontRaise:
      case CoachExercise.armRaise:
        return (80.0, 100.0); // Shoulder parallel
      case CoachExercise.dumbbellRow:
        return (70.0, 95.0); // Elbow past torso
      case CoachExercise.dumbbellLunge:
        return (90.0, 110.0);
      case CoachExercise.wallPushUp:
        return (85.0, 110.0);
      case CoachExercise.marching:
      case CoachExercise.legRaise:
        return (75.0, 105.0);
      case CoachExercise.gluteBridge:
        return (160.0, 180.0);
    }
  }

  /// Camera placement recommendation for computer vision accuracy.
  String get cameraSetupGuide {
    switch (this) {
      case CoachExercise.auto:
        return 'Place camera 2–3 meters away, chest height, showing head to knees.';
      case CoachExercise.squat:
      case CoachExercise.dumbbellSquat:
        return 'Place camera 2–3 meters in front or 45° angle. Ensure knees and hips are visible.';
      case CoachExercise.bicepCurl:
        return 'Place camera 1.5–2 meters in front. Keep torso, elbows, and forearms clearly visible.';
      case CoachExercise.shoulderPress:
        return 'Place camera 2 meters in front. Ensure overhead reach is inside the camera frame.';
      case CoachExercise.dumbbellRow:
        return 'Place camera 2 meters from the side (90° profile) to monitor flat spinal posture.';
      case CoachExercise.frontRaise:
      case CoachExercise.armRaise:
        return 'Place camera 1.5–2 meters in front to capture horizontal arm height.';
      case CoachExercise.dumbbellLunge:
        return 'Place camera 2–3 meters from the side profile to assess front knee depth.';
      case CoachExercise.wallPushUp:
        return 'Place camera 2 meters from the side profile facing the wall.';
      case CoachExercise.marching:
      case CoachExercise.legRaise:
        return 'Place camera 2 meters in front showing full hip and leg path.';
      case CoachExercise.gluteBridge:
        return 'Place camera low from the side on the mat to track pelvic elevation line.';
    }
  }

  /// MET value from 2024 Adult Compendium of Physical Activities for calorie estimation.
  double get met {
    switch (this) {
      case CoachExercise.auto:
        return 2.8;
      case CoachExercise.squat:
        return 3.8;
      case CoachExercise.dumbbellSquat:
        return 4.5;
      case CoachExercise.armRaise:
        return 3.0;
      case CoachExercise.bicepCurl:
        return 3.5;
      case CoachExercise.shoulderPress:
        return 3.8;
      case CoachExercise.dumbbellRow:
        return 4.0;
      case CoachExercise.frontRaise:
        return 3.2;
      case CoachExercise.dumbbellLunge:
        return 4.5;
      case CoachExercise.wallPushUp:
        return 2.8;
      case CoachExercise.marching:
        return 3.0;
      case CoachExercise.legRaise:
        return 2.8;
      case CoachExercise.gluteBridge:
        return 3.2;
    }
  }
}
