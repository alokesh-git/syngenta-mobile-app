import 'package:flutter/material.dart';

/// Maps UserStore language names to EasyLocalization Locale and TTS locale strings.
class AppLocale {
  static const Map<String, Locale> _locales = {
    'English': Locale('en'),
    'Hindi': Locale('hi'),
    'Tamil': Locale('ta'),
    'Telugu': Locale('te'),
    'Marathi': Locale('mr'),
  };

  static const Map<String, String> _ttsLocales = {
    'English': 'en-IN',
    'Hindi': 'hi-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Marathi': 'mr-IN',
  };

  static const List<Locale> supported = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te'),
    Locale('mr'),
  ];

  static Locale fromName(String name) => _locales[name] ?? const Locale('en');
  static String ttsFromName(String name) => _ttsLocales[name] ?? 'en-IN';
}
