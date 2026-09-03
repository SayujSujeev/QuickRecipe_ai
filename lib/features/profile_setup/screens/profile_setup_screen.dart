import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../data/models/person_profile.dart';
import '../../shell/main_shell.dart';
import '../widgets/details_step_content.dart';
import '../widgets/goal_step_content.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/taste_step_content.dart';
import 'family_invite_step.dart';

/// Post-signup wizard: taste preferences, personal details, goal, then an
/// optional step to add family/friends (each collected via the same
/// three questions, see [FamilyMemberSetupScreen]).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _profile = PersonProfile();
  final _familyMembers = <PersonProfile>[];
  final _pageController = PageController();
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    final displayName = AuthService.instance.currentUser?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      _profile.name = displayName;
    }
  }

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

  Future<void> _finish() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _finishing = true);
    try {
      await UserProfileService.instance.completeProfileSetup(
        uid: uid,
        profile: _profile,
        familyMembers: _familyMembers,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.instance.messageFor(e))),
      );
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StepScaffold(
          step: 1,
          totalSteps: 4,
          title: "What's your flavor?",
          subtitle:
              'Tell us what you love to cook and eat so we can tailor your recipe feed.',
          continueLabel: 'Continue',
          onContinue: () => _goTo(1),
          child: TasteStepContent(
            profile: _profile,
            onChanged: () => setState(() {}),
          ),
        ),
        StepScaffold(
          step: 2,
          totalSteps: 4,
          title: "Let's get to know you",
          subtitle:
              'We use these details to calculate your personalized nutrition needs and daily targets.',
          continueLabel: 'Continue',
          onBack: () => _goTo(0),
          onContinue: _profile.name.trim().isEmpty ? null : () => _goTo(2),
          child: DetailsStepContent(
            profile: _profile,
            onChanged: () => setState(() {}),
          ),
        ),
        StepScaffold(
          step: 3,
          totalSteps: 4,
          title: "What's your goal?",
          subtitle:
              "We'll tailor your daily nutritional targets based on your wellness journey.",
          continueLabel: 'Continue',
          onBack: () => _goTo(1),
          onContinue: _profile.goal == null ? null : () => _goTo(3),
          child: GoalStepContent(
            profile: _profile,
            onChanged: () => setState(() {}),
          ),
        ),
        FamilyInviteStep(
          familyMembers: _familyMembers,
          onChanged: () => setState(() {}),
          onBack: () => _goTo(2),
          onFinish: _finish,
          finishing: _finishing,
        ),
      ],
    );
  }
}
