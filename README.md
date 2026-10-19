# 🏋️‍♂️ Fitness Computer Vision Studio

A standalone, high-performance Flutter project dedicated exclusively to **Computer Vision for Fitness**. 

Built for researchers, sports scientists, and computer vision engineers to test, calibrate, and refine real-time pose tracking, joint kinematics, rep detection, and injury-prevention guardrails.

---

## ⚡ Highlights

- **100% On-Device & Private**: Runs Google MediaPipe Pose Landmarker in WebAssembly (`@mediapipe/tasks-vision 0.10.14`). Camera frames never leave the device.
- **Zero Backend Dependencies**: Fully decoupled from any external database, authentication, or patient health records. Runs instantly with `flutter run -d chrome`.
- **Dual Tracking Modes**:
  1. **Live Camera Mode**: Real-time webcam/mobile camera pose tracking with single-person lock-in.
  2. **Pose Simulator / Sandbox Mode**: Deterministic mathematical landmark generator. Test and refine algorithms on simulators or machines without a webcam!
- **13 Exercises Supported**:
  - Chair & Wall Squat
  - Dumbbell Chair Squat
  - Dumbbell Bicep Curl
  - Dumbbell Overhead Shoulder Press
  - Dumbbell Bent-Over Row
  - Dumbbell Front Raise
  - Lateral Arm Raise
  - Dumbbell Lunge
  - Wall Push-Up
  - Marching / Knee Lifts
  - Chair Leg Raise
  - Glute Bridge
  - Auto-Detection & Motion Classifier
- **Real-Time Kinematic Safety**:
  - **Knee Valgus Collapse**: Detects medial knee cave relative to hip width.
  - **Patellofemoral Depth Guard**: Prevents excessive knee shear below safe thresholds.
  - **Elbow Momentum Drift**: Flags cheating swinging during bicep curls.
  - **Chair Stand Lean**: Protects lumbar spine from excessive forward trunk flexion.
  - **Fall & Floor Collapse Assessment**: Emergency collapse detection.
- **Algorithm Calibration Sandbox**: Scrub through reps frame-by-frame, test simulated faults, adjust thresholds live, and export calibrated parameters with 1 click!

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.10+ recommended)
- Google Chrome (for Web testing)

### Run in Chrome
```bash
cd fitness_cv_studio
flutter pub get
flutter run -d chrome
```

---

## 📦 How to Share with Collaborators

This folder is completely self-contained. You can package and share it directly:

### Option A: Create a Clean Zip Archive
From the project parent directory:
```bash
zip -r fitness_cv_studio.zip fitness_cv_studio -x "fitness_cv_studio/.dart_tool/*" "fitness_cv_studio/build/*"
```
Send `fitness_cv_studio.zip` to your collaborators. They can unzip and run `flutter run -d chrome` immediately!

### Option B: Push to a Dedicated Git Repository
```bash
cd fitness_cv_studio
git init
git add .
git commit -m "feat: initial commit of Fitness Computer Vision Studio"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

---

## 🏗️ Project Architecture

```
fitness_cv_studio/
├── web/
│   ├── index.html               # WebAssembly loader & canvas setup
│   ├── pose_bridge.js           # MediaPipe Tasks-Vision 0.10.14 JS bridge
│   └── manifest.json
├── lib/
│   ├── main.dart                # Studio entry point & dark theme setup
│   ├── theme/
│   │   └── studio_colors.dart   # Sunset Coral, Electric Cyan, and Obsidian palette
│   ├── models/
│   │   ├── body_joint_point.dart    # Normalized 2D joint coordinates
│   │   ├── pose_landmark.dart       # 33 MediaPipe BlazePose 3D coordinates & connections
│   │   ├── coach_exercise.dart      # 13 exercises, angle ranges, camera guides, MET values
│   │   ├── safety_assessment.dart   # Form check results & warnings
│   │   └── user_fitness_profile.dart# Configurable weight, age, and joint limits
│   ├── services/
│   │   ├── pose_computer_vision_service.dart # Joint trigonometry, angles, depth, valgus
│   │   ├── exercise_tracker.dart             # State machine, rep counter, classifier
│   │   ├── synthetic_pose_generator.dart     # Deterministic landmark generator for tests
│   │   ├── voice_coach_service.dart          # Audio cue speech synthesis
│   │   └── pose_camera/                      # Unified camera abstraction
│   │       ├── pose_camera.dart              # Abstract camera interface
│   │       ├── pose_camera_web.dart          # Web platform view & JS interop
│   │       ├── pose_camera_native.dart       # Mobile native stub
│   │       └── pose_camera_stub.dart
│   ├── widgets/
│   │   ├── skeleton_canvas_overlay.dart      # CustomPainter rendering 33 joints & angle tags
│   │   ├── joint_angle_gauge.dart            # Live angle speedometer vs safe target zone
│   │   ├── rep_counter_card.dart             # Athletic HUD (reps, active timer, kcal)
│   │   ├── form_feedback_banner.dart         # Status cue banner (warnings, rep alerts)
│   │   └── angle_threshold_slider.dart       # Live calibration slider widget
│   └── screens/
│       ├── cv_fitness_studio_screen.dart     # Main live camera & tracking studio
│       ├── algorithm_sandbox_screen.dart     # Frame scrubber & parameter calibration
│       └── exercise_guide_screen.dart        # 13-exercise kinematics reference
└── pubspec.yaml
```

---

## 🔧 How Collaborators Can Refine the Algorithms

### 1. Adjusting Joint Angle Calculations
All angle mathematics are located in `lib/services/pose_computer_vision_service.dart`.
Angle between 3 joints (vertex is the pivot) is calculated using 2D vector trigonometry:
```dart
double angle = calculateAngleDegrees(first, vertex, second);
```

### 2. Tuning Rep State Machine & Hysteresis
Rep detection logic is located in `lib/services/exercise_tracker.dart`.
Each exercise uses a dual-state hysteresis state machine:
- `_state == 0`: Resting / Starting position.
- `_state == 1`: Active inflection point (e.g. Squat depth below 115°, Curl flexion below 65°).
- When the user returns to the starting extension and the time elapsed since the last rep exceeds minimum rep cadence (`(t - _lastRepT) > 1.0s`), a rep is officially counted!

### 3. Using the Built-In Algorithm Calibration Sandbox
1. Launch the app and tap the **Tune / Sliders Icon** in the top right.
2. Scrub the **Manual Landmark Motion Scrubber** to observe how angles update in real time.
3. Toggle fault simulations:
   - **Simulate Knee Valgus Collapse**: Verifies that the inward displacement detector triggers a warning.
   - **Simulate Elbow Swing Momentum**: Verifies that the horizontal drift cheat detector triggers an audio cue.
4. Adjust the threshold sliders and tap **EXPORT CODE** to copy the calibrated parameters to the clipboard.

---

## ➕ Adding a New Exercise in 3 Steps

1. **Add enum value** in `lib/models/coach_exercise.dart`:
   ```dart
   enum CoachExercise { ..., overheadTricepExtension }
   ```
2. **Define target angle range & camera placement** in `lib/models/coach_exercise.dart`:
   ```dart
   case CoachExercise.overheadTricepExtension:
     return (60.0, 90.0); // Elbow flexion
   ```
3. **Add tracking method** in `lib/services/exercise_tracker.dart`:
   ```dart
   void _trackTricepExtension(...) { ... }
   ```

---

## 📄 License
Apache-2.0. Built with Google MediaPipe Tasks-Vision and Flutter.
