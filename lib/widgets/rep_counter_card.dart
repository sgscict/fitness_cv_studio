import 'package:flutter/material.dart';
import '../models/coach_exercise.dart';
import '../theme/studio_colors.dart';

/// Athletic HUD card displaying reps, workout duration, and calorie burn.
class RepCounterCard extends StatelessWidget {
  final int reps;
  final double activeSeconds;
  final double kcal;
  final CoachExercise exercise;
  final bool isLocked;

  const RepCounterCard({
    super.key,
    required this.reps,
    required this.activeSeconds,
    required this.kcal,
    required this.exercise,
    this.isLocked = true,
  });

  String _formatTime(double sec) {
    final int total = sec.toInt();
    final int m = total ~/ 60;
    final int s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudioColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudioColors.border),
      ),
      child: Row(
        children: [
          // Rep Counter Ring
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: StudioColors.surfaceElevated,
              border: Border.all(color: StudioColors.coral, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: StudioColors.coral.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$reps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'REPS',
                  style: TextStyle(
                    color: StudioColors.coral,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Workout Metrics Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      exercise.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exercise.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudioColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: StudioColors.violet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AUTO',
                          style: TextStyle(
                            color: StudioColors.violet,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MetricChip(
                      icon: Icons.timer_outlined,
                      label: _formatTime(activeSeconds),
                      color: StudioColors.cyan,
                    ),
                    const SizedBox(width: 10),
                    _MetricChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${kcal.toStringAsFixed(1)} kcal',
                      color: StudioColors.coral,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
