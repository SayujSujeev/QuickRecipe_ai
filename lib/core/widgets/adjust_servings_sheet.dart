import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

Future<int?> showAdjustServingsSheet(
  BuildContext context, {
  int initialServings = 4,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _AdjustServingsSheet(initialServings: initialServings),
  );
}

class _AdjustServingsSheet extends StatefulWidget {
  const _AdjustServingsSheet({required this.initialServings});

  final int initialServings;

  @override
  State<_AdjustServingsSheet> createState() => _AdjustServingsSheetState();
}

class _AdjustServingsSheetState extends State<_AdjustServingsSheet> {
  late int _servings;
  static const _base = 4;

  static const _baseIngredients = [
    ('Heirloom Tomatoes', 1.5, 'lbs'),
    ('Fresh Mozzarella', 8.0, 'oz'),
    ('Basil Leaves', 1.0, ''),
    ('Extra Virgin Olive Oil', 0.5, 'cup'),
    ('Sea Salt', 1.0, 'tsp'),
  ];

  @override
  void initState() {
    super.initState();
    _servings = widget.initialServings;
  }

  String _qty(double base) {
    final v = base * _servings / _base;
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(v < 1 ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.progressTrack,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Adjust Servings',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Scale ingredients automatically',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.seasonalCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundCtrl(
                  icon: Icons.remove,
                  onTap: () {
                    if (_servings > 1) setState(() => _servings--);
                  },
                ),
                Column(
                  children: [
                    Text(
                      '$_servings',
                      style: GoogleFonts.dmSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'SERVINGS',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _RoundCtrl(
                  icon: Icons.add,
                  onTap: () => setState(() => _servings++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mintPill,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.olive),
                const SizedBox(width: 6),
                Text(
                  'Cook time: 35 min  →  ',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '35 min',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ADJUSTED INGREDIENTS',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE8E2DB)),
          ..._baseIngredients.map((item) {
            final unit = item.$3.isEmpty ? '' : ' ${item.$3}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.$1,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.peachBadge,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_qty(item.$2)}$unit',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_servings),
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
                'Apply & Save',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCtrl extends StatelessWidget {
  const _RoundCtrl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.terracottaDark),
        ),
      ),
    );
  }
}
