import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wrapper untuk operasi Firebase Auth + Firestore.
/// Semua method aman dipanggil bahkan saat Firebase belum dikonfigurasi
/// (akan silently ignore jika isLoggedIn = false atau Firebase belum init).
class FirebaseService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String get userId => _auth.currentUser?.uid ?? '';

  // ── User Profile ────────────────────────────────────────────────────────

  /// Simpan/update profil user ke Firestore.
  static Future<void> saveUserProfile({
    required String name,
    required String gender,
    required int totalCoins,
    required int trustScore,
  }) async {
    if (!isLoggedIn) return;
    await _db.collection('users').doc(userId).set({
      'name': name,
      'gender': gender,
      'totalCoins': totalCoins,
      'trustScore': trustScore,
      'lastSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Coin Sync ───────────────────────────────────────────────────────────

  /// Update saldo koin di Firestore.
  static Future<void> syncCoins(int totalCoins) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(userId).set({
        'totalCoins': totalCoins,
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Activity Log (Anti-Fraud) ───────────────────────────────────────────

  /// Catat aktivitas user untuk keperluan anti-fraud.
  /// [type]: 'habit_complete' | 'goal_complete' | 'coin_redeem' | 'app_open'
  static Future<void> logActivity({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (!isLoggedIn) return;
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('activity_log')
          .add({
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
      });
    } catch (_) {}
  }

  // ── Fetch User Data ─────────────────────────────────────────────────────

  /// Ambil data user dari Firestore. Returns null jika belum login/error.
  static Future<Map<String, dynamic>?> getUserData() async {
    if (!isLoggedIn) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }
}
