import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/person_profile.dart';
import 'option_card.dart';
import 'step_options.dart';

class DetailsStepContent extends StatefulWidget {
  const DetailsStepContent({
    super.key,
    required this.profile,
    required this.onChanged,
    this.nameLabel = 'WHAT SHOULD WE CALL YOU?',
    this.nameHint = 'e.g. Jamie Oliver',
  });

  final PersonProfile profile;
  final VoidCallback onChanged;
  final String nameLabel;
  final String nameHint;

  @override
  State<DetailsStepContent> createState() => _DetailsStepContentState();
}

class _DetailsStepContentState extends State<DetailsStepContent> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _height = TextEditingController(
    text: widget.profile.heightCm.toString(),
  );
  late final _weight = TextEditingController(
    text: widget.profile.weightKg.toString(),
  );

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.nameLabel,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.nameHint,
            filled: true,
            fillColor: AppColors.searchFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (v) {
            p.name = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 20),
        Text(
          'AGE',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.searchFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (p.age > 10) {
                    setState(() => p.age--);
                    widget.onChanged();
                  }
                },
                icon: const Icon(Icons.remove, color: AppColors.terracotta),
              ),
              Expanded(
                child: Text(
                  '${p.age}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (p.age < 100) {
                    setState(() => p.age++);
                    widget.onChanged();
                  }
                },
                icon: const Icon(Icons.add, color: AppColors.terracotta),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SEX',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SexButton(
                label: 'Male',
                selected: p.sex == 'Male',
                onTap: () {
                  setState(() => p.sex = 'Male');
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SexButton(
                label: 'Female',
                selected: p.sex == 'Female',
                onTap: () {
                  setState(() => p.sex = 'Female');
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'HEIGHT (CM)',
                controller: _height,
                onChanged: (v) {
                  p.heightCm = int.tryParse(v) ?? p.heightCm;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'WEIGHT (KG)',
                controller: _weight,
                onChanged: (v) {
                  p.weightKg = int.tryParse(v) ?? p.weightKg;
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'ACTIVITY LEVEL',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...activityOptions.map((o) {
          return OptionCard(
            icon: o.$1,
            title: o.$2,
            subtitle: o.$3,
            selected: p.activityLevel == o.$2,
            onTap: () {
              p.activityLevel = o.$2;
              widget.onChanged();
            },
          );
        }),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.searchFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SexButton extends StatelessWidget {
  const _SexButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaDark : AppColors.searchFill,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
