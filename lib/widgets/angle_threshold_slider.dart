import 'package:flutter/material.dart';
import '../theme/studio_colors.dart';

/// Interactive slider allowing collaborators to calibrate joint angle thresholds on the fly.
class AngleThresholdSlider extends StatelessWidget {
  final String title;
  final String description;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const AngleThresholdSlider({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                title,
                style: const TextStyle(
                  color: StudioColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: StudioColors.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: StudioColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: StudioColors.coral,
              inactiveTrackColor: StudioColors.surfaceElevated,
              thumbColor: StudioColors.coral,
              overlayColor: StudioColors.coral.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
