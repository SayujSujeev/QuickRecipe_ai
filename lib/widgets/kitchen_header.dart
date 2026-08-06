import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class KitchenHeader extends StatelessWidget {
  const KitchenHeader({
    super.key,
    this.showBack = false,
    this.showBell = false,
    this.onLeading,
  });

  final bool showBack;
  final bool showBell;
  final VoidCallback? onLeading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onLeading ??
                (showBack ? () => Navigator.of(context).maybePop() : null),
            icon: Icon(
              showBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
              color: AppColors.terracotta,
            ),
          ),
          Expanded(
            child: Text(
              'Kitchen & Hearth',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.terracotta,
              ),
            ),
          ),
          if (showBell)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.notifications_none_rounded,
                  color: AppColors.terracotta),
            ),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
            ),
          ),
        ],
      ),
    );
  }
}
