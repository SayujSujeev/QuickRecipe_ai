import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  int _avatar = 1;
  bool _male = true;
  int _activity = 1;
  int _goal = 1;

  final _name = TextEditingController(text: '');
  final _age = TextEditingController(text: '28');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '70');

  static const _activities = [
    (Icons.chair_outlined, 'Sedentary', 'Minimal exercise, office job.'),
    (Icons.directions_walk, 'Lightly Active', '1-3 days of exercise/week.'),
    (Icons.fitness_center, 'Moderate', '3-5 days of hard exercise.'),
    (Icons.bolt_rounded, 'Very Active', 'Hard daily exercise/physical job.'),
  ];

  static const _goals = [
    (
      'Lose Weight',
      'Calorie deficit focused on nutritious, high-fiber meals.',
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=700&q=80',
    ),
    (
      'Maintain Health',
      'Steady energy and balanced macros for long-term vitality.',
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=700&q=80',
    ),
    (
      'Build Muscle',
      'Protein-rich meals designed for growth and recovery.',
      'https://images.unsplash.com/photo-1432139555190-58524da6b9c8?w=700&q=80',
    ),
  ];

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.terracotta,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Add Family Member',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaDark,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Step 1 of 2',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.5,
                            minHeight: 4,
                            backgroundColor: AppColors.progressTrack,
                            color: AppColors.terracottaDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Text(
                    'Family Profile',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tailor nutritional goals and meal recommendations by creating a detailed profile for your family member.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _LabeledField(
                    label: 'FULL NAME',
                    controller: _name,
                    hint: 'e.g. Leo Smith',
                  ),
                  _LabeledField(
                    label: 'AGE (YEARS)',
                    controller: _age,
                    hint: '28',
                    keyboard: TextInputType.number,
                  ),
                  Text(
                    'CHOOSE AVATAR',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final icons = [
                        Icons.face_retouching_natural,
                        Icons.sentiment_satisfied_alt,
                        Icons.directions_walk,
                        Icons.place_outlined,
                        Icons.restaurant,
                      ];
                      final selected = _avatar == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _avatar = i),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.chipInactive,
                              border: Border.all(
                                color: selected
                                    ? AppColors.terracotta
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              icons[i],
                              color: AppColors.terracottaDark,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'BIOLOGICAL SEX',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SexBtn(
                          label: 'MALE',
                          selected: _male,
                          onTap: () => setState(() => _male = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SexBtn(
                          label: 'FEMALE',
                          selected: !_male,
                          onTap: () => setState(() => _male = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'HEIGHT (CM)',
                    controller: _height,
                    hint: '175',
                    keyboard: TextInputType.number,
                  ),
                  _LabeledField(
                    label: 'WEIGHT (KG)',
                    controller: _weight,
                    hint: '70',
                    keyboard: TextInputType.number,
                  ),
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
                  ...List.generate(_activities.length, (i) {
                    final a = _activities[i];
                    final selected = _activity == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _activity = i),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.sage
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.protein
                                  : AppColors.progressTrack,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(a.$1, color: AppColors.terracottaDark),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.$2,
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      a.$3,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'PRIMARY GOAL',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_goals.length, (i) {
                    final g = _goals[i];
                    final selected = _goal == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _goal = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.terracotta
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Image.network(
                                    g.$3,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      height: 120,
                                      color: AppColors.searchFill,
                                    ),
                                  ),
                                  if (selected)
                                    const Positioned(
                                      top: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: AppColors.terracotta,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.$1,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      g.$2,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: selected
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.successGreen,
                            content: Text(
                              'Family profile saved',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Save Profile',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                        side: const BorderSide(color: AppColors.terracotta),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
            keyboardType: keyboard,
            style: GoogleFonts.dmSans(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
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
          ),
        ],
      ),
    );
  }
}

class _SexBtn extends StatelessWidget {
  const _SexBtn({
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
