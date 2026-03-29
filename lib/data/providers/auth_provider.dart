import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import 'admin_provider.dart';
import 'user_profile_provider.dart';
import 'habit_provider.dart';

class AuthProvider extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  User? _user;
  bool _isLoading = false;
  String? _error;
  VoidCallback? onLogoutNavigate; // callback untuk navigate ke splash setelah logout

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

      // Simpan nama ke Firestore
      final prefs = await SharedPreferences.getInstance();
      await FirebaseService.saveUserProfile(
        name: prefs.getString('user_name') ?? _user?.displayName ?? '',
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

  /// Logout dan reset semua data (coins, habits, goals)
  Future<void> signOut() async {
    try {
      // Get current coins & trust score dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentCoins = prefs.getInt('user_coins') ?? 0;
      final currentTrustScore = prefs.getInt('trust_score') ?? 70;

      // Save actual coins & trust score to Firebase sebelum logout
      await FirebaseService.saveUserProfile(
        name: _user?.displayName ?? '',
        totalCoins: currentCoins,
        trustScore: currentTrustScore,
      );

      // Clear local data setelah Firebase save
      await prefs.remove('user_coins');
      await prefs.remove('trust_score');
      await prefs.remove('user_name');
    } catch (e) {
      debugPrint('[Auth] Failed to save data to Firebase: $e');
    }

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (_) {}

    _user = null;
    notifyListeners();

    // Trigger navigation callback setelah logout selesai
    onLogoutNavigate?.call();
  }

  /// Setelah signInWithGoogle() berhasil, panggil method ini untuk setup admin & auto-populate profile
  Future<void> completeGoogleLoginSetup({
    required AdminProvider adminProvider,
    required UserProfileProvider profileProvider,
    HabitProvider? habitProvider,
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

    // 3. Fetch coins dari Firebase & sync ke local storage
    try {
      final userData = await FirebaseService.getUserData();
      if (userData != null && userData['totalCoins'] != null) {
        final firebaseCoins = userData['totalCoins'] as int;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_coins', firebaseCoins);

        // Update HabitProvider dengan coins dari Firebase
        if (habitProvider != null) {
          habitProvider.syncCoinsFromFirebase(firebaseCoins);
        }

        debugPrint('[Auth] Coins synced from Firebase: $firebaseCoins');
      }
    } catch (e) {
      debugPrint('[Auth] Failed to sync coins from Firebase: $e');
    }

    // 4. Sync user profile ke Firebase (simpan nama, coins, trust score)
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalCoins = prefs.getInt('user_coins') ?? 0;
      final trustScore = prefs.getInt('trust_score') ?? 70;

      await FirebaseService.saveUserProfile(
        name: userName,
        totalCoins: totalCoins,
        trustScore: trustScore,
      );
      debugPrint('[Auth] Profile synced to Firebase');
    } catch (e) {
      debugPrint('[Auth] Failed to sync profile to Firebase: $e');
    }
  }
}
