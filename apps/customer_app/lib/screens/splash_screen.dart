import 'dart:async';

import 'package:flutter/material.dart';

import '../services/session_store.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import 'customer_shell.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Read the stored session while the logo is on screen.
    final next = _nextScreen();
    _timer = Timer(const Duration(milliseconds: 1200), () async {
      final screen = await next;
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    });
  }

  Future<Widget> _nextScreen() async {
    final user = await SessionStore.restoreUser();
    if (user != null) return CustomerShell(user: user);
    if (await SessionStore.onboardingSeen()) return const LoginScreen();
    return const OnboardingScreen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 260),
            const SizedBox(height: 8),
            const Text(
              'رحلات فاخرة بدون خرائط معقدة',
              style: TextStyle(color: mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
