import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import 'admin_provider.dart';
import 'user_profile_provider.dart';

class AuthProvider extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get displayName => _user?.displayName ?? '';
  String? get photoUrl => _user?.photoURL;
  String get email => _user?.email ?? '';

  /// Panggil setelah Firebase.initializeApp() sukses.
  void init() {
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
      _user = _auth.currentUser;
      _auth.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthProvider init failed (Firebase not ready): $e');
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User membatalkan sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _user = _auth.currentUser;

      // Simpan nama & gender dari SharedPreferences ke Firestore
      final prefs = await SharedPreferences.getInstance();
      await FirebaseService.saveUserProfile(
        name: prefs.getString('user_name') ?? _user?.displayName ?? '',
        gender: prefs.getString('user_gender') ?? 'male',
        totalCoins: 0, // akan di-update oleh HabitProvider
        trustScore: 70,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }

  /// Setelah signInWithGoogle() berhasil, panggil method ini untuk setup admin & auto-populate profile
  Future<void> completeGoogleLoginSetup({
    required AdminProvider adminProvider,
    required UserProfileProvider profileProvider,
  }) async {
    if (_user == null) return;

    final userEmail = _user!.email ?? '';
    final userName = _user!.displayName ?? '';

    // 1. Check & setup admin jika email sesuai
    if (AdminProvider.allowedAdmins.contains(userEmail.toLowerCase())) {
      try {
        await adminProvider.setAdminEmail(userEmail);
        debugPrint('[Auth] Admin setup successful for $userEmail');
      } catch (e) {
        debugPrint('[Auth] Admin setup failed: $e');
      }
    }

    // 2. Auto-populate profile dari Google user info
    await profileProvider.autoPopulateFromGoogle(
      googleName: userName,
      googleEmail: userEmail,
    );
  }
}
