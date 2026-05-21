import 'package:flutter/material.dart';

class NavigatorService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Future<void> pushNamed(String routeName, {dynamic arguments}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
    });
  }

  static void goBack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pop();
    });
  }

  static Future<void> pushNamedAndRemoveUntil(String routeName,
      {bool routePredicate = false, dynamic arguments}) async {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName, (route) => routePredicate,
        arguments: arguments);
    // });
  }

  static Future<void> popAndPushNamed(String routeName,
      {dynamic arguments}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState
          ?.popAndPushNamed(routeName, arguments: arguments);
    });
  }
}
