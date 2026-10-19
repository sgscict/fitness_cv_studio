import 'package:flutter/material.dart';
import '../models/pose_landmark.dart';
import '../theme/studio_colors.dart';

/// Renders a real-time 33-point BlazePose skeleton overlay with joint angle labels.
class SkeletonCanvasOverlay extends StatelessWidget {
  final List<PoseLandmark> landmarks;
  final Map<String, double> angles;
  final bool hasSafetyWarning;
  final bool isMultiplePeople;

  const SkeletonCanvasOverlay({
    super.key,
    required this.landmarks,
    required this.angles,
    this.hasSafetyWarning = false,
    this.isMultiplePeople = false,
  });

  @override
  Widget build(BuildContext context) {
    if (landmarks.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _SkeletonPainter(
        landmarks: landmarks,
        angles: angles,
        hasSafetyWarning: hasSafetyWarning,
        isMultiplePeople: isMultiplePeople,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Map<String, double> angles;
  final bool hasSafetyWarning;
  final bool isMultiplePeople;

  _SkeletonPainter({
    required this.landmarks,
    required this.angles,
    required this.hasSafetyWarning,
    required this.isMultiplePeople,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length < 29) return;

    final linePaint = Paint()
      ..color = isMultiplePeople
          ? StudioColors.crimson
          : (hasSafetyWarning ? StudioColors.amber : StudioColors.cyan)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointFillPaint = Paint()
      ..color = isMultiplePeople ? StudioColors.crimson : StudioColors.coral
      ..style = PaintingStyle.fill;

    final jointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Convert 3D world landmark coordinates (meters around hip origin) to 2D canvas coordinates
    Offset toCanvas(PoseLandmark p) {
      // Scale and center in canvas
      final double cx = size.width / 2.0;
      final double cy = size.height * 0.48;
      const double scale = 220.0;
      return Offset(cx + (p.x * scale), cy + (p.y * scale));
    }

    // 1. Draw Skeleton Bone Connections
    for (final conn in PoseIdx.connections) {
      if (conn.$1 < landmarks.length && conn.$2 < landmarks.length) {
        final p1 = landmarks[conn.$1];
        final p2 = landmarks[conn.$2];
        if (p1.visibility > 0.4 && p2.visibility > 0.4) {
          canvas.drawLine(toCanvas(p1), toCanvas(p2), linePaint);
        }
      }
    }

    // 2. Draw Joints
    for (int i = 0; i < landmarks.length; i++) {
      final p = landmarks[i];
      if (p.visibility > 0.4) {
        final pos = toCanvas(p);
        final radius = (i == PoseIdx.lKnee || i == PoseIdx.rKnee || i == PoseIdx.lElbow || i == PoseIdx.rElbow)
            ? 7.0
            : 4.5;
        canvas.drawCircle(pos, radius, jointFillPaint);
        canvas.drawCircle(pos, radius, jointBorderPaint);
      }
    }

    // 3. Draw Floating Angle Badges on Key Joints
    void drawAngleBadge(Offset pos, double angle, {bool isKnee = false}) {
      final textSpan = TextSpan(
        text: '${angle.toInt()}°',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx + 28, pos.dy - 6),
          width: textPainter.width + 12,
          height: textPainter.height + 6,
        ),
        const Radius.circular(6),
      );

      final badgePaint = Paint()
        ..color = (isKnee && angle < 85.0)
            ? StudioColors.crimson
            : (hasSafetyWarning ? StudioColors.amber : const Color(0xFF0F172A).withValues(alpha: 0.85))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(badgeRect, badgePaint);
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      textPainter.paint(
        canvas,
        Offset(pos.dx + 28 - (textPainter.width / 2), pos.dy - 6 - (textPainter.height / 2)),
      );
    }

    if (angles.containsKey('lKnee') && landmarks[PoseIdx.lKnee].visibility > 0.4) {
      drawAngleBadge(toCanvas(landmarks[PoseIdx.lKnee]), angles['lKnee']!, isKnee: true);
    }
    if (angles.containsKey('rKnee') && landmarks[PoseIdx.rKnee].visibility > 0.4) {
      drawAngleBadge(toCanvas(landmarks[PoseIdx.rKnee]), angles['rKnee']!, isKnee: true);
    }
    if (angles.containsKey('lElbow') && landmarks[PoseIdx.lElbow].visibility > 0.4) {
      drawAngleBadge(toCanvas(landmarks[PoseIdx.lElbow]), angles['lElbow']!);
    }
    if (angles.containsKey('rElbow') && landmarks[PoseIdx.rElbow].visibility > 0.4) {
      drawAngleBadge(toCanvas(landmarks[PoseIdx.rElbow]), angles['rElbow']!);
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) {
    return true; // Live frame update
  }
}
