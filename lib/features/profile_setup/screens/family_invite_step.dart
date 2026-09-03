import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/person_profile.dart';
import 'family_member_setup_screen.dart';

class FamilyInviteStep extends StatelessWidget {
  const FamilyInviteStep({
    super.key,
    required this.familyMembers,
    required this.onChanged,
    required this.onBack,
    required this.onFinish,
    required this.finishing,
  });

  final List<PersonProfile> familyMembers;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final bool finishing;

  Future<void> _addMember(BuildContext context) async {
    final result = await Navigator.of(context).push<PersonProfile>(
      MaterialPageRoute(builder: (_) => const FamilyMemberSetupScreen()),
    );
    if (result != null) {
      familyMembers.add(result);
      onChanged();
    }
  }

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
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.terracotta,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 1,
                        minHeight: 6,
                        backgroundColor: AppColors.progressTrack,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '4/4',
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.sageDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cooking for others too?',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add family or friends to tailor meal plans and nutrition targets around everyone in your kitchen.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addMember(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracottaDark,
                        side: const BorderSide(color: AppColors.terracotta),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Add Family Member',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (familyMembers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'FAMILY PREVIEW',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: familyMembers.map((m) {
                        return Container(
                          padding: const EdgeInsets.only(
                            left: 6,
                            right: 12,
                            top: 6,
                            bottom: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.progressTrack),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.sage,
                                child: Text(
                                  m.initial,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.sageDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                m.name,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  familyMembers.remove(m);
                                  onChanged();
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: finishing ? null : onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: finishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          familyMembers.isEmpty ? 'Skip for now' : 'Continue',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
