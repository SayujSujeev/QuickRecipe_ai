import 'package:flutter/material.dart';

import '../../../data/models/person_profile.dart';
import '../widgets/details_step_content.dart';
import '../widgets/goal_step_content.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/taste_step_content.dart';

/// Same three questions as the primary onboarding flow (taste, details,
/// goal), reused to build a profile for a family member.
class FamilyMemberSetupScreen extends StatefulWidget {
  const FamilyMemberSetupScreen({super.key});

  @override
  State<FamilyMemberSetupScreen> createState() =>
      _FamilyMemberSetupScreenState();
}

class _FamilyMemberSetupScreenState extends State<FamilyMemberSetupScreen> {
  final _profile = PersonProfile();
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  String get _badge {
    final name = _profile.name.trim();
    return name.isEmpty ? 'Adding Family Member' : 'Adding $name';
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StepScaffold(
          step: 1,
          totalSteps: 3,
          contextBadge: _badge,
          title: "What's their flavor?",
          subtitle:
              'Tell us what they love to cook and eat so we can tailor recommendations.',
          continueLabel: 'Continue',
          onBack: () => Navigator.of(context).maybePop(),
          onContinue: () => _goTo(1),
          child: TasteStepContent(
            profile: _profile,
            onChanged: () => setState(() {}),
          ),
        ),
        StepScaffold(
          step: 2,
          totalSteps: 3,
          contextBadge: _badge,
          title: 'Tell us about them',
          subtitle:
              "We'll use this to calculate their personalized nutrition needs.",
          continueLabel: 'Continue',
          onBack: () => _goTo(0),
          onContinue: _profile.name.trim().isEmpty ? null : () => _goTo(2),
          child: DetailsStepContent(
            profile: _profile,
            nameLabel: 'NICKNAME',
            nameHint: 'e.g. Leo',
            onChanged: () => setState(() {}),
          ),
        ),
        StepScaffold(
          step: 3,
          totalSteps: 3,
          contextBadge: _badge,
          title: "What's their goal?",
          subtitle: "We'll tailor meal recommendations around this.",
          continueLabel: 'Add to Family',
          onBack: () => _goTo(1),
          onContinue: _profile.goal == null
              ? null
              : () => Navigator.of(context).pop(_profile),
          child: GoalStepContent(
            profile: _profile,
            onChanged: () => setState(() {}),
          ),
        ),
      ],
    );
  }
}
