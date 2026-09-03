import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../data/models/person_profile.dart';
import 'option_card.dart';
import 'step_options.dart';

class GoalStepContent extends StatelessWidget {
  const GoalStepContent({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final PersonProfile profile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...goalOptions.map((o) {
          return OptionCard(
            icon: o.$1,
            title: o.$2,
            subtitle: o.$3,
            selected: profile.goal == o.$2,
            onTap: () {
              profile.goal = o.$2;
              onChanged();
            },
          );
        }),
        if (profile.goal != null) ...[
          const SizedBox(height: 16),
          _TargetsPreview(profile: profile),
        ],
      ],
    );
  }
}

class _TargetsPreview extends StatelessWidget {
  const _TargetsPreview({required this.profile});

  final PersonProfile profile;

  @override
  Widget build(BuildContext context) {
    final targets = computeDailyTargets(profile);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bannerPeach,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR ESTIMATED DAILY TARGETS',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.terracottaDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${targets.kcal}',
                style: GoogleFonts.fraunces(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracottaDark,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kcal / day',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroChip(label: 'Protein', value: '${targets.proteinG}g'),
              const SizedBox(width: 10),
              _MacroChip(label: 'Carbs', value: '${targets.carbsG}g'),
              const SizedBox(width: 10),
              _MacroChip(label: 'Fats', value: '${targets.fatsG}g'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                size: 16,
                color: AppColors.terracottaDark,
              ),
              const SizedBox(width: 6),
              Text(
                'BMI ${targets.bmi.toStringAsFixed(1)} · ${targets.bmiCategory}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracottaDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
