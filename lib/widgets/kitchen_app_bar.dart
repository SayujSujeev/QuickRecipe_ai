import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class KitchenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KitchenAppBar({
    super.key,
    this.title = 'Kitchen & Hearth',
    this.leading,
    this.onLeading,
    this.showBack = false,
    this.showClose = false,
  });

  final String title;
  final Widget? leading;
  final VoidCallback? onLeading;
  final bool showBack;
  final bool showClose;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    Widget? lead = leading;
    if (lead == null) {
      if (showClose) {
        lead = IconButton(
          onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
        );
      } else if (showBack) {
        lead = IconButton(
          onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.terracotta),
        );
      } else {
        lead = IconButton(
          onPressed: onLeading,
          icon: const Icon(Icons.menu_rounded, color: AppColors.terracotta),
        );
      }
    }

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: lead,
      title: Text(
        title,
        style: GoogleFonts.fraunces(
          fontSize: title == 'Import Recipe' ? 22 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.terracotta,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.chipInactive,
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
            ),
            child: const Icon(Icons.person, size: 18, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
