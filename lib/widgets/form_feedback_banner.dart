import 'package:flutter/material.dart';
import '../services/exercise_tracker.dart';
import '../theme/studio_colors.dart';

/// Real-time coaching cue banner with status indicators.
class FormFeedbackBanner extends StatelessWidget {
  final String cue;
  final CueKind cueKind;
  final bool isSafetyWarning;
  final bool isMultiplePeople;

  const FormFeedbackBanner({
    super.key,
    required this.cue,
    required this.cueKind,
    this.isSafetyWarning = false,
    this.isMultiplePeople = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cue.isEmpty) return const SizedBox.shrink();

    final Color badgeColor = isMultiplePeople || isSafetyWarning
        ? StudioColors.crimson
        : (cueKind == CueKind.rep
            ? StudioColors.emerald
            : (cueKind == CueKind.detected ? StudioColors.violet : StudioColors.cyan));

    final IconData icon = isMultiplePeople
        ? Icons.people_outline_rounded
        : (isSafetyWarning
            ? Icons.warning_amber_rounded
            : (cueKind == CueKind.rep
                ? Icons.check_circle_outline_rounded
                : (cueKind == CueKind.detected ? Icons.auto_awesome : Icons.record_voice_over_rounded)));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cue,
              style: TextStyle(
                color: badgeColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
