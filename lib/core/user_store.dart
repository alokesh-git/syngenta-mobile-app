import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent user/auth store. Holds login state, profile data, and
/// onboarding-seen flag. Replace with Firestore/secure storage in production.
class UserStore extends ChangeNotifier {
  UserStore._();
  static final UserStore instance = UserStore._();

  static const _kName = 'user.name';
  static const _kWhatsapp = 'user.whatsapp';
  static const _kLanguage = 'user.language';
  static const _kPhone = 'user.phone';
  static const _kLoggedIn = 'auth.loggedIn';
  static const _kOnboardingSeen = 'auth.onboardingSeen';

  late SharedPreferences _prefs;
  bool _ready = false;

  String _name = '';
  String _whatsappNumber = '';
  String _language = 'English';
  String _phone = '';
  bool _isLoggedIn = false;
  bool _onboardingSeen = false;

  String get name => _name;
  String get whatsappNumber => _whatsappNumber;
  String get language => _language;
  String get phone => _phone;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasProfile => _name.isNotEmpty && _whatsappNumber.isNotEmpty;
  bool get onboardingSeen => _onboardingSeen;
  bool get isReady => _ready;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _name = _prefs.getString(_kName) ?? '';
    _whatsappNumber = _prefs.getString(_kWhatsapp) ?? '';
    _language = _prefs.getString(_kLanguage) ?? 'English';
    _phone = _prefs.getString(_kPhone) ?? '';
    _isLoggedIn = _prefs.getBool(_kLoggedIn) ?? false;
    _onboardingSeen = _prefs.getBool(_kOnboardingSeen) ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    await _prefs.setBool(_kOnboardingSeen, true);
    notifyListeners();
  }

  /// Records login (real phone login or skip).
  Future<void> login({String phone = ''}) async {
    _phone = phone;
    _isLoggedIn = true;
    await _prefs.setString(_kPhone, phone);
    await _prefs.setBool(_kLoggedIn, true);
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required String whatsappNumber,
    required String language,
  }) async {
    _name = name.trim();
    _whatsappNumber = whatsappNumber.trim();
    _language = language;
    await _prefs.setString(_kName, _name);
    await _prefs.setString(_kWhatsapp, _whatsappNumber);
    await _prefs.setString(_kLanguage, _language);
    notifyListeners();
  }

  Future<void> updateLanguage(String language) async {
    _language = language;
    await _prefs.setString(_kLanguage, language);
    notifyListeners();
  }

  /// Full logout — clears user/profile but keeps onboardingSeen so we
  /// don't re-show onboarding after a logout.
  Future<void> logout() async {
    _name = '';
    _whatsappNumber = '';
    _language = 'English';
    _phone = '';
    _isLoggedIn = false;
    await _prefs.remove(_kName);
    await _prefs.remove(_kWhatsapp);
    await _prefs.remove(_kLanguage);
    await _prefs.remove(_kPhone);
    await _prefs.setBool(_kLoggedIn, false);
    notifyListeners();
  }
}
