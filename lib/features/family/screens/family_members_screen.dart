import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/kitchen_header.dart';
import 'add_family_member_screen.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  static const _members = [
    (
      'Jamie',
      '12 years old • Active',
      0.70,
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
      AppColors.terracotta,
    ),
    (
      'Sam',
      '8 years old • Growth',
      0.55,
      'https://images.unsplash.com/photo-1503919545889-aef636e10ad2?w=200&q=80',
      AppColors.successGreen,
    ),
    (
      'Sarah',
      'Adult • Maintenance',
      0.82,
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
      AppColors.olive,
    ),
    (
      'Dad',
      'Adult • Active',
      0.48,
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      AppColors.terracottaDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, canPop ? 32 : 120),
          children: [
            KitchenHeader(showBack: canPop),
            const SizedBox(height: 12),
            Text(
              'Family Members',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track nutritional progress for your loved ones.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ..._members.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(m.$4),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$1,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.$2,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CustomPaint(
                        painter: _RingPainter(progress: m.$3, color: m.$5),
                        child: Center(
                          child: Text(
                            '${(m.$3 * 100).round()}%',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddFamilyMemberScreen(),
                  ),
                );
              },
              child: CustomPaint(
                painter: _DashedRectPainter(),
                child: Container(
                  height: 110,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.terracotta,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+ Add Family Member',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 5.0;
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
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(r, Paint()..color = AppColors.seasonalCard);
    final paint = Paint()
      ..color = AppColors.inputBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 7.0;
    const gap = 5.0;
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
