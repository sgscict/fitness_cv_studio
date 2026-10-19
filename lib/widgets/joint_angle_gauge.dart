import 'package:flutter/material.dart';
import '../theme/studio_colors.dart';

/// Live speedometer-style bar gauge displaying the active joint angle relative to target limits.
class JointAngleGauge extends StatelessWidget {
  final String label;
  final double currentAngle;
  final double minTargetAngle;
  final double maxTargetAngle;
  final String unit;

  const JointAngleGauge({
    super.key,
    required this.label,
    required this.currentAngle,
    required this.minTargetAngle,
    required this.maxTargetAngle,
    this.unit = '°',
  });

  @override
  Widget build(BuildContext context) {
    final bool isInTargetZone = currentAngle >= minTargetAngle && currentAngle <= maxTargetAngle;
    final bool isBelowMin = currentAngle < minTargetAngle;

    final Color statusColor = isInTargetZone
        ? StudioColors.emerald
        : (isBelowMin ? StudioColors.crimson : StudioColors.cyan);

    // Normalize progress 0.0 to 1.0 (assuming 30° to 180° range)
    final double norm = ((currentAngle - 30.0) / 150.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(
                label,
                style: const TextStyle(
                  color: StudioColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${currentAngle.toStringAsFixed(1)}$unit',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: StudioColors.surfaceElevated,
                ),
                FractionallySizedBox(
                  widthFactor: norm,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [StudioColors.coral, statusColor],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${minTargetAngle.toInt()}$unit',
                style: const TextStyle(color: StudioColors.textMuted, fontSize: 10),
              ),
              Text(
                isInTargetZone ? '🎯 IN TARGET ZONE' : (isBelowMin ? '⚠️ BELOW SAFE LIMIT' : 'ASCENT / EXTENSION'),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Max: ${maxTargetAngle.toInt()}$unit',
                style: const TextStyle(color: StudioColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
