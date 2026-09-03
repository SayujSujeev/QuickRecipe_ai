import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Shared chrome for every step in the profile-setup wizard: a progress
/// bar, title/subtitle, scrollable body, and a bottom continue button.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.continueLabel,
    required this.onContinue,
    this.onBack,
    this.trailing,
    this.contextBadge,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final String continueLabel;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Small pill shown above the title, e.g. "Adding Family Member" — makes
  /// it unmistakable this step isn't asking about the signed-in user.
  final String? contextBadge;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: onBack != null
                        ? IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.terracotta,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: step / totalSteps,
                        minHeight: 6,
                        backgroundColor: AppColors.progressTrack,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$step/$totalSteps',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                children: [
                  if (contextBadge != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 14,
                              color: AppColors.sageDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              contextBadge!,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaDark,
                        disabledBackgroundColor: AppColors.progressTrack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        continueLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
