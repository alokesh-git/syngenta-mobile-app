import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  int _currentTab = 0;
  String _selectedLanguageCode = 'en';
  bool _notificationsEnabled = true;

  int get currentTab => _currentTab;
  String get selectedLanguageCode => _selectedLanguageCode;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguageCode = prefs.getString('language') ?? 'en';
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    notifyListeners();
  }

  void setTab(int tab) {
    _currentTab = tab;
    notifyListeners();
  }

  Future<void> setLanguage(BuildContext context, String code) async {
    _selectedLanguageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
    await context.setLocale(Locale(code));
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    notifyListeners();
  }
}
