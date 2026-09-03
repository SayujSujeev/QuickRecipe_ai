import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/person_profile.dart';
import 'option_card.dart';
import 'selectable_chip.dart';
import 'step_options.dart';

class TasteStepContent extends StatelessWidget {
  const TasteStepContent({
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
        Text(
          'FAVORITE CUISINES',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cuisineOptions.map((c) {
            final selected = profile.cuisines.contains(c);
            return SelectableChip(
              label: c,
              selected: selected,
              onTap: () {
                if (selected) {
                  profile.cuisines.remove(c);
                } else {
                  profile.cuisines.add(c);
                }
                onChanged();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'COOKING STYLE',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...cookingStyleOptions.map((o) {
          return OptionCard(
            icon: o.$1,
            title: o.$2,
            subtitle: o.$3,
            selected: profile.cookingStyle == o.$2,
            onTap: () {
              profile.cookingStyle = o.$2;
              onChanged();
            },
          );
        }),
      ],
    );
  }
}
