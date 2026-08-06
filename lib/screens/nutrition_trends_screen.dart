import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/kitchen_header.dart';
import 'meal_suggestions_screen.dart';

class NutritionTrendsScreen extends StatefulWidget {
  const NutritionTrendsScreen({super.key});

  @override
  State<NutritionTrendsScreen> createState() => _NutritionTrendsScreenState();
}

class _NutritionTrendsScreenState extends State<NutritionTrendsScreen> {
  bool _sevenDays = true;
  int _metric = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          const KitchenHeader(),
          const SizedBox(height: 12),
          Text(
            'Nutrition Trends',
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your culinary journey through data. Understanding your habits to fuel your hearth.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.chipInactive,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PeriodBtn(
                    label: '7 Days',
                    selected: _sevenDays,
                    onTap: () => setState(() => _sevenDays = true),
                  ),
                ),
                Expanded(
                  child: _PeriodBtn(
                    label: '30 Days',
                    selected: !_sevenDays,
                    onTap: () => setState(() => _sevenDays = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.local_fire_department_outlined,
            label: 'AVERAGE DAILY',
            value: '2,100 kcal',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward,
                    size: 14, color: AppColors.protein),
                Text(
                  '4% vs last week',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.protein,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.check_circle_outline,
            label: 'GOAL ACCURACY',
            value: '6/7 Days on Target',
            trailing: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  value: 0.86,
                  minHeight: 8,
                  backgroundColor: AppColors.progressTrack,
                  color: AppColors.successGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.restaurant,
            label: 'TOP CUISINE',
            value: 'Mediterranean',
            trailing: Text(
              'Consistent healthy fats this week.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Calorie Intake vs. Target',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(4, (i) {
              const labels = ['Calories', 'Protein', 'Carbs', 'Fat'];
              final selected = _metric == i;
              return GestureDetector(
                onTap: () => setState(() => _metric = i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.terracotta
                        : AppColors.chipInactive,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomPaint(
              painter: _LineChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map(
                  (d) => Text(
                    d,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Macro Nutrient Balance',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _MacroRing(
                  label: 'Protein',
                  percent: 0.80,
                  color: AppColors.successGreen,
                ),
              ),
              Expanded(
                child: _MacroRing(
                  label: 'Carbs',
                  percent: 0.60,
                  color: AppColors.carbsBrown,
                ),
              ),
              Expanded(
                child: _MacroRing(
                  label: 'Fats',
                  percent: 0.25,
                  color: AppColors.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "Chef's Wisdom",
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Fiber dipped midweek and protein was light on Wednesday. Add chickpeas to tomorrow\'s salad to rebalance both.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MealSuggestionsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.terracotta,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'View Recipe Suggestions',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  const _PeriodBtn({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.terracottaDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.seasonalCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.terracotta, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: CustomPaint(
            painter: _SimpleRing(progress: percent, color: color),
            child: Center(
              child: Text(
                '${(percent * 100).round()}%',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SimpleRing extends CustomPainter {
  _SimpleRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 8.0;
    final radius = size.width / 2 - stroke;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.progressTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleRing oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.55, 0.72, 0.48, 0.80, 0.65, 0.90, 0.70];
    final paint = Paint()
      ..color = AppColors.terracotta
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final goal = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // dotted goal line
    final gy = size.height * 0.35;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, gy), Offset(x + 4, gy), goal);
      x += 8;
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final px = size.width * (i / (values.length - 1));
      final py = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, paint);

    final dot = Paint()..color = AppColors.terracotta;
    for (var i = 0; i < values.length; i++) {
      final px = size.width * (i / (values.length - 1));
      final py = size.height * (1 - values[i]);
      canvas.drawCircle(Offset(px, py), 4, dot);
      canvas.drawCircle(
        Offset(px, py),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
