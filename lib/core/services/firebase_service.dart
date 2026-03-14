import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/transaction_model.dart';

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

  // ── Admin: Get All Users ────────────────────────────────────────────────────

  /// Ambil semua user dari Firestore untuk admin dashboard.
  /// Returns list of {uid, name, totalCoins, trustScore, gender, whatsapp, lastSync}
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!isLoggedIn) return [];
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown',
          'totalCoins': data['totalCoins'] ?? 0,
          'trustScore': data['trustScore'] ?? 70,
          'gender': data['gender'] ?? 'unknown',
          'whatsapp': data['whatsapp'] ?? '-',
          'lastSync': data['lastSync'],
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Redemption Sync ─────────────────────────────────────────────────────────

  /// Simpan redemption request ke Firestore global collection untuk admin
  static Future<void> saveRedemptionRequest(TransactionModel tx) async {
    try {
      // Simpan dengan userEmail dari current user
      final userEmail = _auth.currentUser?.email ?? '';
      await _db.collection('redemptions').doc(tx.id).set({
        'id': tx.id,
        'userId': tx.userId,
        'userEmail': userEmail,
        'userName': tx.userName,
        'rewardId': tx.rewardId,
        'rewardTitle': tx.rewardTitle,
        'rewardEmoji': tx.rewardEmoji,
        'coinsCost': tx.coinsCost,
        'timestamp': FieldValue.serverTimestamp(),
        'status': tx.status,
        'category': tx.category,
        'approvedBy': tx.approvedBy,
        'approvedAt': tx.approvedAt,
        'rejectionReason': tx.rejectionReason,
      });
    } catch (_) {}
  }

  /// Ambil semua pending redemption dari Firestore untuk admin
  /// Returns list of {id, userId, userEmail, userName, rewardTitle, coinsCost, timestamp, status, rewardEmoji}
  static Future<List<Map<String, dynamic>>> getAllPendingRedemptions() async {
    if (!isLoggedIn) return [];
    try {
      final snapshot = await _db
          .collection('redemptions')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] as String? ?? '',
          'userEmail': data['userEmail'] as String? ?? '',
          'userName': data['userName'] as String? ?? 'Unknown',
          'rewardTitle': data['rewardTitle'] as String? ?? 'Unknown Reward',
          'rewardEmoji': data['rewardEmoji'] as String? ?? '🎁',
          'coinsCost': data['coinsCost'] as int? ?? 0,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'status': data['status'] as String? ?? 'pending',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Update status redemption (approve/reject) di Firestore
  static Future<void> updateRedemptionStatus({
    required String transactionId,
    required String status, // 'approved' or 'rejected'
    required String adminEmail,
    String? rejectionReason,
  }) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('redemptions').doc(transactionId).update({
        'status': status,
        'approvedBy': adminEmail,
        'approvedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });
    } catch (_) {}
  }
}
