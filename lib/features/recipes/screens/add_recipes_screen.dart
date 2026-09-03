import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class _RecipeOption {
  const _RecipeOption({
    required this.title,
    required this.mins,
    required this.tag,
    required this.image,
  });

  final String title;
  final int mins;
  final String tag;
  final String image;
}

class AddRecipesScreen extends StatefulWidget {
  const AddRecipesScreen({super.key});

  @override
  State<AddRecipesScreen> createState() => _AddRecipesScreenState();
}

class _AddRecipesScreenState extends State<AddRecipesScreen> {
  final _selected = <int>{2};

  static const _recipes = [
    _RecipeOption(
      title: 'Herbed Garlic Sourdough',
      mins: 45,
      tag: 'Vegan',
      image:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&q=80',
    ),
    _RecipeOption(
      title: 'Garden Caprese Salad',
      mins: 15,
      tag: 'High Protein',
      image:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&q=80',
    ),
    _RecipeOption(
      title: 'Lemon Herb Atlantic Salmon',
      mins: 30,
      tag: 'Pescatarian',
      image:
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=300&q=80',
    ),
    _RecipeOption(
      title: 'Roasted Chickpea Bowl',
      mins: 25,
      tag: 'Vegan',
      image:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final count = _selected.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
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
                      'Add Recipes',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.terracottaDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: AppColors.terracotta),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Text(
                    'Saved for Shopping',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Select the recipes you'd like to aggregate into your master shopping list for the week.",
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(_recipes.length, (i) {
                    final r = _recipes[i];
                    final selected = _selected.contains(i);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selected.remove(i);
                            } else {
                              _selected.add(i);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.sage
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? AppColors.olive
                                  : AppColors.progressTrack,
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: selected
                                ? null
                                : const [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: selected
                                    ? AppColors.olive
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  r.image,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 56,
                                    height: 56,
                                    color: AppColors.searchFill,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${r.mins} mins',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  r.tag,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sageDark,
                                  ),
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
            Container(
              padding: EdgeInsets.fromLTRB(20, 14, 16, 14 + bottom),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count recipe${count == 1 ? '' : 's'} selected',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'Estimated '),
                              TextSpan(
                                text: '${count * 6} ingredients',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: count == 0
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.successGreen,
                                content: Text(
                                  'Added $count recipe${count == 1 ? '' : 's'} to list',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.shopping_basket_outlined, size: 18),
                    label: Text(
                      'Add to List',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.chipInactive,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
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
