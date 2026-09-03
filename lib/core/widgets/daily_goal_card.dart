import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/nutrition_calculator.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.targets});

  /// The signed-in user's stored daily targets (from the profile-setup
  /// wizard). Null while loading, or if they haven't completed setup.
  ///
  /// There's no meal-logging backend yet, so "consumed so far" isn't real
  /// data — this only shows the target, not a fabricated progress number.
  final DailyTargets? targets;

  @override
  Widget build(BuildContext context) {
    final t = targets;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 8),
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
                  "Today's Target",
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t == null ? '— kcal' : '${t.kcal} kcal',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MacroStat(
                      label: 'Protein',
                      value: t == null ? '—' : '${t.proteinG}g',
                      color: AppColors.protein,
                    ),
                    const SizedBox(width: 18),
                    _MacroStat(
                      label: 'Carbs',
                      value: t == null ? '—' : '${t.carbsG}g',
                      color: AppColors.carbs,
                    ),
                    const SizedBox(width: 18),
                    _MacroStat(
                      label: 'Fats',
                      value: t == null ? '—' : '${t.fatsG}g',
                      color: AppColors.fats,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GoalRing(bmi: t?.bmi),
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Shows BMI rather than a fake "calories consumed today" ring — there's
/// no meal-logging backend yet, so a real progress percentage isn't
/// available, but BMI is real data straight from the user's profile.
class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.bmi});

  final double? bmi;

  @override
  Widget build(BuildContext context) {
    final normalized = bmi == null ? 0.0 : (bmi! / 40).clamp(0.0, 1.0);

    return SizedBox(
      width: 84,
      height: 84,
      child: CustomPaint(
        painter: _RingPainter(progress: normalized),
        child: Center(
          child: bmi == null
              ? Text(
                  '—',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bmi!.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'BMI',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const stroke = 8.0;

    final track = Paint()
      ..color = const Color(0xFFF0E8E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
