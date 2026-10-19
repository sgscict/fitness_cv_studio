import 'package:flutter/material.dart';
import '../models/coach_exercise.dart';
import '../theme/studio_colors.dart';

/// Catalog of all 13 supported exercises explaining camera angles, kinematics, and safety limits.
class ExerciseGuideScreen extends StatelessWidget {
  const ExerciseGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = CoachExercise.values.where((e) => e != CoachExercise.auto).toList();

    return Scaffold(
      backgroundColor: StudioColors.background,
      appBar: AppBar(
        backgroundColor: StudioColors.surface,
        title: const Text(
          'Computer Vision Exercise Guide',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final ex = exercises[i];
          final range = ex.targetAngleRange;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StudioColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StudioColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: StudioColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: StudioColors.coral.withValues(alpha: 0.3)),
                      ),
                      child: Text(ex.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ex.isDumbbell ? "Dumbbell Resistance" : "Bodyweight Movement"}  •  ~${ex.met} MET',
                            style: const TextStyle(
                              color: StudioColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.videocam_outlined,
                  title: 'Camera Placement',
                  detail: ex.cameraSetupGuide,
                  color: StudioColors.cyan,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.track_changes_rounded,
                  title: 'Target Joint Kinematics',
                  detail: '${ex.targetMetricName} (Optimal Inflection: ${range.$1.toInt()}° – ${range.$2.toInt()}°)',
                  color: StudioColors.coral,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                detail,
                style: const TextStyle(
                  color: StudioColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
