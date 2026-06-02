import '404ErrorScreen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/user_details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String userDetails = '/user_details';
  static const String editProfile = '/edit_profile';
  static const String homeScreen = '/homeScreen';
  static const String notFoundScreen = '/not_found';

  static Route onGenrateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case userDetails:
        return MaterialPageRoute(builder: (_) => const UserDetailsScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const UserDetailsScreen(isEdit: true));
      case homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}
