import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/farmer_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  FarmerModel? _farmerProfile;
  String? _errorMessage;
  String? _verificationId;
  bool _firebaseAvailable = false;

  AuthStatus get status => _status;
  User? get user => _user;
  FarmerModel? get farmerProfile => _farmerProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get firebaseAvailable => _firebaseAvailable;

  String get displayName {
    if (_farmerProfile != null && _farmerProfile!.name.isNotEmpty) {
      return _farmerProfile!.name;
    }
    if (_user?.displayName != null) return _user!.displayName!;
    if (_user?.phoneNumber != null) return _user!.phoneNumber!;
    return 'Farmer';
  }

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _authService.authStateChanges.listen((user) async {
        _user = user;
        _firebaseAvailable = true;
        if (user != null) {
          _status = AuthStatus.authenticated;
          await _loadFarmerProfile(user.uid);
        } else {
          _status = AuthStatus.unauthenticated;
          _farmerProfile = null;
        }
        notifyListeners();
      });
    } catch (e) {
      // Firebase not configured — run in demo mode
      _firebaseAvailable = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebaseAvailable) {
        final cred = await _authService.signInAnonymously();
        _user = cred.user;
      } else {
        // Demo mode: simulate anonymous user
        _farmerProfile = FarmerModel(
          uid: 'demo_user',
          name: 'Guest Farmer',
          isAnonymous: true,
          createdAt: DateTime.now(),
        );
      }
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> sendOTP(String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onVerificationCompleted: (credential) async {
          await _authService.signInWithCredential(credential);
        },
        onVerificationFailed: (e) {
          _errorMessage = e.message ?? 'Verification failed';
          _status = AuthStatus.error;
          notifyListeners();
        },
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        },
        onCodeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) return false;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.signInWithOTP(_verificationId!, otp);
      return true;
    } catch (e) {
      _errorMessage = 'Invalid OTP. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile(FarmerModel profile) async {
    _farmerProfile = profile;
    notifyListeners();
    if (_firebaseAvailable && _user != null) {
      try {
        await _firestoreService.saveFarmer(profile);
      } catch (_) {}
    }
  }

  Future<void> _loadFarmerProfile(String uid) async {
    try {
      _farmerProfile = await _firestoreService.getFarmer(uid);
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      if (_firebaseAvailable) await _authService.signOut();
    } catch (_) {}
    _user = null;
    _farmerProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
