import 'package:flutter/material.dart';

import '../../data/models/recipe_draft.dart';
import '../theme/app_colors.dart';

/// Shared by draft review and saved recipes so estimate labels survive saving.
class RecipePlanningSummary extends StatelessWidget {
  const RecipePlanningSummary({super.key, this.servings, this.times});

  final DraftServing? servings;
  final DraftTime? times;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (times?.prepMinutes != null)
        'Prep: ${times!.prepMinutes} min${times!.estimatedFields.contains('prepMinutes') ? ' (estimated)' : ''}',
      if (times?.cookMinutes != null)
        'Cook: ${times!.cookMinutes} min${times!.estimatedFields.contains('cookMinutes') ? ' (estimated)' : ''}',
    ];
    final reasons = <String>{
      if (servings?.isEstimated == true && servings?.estimateReason != null)
        servings!.estimateReason!,
      if ((times?.estimatedFields.isNotEmpty ?? false) &&
          times?.estimateReason != null)
        times!.estimateReason!,
    }.where((reason) => reason.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PlanningChip(
              icon: Icons.people_outline,
              label: servings?.displayLabel ?? 'Servings not available',
            ),
            _PlanningChip(
              icon: Icons.timer_outlined,
              label: times?.displayLabel ?? 'Time not available',
            ),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            details.join(' · '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'AI estimate: ${reasons.join(' ')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanningChip extends StatelessWidget {
  const _PlanningChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.chipInactive,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
