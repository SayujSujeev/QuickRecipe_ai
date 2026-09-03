import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/kitchen_header.dart';
import 'log_meal_screen.dart';
import 'meal_suggestions_screen.dart';

class MealsDashboardScreen extends StatefulWidget {
  const MealsDashboardScreen({super.key});

  @override
  State<MealsDashboardScreen> createState() => _MealsDashboardScreenState();
}

class _MealsDashboardScreenState extends State<MealsDashboardScreen> {
  int _dayIndex = 1;

  static const _days = [
    ('Mon', '23'),
    ('Tue', '24'),
    ('Wed', '25'),
    ('Thu', '26'),
    ('Fri', '27'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const KitchenHeader(showBell: true),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _days.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _dayIndex;
                return GestureDetector(
                  onTap: () => setState(() => _dayIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.terracotta
                          : AppColors.chipInactive,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '${_days[i].$1} ${_days[i].$2}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: 1640 / 2450,
                        color: AppColors.terracotta,
                        stroke: 14,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CONSUMED',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '1,640 / 2,450',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'kcal today',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Macro Breakdown',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(
                        child: _MiniMacro(
                          icon: Icons.restaurant,
                          label: 'Protein',
                          value: '95g/184g',
                          progress: 95 / 184,
                          color: AppColors.protein,
                        ),
                      ),
                      Expanded(
                        child: _MiniMacro(
                          icon: Icons.grain,
                          label: 'Carbs',
                          value: '120g/280g',
                          progress: 120 / 280,
                          color: AppColors.carbs,
                        ),
                      ),
                      Expanded(
                        child: _MiniMacro(
                          icon: Icons.water_drop_outlined,
                          label: 'Fat',
                          value: '42g/65g',
                          progress: 42 / 65,
                          color: AppColors.fats,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LogMealScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'Log New Meal',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Family Profiles',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Manage Family',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _FamilyAvatar(
                  name: 'Jamie',
                  image:
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
                  selected: true,
                ),
                _FamilyAvatar(
                  name: 'Sam',
                  image:
                      'https://images.unsplash.com/photo-1503919545889-aef636e10ad2?w=200&q=80',
                ),
                _FamilyAvatar(
                  name: 'Sarah',
                  image:
                      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
                ),
                _AddFamilyAvatar(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Logged Meals',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MealSuggestionsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Suggestions',
                    style: GoogleFonts.dmSans(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _MealTimelineItem(
            icon: Icons.wb_sunny_outlined,
            title: 'Dragonfruit Bowl',
            tag: 'BREAKFAST',
            time: '8:30 AM',
            kcal: '420 kcal',
            progress: 0.45,
            image:
                'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300&q=80',
          ),
          const _MealTimelineItem(
            icon: Icons.lunch_dining_outlined,
            title: 'Chicken Med. Salad',
            tag: 'LUNCH',
            time: '1:10 PM',
            kcal: '580 kcal',
            progress: 0.7,
            image:
                'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&q=80',
          ),
          const _MealTimelineItem(
            icon: Icons.cookie_outlined,
            title: 'Choco Chip Snack',
            tag: 'SNACK',
            time: '4:05 PM',
            kcal: '210 kcal',
            progress: 0.25,
            image:
                'https://images.unsplash.com/photo-1499636139342-4aedc6e5e5c4?w=300&q=80',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  const _MiniMacro({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: color, stroke: 5),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FamilyAvatar extends StatelessWidget {
  const _FamilyAvatar({
    required this.name,
    required this.image,
    this.selected = false,
  });

  final String name;
  final String image;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.terracotta : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(image),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFamilyAvatar extends StatelessWidget {
  const _AddFamilyAvatar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          painter: _DashedCirclePainter(),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MealTimelineItem extends StatelessWidget {
  const _MealTimelineItem({
    required this.icon,
    required this.title,
    required this.tag,
    required this.time,
    required this.kcal,
    required this.progress,
    required this.image,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String tag;
  final String time;
  final String kcal;
  final double progress;
  final String image;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.chipInactive,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 14, color: AppColors.terracotta),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.progressTrack,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        image,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: AppColors.progressTrack,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kcal,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                  ],
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
  _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke;
    final track = Paint()
      ..color = AppColors.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    final circumference = 2 * math.pi * radius;
    var dist = 0.0;
    while (dist < circumference) {
      final a1 = dist / radius;
      final a2 = (dist + dash) / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        a1 - math.pi / 2,
        a2 - a1,
        false,
        paint,
      );
      dist += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
