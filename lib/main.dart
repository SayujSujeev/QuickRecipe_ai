import 'dart:async';
import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/auth_service.dart';
import 'core/services/share_intake_service.dart';
import 'core/theme/app_theme.dart';
import 'features/import_recipe/screens/import_recipe_screen.dart';
import 'features/onboarding/screens/app_startup.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.instance.initializeGoogleSignIn();
  runApp(const CookSenseApp());
}

class CookSenseApp extends StatefulWidget {
  const CookSenseApp({super.key});

  @override
  State<CookSenseApp> createState() => _CookSenseAppState();
}

class _CookSenseAppState extends State<CookSenseApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _pendingShares = Queue<SharedRecipePayload>();
  StreamSubscription<User?>? _authSubscription;
  bool _draining = false;
  bool _presenting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShareIntakeService.instance.listen(_drainShares);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _presentNextShare();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainShares());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _drainShares();
  }

  Future<void> _drainShares() async {
    if (_draining) return;
    _draining = true;
    try {
      final payloads = await ShareIntakeService.instance.drainPendingShares();
      _pendingShares.addAll(payloads);
      await _presentNextShare();
    } finally {
      _draining = false;
    }
  }

  Future<void> _presentNextShare() async {
    if (_presenting ||
        _pendingShares.isEmpty ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _presentNextShare());
      return;
    }

    final payload = _pendingShares.removeFirst();
    _presenting = true;
    try {
      if (payload.error != null) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(payload.error!)));
        }
        return;
      }
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ImportRecipeScreen(
            initialSharedText: payload.text,
            sharedVideoPath: payload.hasVideo ? payload.filePath : null,
            autoStart: true,
          ),
        ),
      );
    } finally {
      _presenting = false;
      if (_pendingShares.isNotEmpty) _presentNextShare();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CookSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppStartup(),
    );
  }
}
