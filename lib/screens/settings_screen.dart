import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/kitchen_header.dart';
import 'offline_screen.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _metric = true;
  bool _daily = true;
  bool _milestones = true;
  bool _trending = false;
  final _prefs = <String>{'High Protein', 'Dairy Free'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            KitchenHeader(
              showBack: Navigator.of(context).canPop(),
            ),
            const SizedBox(height: 8),
            Text(
              'Settings',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Customize your culinary experience and account preferences.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.straighten,
                    title: 'Measurement Units',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.searchFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Preference',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose between Metric or Imperial units for recipes.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.chipInactive,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _Seg(
                                  label: 'Metric',
                                  selected: _metric,
                                  onTap: () => setState(() => _metric = true),
                                ),
                              ),
                              Expanded(
                                child: _Seg(
                                  label: 'Imperial',
                                  selected: !_metric,
                                  onTap: () => setState(() => _metric = false),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                  ),
                  _ToggleRow(
                    title: 'Daily Reminders',
                    subtitle: 'Meal logging nudges throughout the day.',
                    value: _daily,
                    onChanged: (v) => setState(() => _daily = v),
                  ),
                  const Divider(height: 1),
                  _ToggleRow(
                    title: 'Goal Milestones',
                    subtitle: 'Celebrate when you hit protein or calorie goals.',
                    value: _milestones,
                    onChanged: (v) => setState(() => _milestones = v),
                  ),
                  const Divider(height: 1),
                  _ToggleRow(
                    title: 'New Trending Recipes',
                    subtitle: 'Weekly picks based on your tastes.',
                    value: _trending,
                    onChanged: (v) => setState(() => _trending = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.restaurant,
                    title: 'Dietary Preferences',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._prefs.map(
                        (p) => Chip(
                          label: Text(p),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => _prefs.remove(p)),
                          backgroundColor: AppColors.sage,
                          side: BorderSide.none,
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Add Preference'),
                        onPressed: () {
                          setState(() => _prefs.add('Gluten Free'));
                        },
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(
                          color: AppColors.terracotta,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  const _SectionTitle(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Account Settings',
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline,
                        color: AppColors.terracotta),
                    title: Text('Email Address',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      'maria.cooks@example.com',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline,
                        color: AppColors.terracotta),
                    title: Text('Password',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      'Last updated 3 months ago',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline,
                        color: Color(0xFFC44536)),
                    title: Text(
                      'Delete Account',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC44536),
                      ),
                    ),
                    subtitle: Text(
                      'Permanently remove your data from Kitchen & Hearth.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  const _SectionTitle(
                    icon: Icons.info_outline,
                    title: 'About',
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Terms of Service',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () {},
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Privacy Policy',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () {},
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Offline Mode',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OfflineScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Upgrade Plan',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kitchen & Hearth v2.4.1',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '© 2024 Modern Culinary Systems Inc.',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
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

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
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
          color: selected ? AppColors.terracotta : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.terracotta,
      onChanged: onChanged,
    );
  }
}
