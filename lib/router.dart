import 'package:farmerconnect/404ErrorScreen.dart';
import 'package:farmerconnect/screens/auth/login_screen.dart';
import 'package:farmerconnect/screens/auth/user_details_screen.dart';
import 'package:farmerconnect/screens/home_screen.dart';
import 'package:farmerconnect/screens/onboarding/onboarding_screen.dart';
import 'package:farmerconnect/screens/splash_screen.dart';
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
