import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/user_store.dart';
import '../router.dart';

/// App entry point. Initializes [UserStore] and routes to the correct
/// screen based on auth + profile state:
///   - no onboarding seen → OnboardingScreen
///   - not logged in     → LoginScreen
///   - logged in, no profile → UserDetailsScreen
///   - fully set up      → HomeScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!UserStore.instance.isReady) {
      await UserStore.instance.init();
    }
    // Small delay so the splash is visible briefly
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final store = UserStore.instance;
    String route;
    if (!store.onboardingSeen) {
      route = AppRoutes.onboarding;
    } else if (!store.isLoggedIn) {
      route = AppRoutes.login;
    } else if (!store.hasProfile) {
      route = AppRoutes.userDetails;
    } else {
      route = AppRoutes.homeScreen;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 72, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'KisanConnect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-powered crop assistant',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
