import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _monthly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CookSense',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracottaDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=1000&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(height: 180, color: AppColors.searchFill),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PREMIUM EXPERIENCE',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the Full Kitchen',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Master your culinary journey with professional tools designed for the modern home chef. Personalized, efficient, and inspiring.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const _Feature(
              icon: Icons.auto_awesome,
              label: 'Unlimited AI Imports',
            ),
            const _Feature(
              icon: Icons.groups_outlined,
              label: 'Full Family Nutrition Profiles',
            ),
            const _Feature(
              icon: Icons.psychology_outlined,
              label: 'Personalized AI Coaching',
            ),
            const _Feature(
              icon: Icons.map_outlined,
              label: 'Grocery Store Aisle Mapping',
            ),
            const SizedBox(height: 18),
            _PlanCard(
              title: 'Monthly',
              subtitle: 'Flexible access',
              price: '\$9.99 per month',
              note: 'Cancel anytime',
              selected: _monthly,
              onTap: () => setState(() => _monthly = true),
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Yearly',
              subtitle: 'Ultimate savings',
              price: '\$79.99 per year',
              note: 'Save 33% annually',
              selected: !_monthly,
              badge: 'Best Value',
              onTap: () => setState(() => _monthly = false),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.successGreen,
                      content: Text(
                        '7-day free trial started',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Start 7-Day Free Trial',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'After your free trial ends, you will be charged unless you cancel. See Terms of Service and Privacy Policy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Trust(
                  icon: Icons.verified_user_outlined,
                  label: 'Secure Payments',
                ),
                _Trust(icon: Icons.star_outline, label: '4.9/5 Kitchen Rating'),
                _Trust(
                  icon: Icons.shield_outlined,
                  label: 'Privacy Guaranteed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.sageDark),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : AppColors.seasonalCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.terracottaDark : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.terracotta,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      note,
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
          if (badge != null)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.terracottaDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
