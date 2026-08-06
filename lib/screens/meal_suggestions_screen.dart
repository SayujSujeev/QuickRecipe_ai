import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/kitchen_header.dart';
import 'log_meal_screen.dart';

class MealSuggestionsScreen extends StatelessWidget {
  const MealSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const KitchenHeader(showBack: true),
            const SizedBox(height: 12),
            Text(
              "What to cook to hit today's goals",
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalized recommendations based on your activity and morning nutrition.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.seasonalCard,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _DoubleRingPainter(),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '420',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracottaDark,
                              ),
                            ),
                            Text(
                              'kcal left',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Balance',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.dmSans(fontSize: 13),
                            children: const [
                              TextSpan(text: 'Protein  '),
                              TextSpan(
                                text: '40g',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.protein,
                                ),
                              ),
                              TextSpan(text: ' remaining'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.dmSans(fontSize: 13),
                            children: const [
                              TextSpan(text: 'Carbs  '),
                              TextSpan(
                                text: '115g',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.carbsBrown,
                                ),
                              ),
                              TextSpan(text: ' remaining'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.apple, size: 48, color: Color(0x33A85C41)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  'Top Suggestions',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'View Pantry Matches',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terracotta,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SuggestionCard(
              title: 'Lemon Herb Chicken',
              match: '92% Match',
              tag: 'High Protein - fits your remaining 40g goal',
              tagColor: AppColors.sage,
              mins: 25,
              kcal: 310,
              image:
                  'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=900&q=80',
              onSelect: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogMealScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _SuggestionCard(
              title: 'Seared Tuna Grain Bowl',
              match: '88% Match',
              tag: 'Balanced carbs for steady afternoon energy',
              tagColor: AppColors.badgePeach,
              mins: 20,
              kcal: 380,
              image:
                  'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=900&q=80',
              onSelect: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogMealScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.title,
    required this.match,
    required this.tag,
    required this.tagColor,
    required this.mins,
    required this.kcal,
    required this.image,
    required this.onSelect,
  });

  final String title;
  final String match;
  final String tag;
  final Color tagColor;
  final int mins;
  final int kcal;
  final String image;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: AppColors.searchFill),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      match,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.favorite_border,
                        color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('$mins min',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('$kcal kcal',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Select Meal',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _DoubleRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = Paint()
      ..color = AppColors.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final inner = Paint()
      ..color = AppColors.carbsBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final track = Paint()
      ..color = AppColors.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, 48, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 48),
      -math.pi / 2,
      2 * math.pi * 0.72,
      false,
      outer,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 36),
      -math.pi / 2,
      2 * math.pi * 0.45,
      false,
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
