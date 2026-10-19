/// Represents a normalized 2D joint point in camera frame coordinates (0.0 to 1.0).
class BodyJointPoint {
  final double x;
  final double y;
  final double confidence;

  const BodyJointPoint({
    required this.x,
    required this.y,
    this.confidence = 1.0,
  });

  @override
  String toString() => 'BodyJointPoint(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, conf: ${confidence.toStringAsFixed(2)})';
}
