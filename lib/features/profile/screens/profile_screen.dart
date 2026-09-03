import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/macro_backfill_service.dart';
import '../../../core/services/recipe_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/kitchen_header.dart';
import '../../common/screens/empty_states_screen.dart';
import '../../family/screens/family_members_screen.dart';
import '../../onboarding/screens/app_startup.dart';
import 'notifications_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;
  bool _importing = false;
  (int, int)? _importProgress;
  bool _calculatingMacros = false;
  (int, int)? _macroProgress;

  Future<void> _calculateMacros() async {
    setState(() {
      _calculatingMacros = true;
      _macroProgress = (0, 0);
    });
    try {
      final updated = await MacroBackfillService.instance.calculateForAll(
        onProgress: (completed, total) {
          if (mounted) setState(() => _macroProgress = (completed, total));
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated == 0
                ? 'All recipes already have macros calculated.'
                : 'Calculated macros for $updated recipe${updated == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Macro calculation failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _calculatingMacros = false;
          _macroProgress = null;
        });
      }
    }
  }

  static const _importCategories = [
    'Chicken',
    'Seafood',
    'Vegetarian',
    'Dessert',
    'Pasta',
    'Beef',
  ];
  static const _importCounts = [10, 25, 50, 100];

  Future<void> _showImportSheet() async {
    final result = await showModalBottomSheet<(String, int)>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? source;
        var count = 25;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Recipes',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull recipes from TheMealDB into your shared library.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'SOURCE',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in _importCategories)
                          ChoiceChip(
                            label: Text(
                              category,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: source == category,
                            selectedColor: AppColors.terracotta,
                            backgroundColor: AppColors.chipInactive,
                            labelStyle: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: source == category
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            onSelected: (_) =>
                                setSheetState(() => source = category),
                          ),
                        ChoiceChip(
                          avatar: Icon(
                            Icons.shuffle_rounded,
                            size: 16,
                            color: source == '__random__'
                                ? Colors.white
                                : AppColors.sageDark,
                          ),
                          label: Text(
                            'Random',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: source == '__random__'
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          selected: source == '__random__',
                          selectedColor: AppColors.terracotta,
                          backgroundColor: AppColors.sage,
                          onSelected: (_) =>
                              setSheetState(() => source = '__random__'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'HOW MANY',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _importCounts)
                          ChoiceChip(
                            label: Text(
                              '$c',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                color: count == c
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            selected: count == c,
                            selectedColor: AppColors.terracotta,
                            backgroundColor: AppColors.chipInactive,
                            onSelected: (_) => setSheetState(() => count = c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: source == null
                            ? null
                            : () => Navigator.of(context).pop((source!, count)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaDark,
                          disabledBackgroundColor: AppColors.progressTrack,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Import $count Recipe${count == 1 ? '' : 's'}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    final (source, count) = result;

    setState(() {
      _importing = true;
      _importProgress = (0, count);
    });
    void onProgress(int completed, int total) {
      if (mounted) setState(() => _importProgress = (completed, total));
    }

    try {
      final imported = source == '__random__'
          ? await RecipeRepository.instance.importRandom(
              count: count,
              onProgress: onProgress,
            )
          : await RecipeRepository.instance.importFromCategory(
              source,
              limit: count,
              onProgress: onProgress,
            );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $imported recipe${imported == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
          _importProgress = null;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Log out?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'You will need to sign in again to access your CookSense account.',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppStartup()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.instance.messageFor(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'CookSense Chef');
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          const KitchenHeader(),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.badgePeach,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : const NetworkImage(
                          'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80',
                        ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.terracotta,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const _StatCard(
            value: '24',
            label: 'RECIPES SAVED',
            valueColor: AppColors.terracotta,
            borderColor: AppColors.terracotta,
          ),
          const SizedBox(height: 10),
          const _StatCard(
            value: '3/5',
            label: 'IMPORTS USED',
            valueColor: AppColors.textPrimary,
            borderColor: AppColors.successGreen,
          ),
          const SizedBox(height: 10),
          const _StatCard(
            value: '42',
            label: 'RECIPES COOKED',
            valueColor: AppColors.carbs,
            borderColor: AppColors.carbs,
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.surface,
            elevation: 1.5,
            shadowColor: AppColors.shadow,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Health Profile',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF0EBE5)),
                _MenuTile(
                  icon: Icons.people_outline,
                  title: 'Family Members',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FamilyMembersScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF0EBE5)),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: '2 new alerts',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF0EBE5)),
                _MenuTile(
                  icon: Icons.desktop_windows_outlined,
                  title: 'Subscription',
                  subtitle: 'Premium Plan Active',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF0EBE5)),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmptyStatesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _importing ? null : _showImportSheet,
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.terracotta,
                    ),
                  )
                : const Icon(Icons.cloud_download_outlined),
            label: Text(
              _importing
                  ? 'Importing ${_importProgress?.$1 ?? 0}/${_importProgress?.$2 ?? 0}...'
                  : 'Import Recipes',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracotta,
              side: const BorderSide(color: AppColors.terracotta, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _calculatingMacros ? null : _calculateMacros,
            icon: _calculatingMacros
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.terracotta,
                    ),
                  )
                : const Icon(Icons.calculate_outlined),
            label: Text(
              _calculatingMacros
                  ? 'Calculating ${_macroProgress?.$1 ?? 0}/${_macroProgress?.$2 ?? 0}...'
                  : 'Calculate Macros',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracotta,
              side: const BorderSide(color: AppColors.terracotta, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.terracotta,
                    ),
                  )
                : const Icon(Icons.logout),
            label: Text(
              _loggingOut ? 'Logging out...' : 'Logout',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracotta,
              side: const BorderSide(color: AppColors.terracotta, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.borderColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(bottom: BorderSide(color: borderColor, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.sage,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.terracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
