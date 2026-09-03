import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/onboarding_prefs.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../../profile_setup/screens/profile_setup_screen.dart';
import '../../shell/main_shell.dart';
import 'onboarding_screen.dart';

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final done = await OnboardingPrefs.isComplete();
    if (!mounted) return;
    setState(() => _onboardingDone = done);
  }

  Future<void> _completeOnboarding() async {
    await OnboardingPrefs.markComplete();
    if (!mounted) return;
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const _BootLoader();
    }

    if (_onboardingDone != true) {
      return OnboardingScreen(onFinished: _completeOnboarding);
    }

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _BootLoader();
        }

        final user = authSnap.data;
        if (user == null) {
          return const SignInScreen();
        }

        return _ProfileGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

/// Ensures the Firestore user document exists, then routes to the
/// profile-setup wizard or straight into the app depending on whether
/// `users/{uid}.profileComplete` is already true.
class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key, required this.user});

  final User user;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final Future<bool> _profileComplete = _load();

  Future<bool> _load() async {
    await UserProfileService.instance.ensureUserDocument(widget.user);
    return UserProfileService.instance.isProfileComplete(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _profileComplete,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _BootLoader();
        }
        return snapshot.data == true
            ? const MainShell()
            : const ProfileSetupScreen();
      },
    );
  }
}

class _BootLoader extends StatelessWidget {
  const _BootLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.terracotta),
      ),
    );
  }
}
