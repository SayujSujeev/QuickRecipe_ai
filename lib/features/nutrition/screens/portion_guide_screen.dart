import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/adjust_servings_sheet.dart';

class PortionGuideScreen extends StatelessWidget {
  const PortionGuideScreen({super.key});

  static const _members = [
    _Member(
      name: 'Dad',
      badge: 'Active',
      servings: '1.5 Servings',
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
      calLeft: '1,420 / 2,800 kcal left',
      calProgress: 0.51,
      proteinLeft: '45g / 180g left',
      proteinProgress: 0.25,
      note: 'Adjusted for his high-intensity workout and protein goal today.',
    ),
    _Member(
      name: 'Mom',
      badge: 'Maintenance',
      servings: '1 Serving',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&q=80',
      calLeft: '950 / 2,100 kcal left',
      calProgress: 0.45,
      proteinLeft: '82g / 120g left',
      proteinProgress: 0.68,
      note: 'Balanced for her steady energy needs this week.',
    ),
    _Member(
      name: 'Sam (8)',
      badge: 'Growth',
      servings: '0.75 Serving',
      imageUrl:
          'https://images.unsplash.com/photo-1503919545889-aef636e10ad2?w=600&q=80',
      calLeft: '600 / 1,600 kcal left',
      calProgress: 0.38,
      proteinLeft: '12g / 45g left',
      proteinProgress: 0.27,
      note: 'Scaled for age-appropriate growth and activity.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.terracotta,
                  ),
                ),
                Expanded(
                  child: Text(
                    'CookSense',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracotta,
                    ),
                  ),
                ),
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.terracotta,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              label: Text(
                'Back to Recipes',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              'Portion Guide',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
                children: const [
                  TextSpan(
                    text:
                        'Recommended serving sizes based on individual daily goals and activity levels for ',
                  ),
                  TextSpan(
                    text: 'Roasted Harissa Salmon.',
                    style: TextStyle(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._members.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PortionCard(member: m),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finalizing the Meal?',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Portions have been added to the family tracker automatically.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.terracotta,
                            side: const BorderSide(color: AppColors.terracotta),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Edit Profiles',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await showAdjustServingsSheet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Confirm Service',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
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
      ),
    );
  }
}

class _Member {
  const _Member({
    required this.name,
    required this.badge,
    required this.servings,
    required this.imageUrl,
    required this.calLeft,
    required this.calProgress,
    required this.proteinLeft,
    required this.proteinProgress,
    required this.note,
  });

  final String name;
  final String badge;
  final String servings;
  final String imageUrl;
  final String calLeft;
  final double calProgress;
  final String proteinLeft;
  final double proteinProgress;
  final String note;
}

class _PortionCard extends StatelessWidget {
  const _PortionCard({required this.member});

  final _Member member;

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
            height: 140,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  member.imageUrl,
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
                      member.badge,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Recommended Portion',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      member.servings,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MetricBar(
                  label: 'Daily Calories',
                  value: member.calLeft,
                  progress: member.calProgress,
                  color: AppColors.terracotta,
                ),
                const SizedBox(height: 12),
                _MetricBar(
                  label: 'Daily Protein',
                  value: member.proteinLeft,
                  progress: member.proteinProgress,
                  color: AppColors.olive,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member.note,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                          height: 1.35,
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

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.progressTrack,
            color: color,
          ),
        ),
      ],
    );
  }
}
