/// One body point from MediaPipe Pose Landmarker world landmarks (metres,
/// origin at the hips, x right, y down, z toward the camera is negative;
/// visibility 0..1).
class PoseLandmark {
  final double x;
  final double y;
  final double z;
  final double visibility;

  const PoseLandmark(this.x, this.y, [this.z = 0, this.visibility = 1]);

  @override
  String toString() => 'PoseLandmark(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)}, vis: ${visibility.toStringAsFixed(2)})';
}

/// MediaPipe BlazePose standard 33-point indices.
class PoseIdx {
  static const nose = 0;
  static const leftEyeInner = 1;
  static const leftEye = 2;
  static const leftEyeOuter = 3;
  static const rightEyeInner = 4;
  static const rightEye = 5;
  static const rightEyeOuter = 6;
  static const leftEar = 7;
  static const rightEar = 8;
  static const mouthLeft = 9;
  static const mouthRight = 10;
  static const lShoulder = 11, rShoulder = 12;
  static const lElbow = 13, rElbow = 14;
  static const lWrist = 15, rWrist = 16;
  static const leftPinky = 17, rightPinky = 18;
  static const leftIndex = 19, rightIndex = 20;
  static const leftThumb = 21, rightThumb = 22;
  static const lHip = 23, rHip = 24;
  static const lKnee = 25, rKnee = 26;
  static const lAnkle = 27, rAnkle = 28;
  static const leftHeel = 29, rightHeel = 30;
  static const leftFootIndex = 31, rightFootIndex = 32;

  /// Returns pairs of landmark indices forming the skeleton connections.
  static const List<(int, int)> connections = [
    (nose, leftEye),
    (leftEye, leftEar),
    (nose, rightEye),
    (rightEye, rightEar),
    (mouthLeft, mouthRight),
    (lShoulder, rShoulder),
    (lShoulder, lElbow),
    (lElbow, lWrist),
    (rShoulder, rElbow),
    (rElbow, rWrist),
    (lShoulder, lHip),
    (rShoulder, rHip),
    (lHip, rHip),
    (lHip, lKnee),
    (lKnee, lAnkle),
    (rHip, rKnee),
    (rKnee, rAnkle),
    (lAnkle, leftHeel),
    (rAnkle, rightHeel),
    (leftHeel, leftFootIndex),
    (rightHeel, rightFootIndex),
  ];
}
