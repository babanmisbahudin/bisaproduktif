import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/reward_provider.dart';

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
    required int totalCoins,
    required int trustScore,
  }) async {
    if (!isLoggedIn) return;
    await _db.collection('users').doc(userId).set({
      'name': name,
      'totalCoins': totalCoins,
      'trustScore': trustScore,
      'lastSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Simpan nomor WhatsApp user ke Firestore.
  static Future<void> saveWhatsapp(String whatsapp) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(userId).set({
        'whatsapp': whatsapp,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firebase] Error saving whatsapp: $e');
    }
  }

  /// Simpan lokasi user (kota, provinsi, negara) ke Firestore.
  /// Dipanggil setelah login + dapat izin GPS.
  static Future<void> saveUserLocation(Map<String, String> location) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(userId).set({
        'location': {
          'city': location['city'] ?? '',
          'state': location['state'] ?? '',
          'country': location['country'] ?? '',
          'countryCode': location['countryCode'] ?? '',
          'displayAddress': location['displayAddress'] ?? '',
          'lat': location['lat'] ?? '',
          'lon': location['lon'] ?? '',
        },
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firebase] Error saving location: $e');
    }
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
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
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
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Log aksi admin ke activity_log (untuk audit trail)
  /// [action]: 'block_user' | 'unblock_user' | 'trust_adjust'
  /// [targetUid]: uid user yang dikenai aksi
  static Future<void> logAdminAction({
    required String action,
    required String targetUid,
    required Map<String, dynamic> data,
  }) async {
    if (!isLoggedIn) return;
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('activity_log')
          .add({
        'type': 'admin_$action',
        'targetUid': targetUid,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
      });
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
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

  /// Ambil semua user AKTIF dari Firestore untuk admin dashboard.
  /// Filter: isActive != false (exclude soft-deleted users)
  /// Returns list of {uid, name, totalCoins, trustScore, whatsapp, lastSync}
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!isLoggedIn) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .where('isActive', isNotEqualTo: false)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown',
          'totalCoins': data['totalCoins'] ?? 0,
          'trustScore': data['trustScore'] ?? 70,
          'whatsapp': data['whatsapp'] ?? '-',
          'lastSync': data['lastSync'],
          'isBlocked': data['isBlocked'] ?? false,
          'location': data['location'] as Map<String, dynamic>? ?? {},
          'locationUpdatedAt': data['locationUpdatedAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('[Firebase] Error fetching users: $e');
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
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
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
      final updateData = {
        'status': status,
        'approvedBy': adminEmail,
        'approvedAt': FieldValue.serverTimestamp(),
      };
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      await _db.collection('redemptions').doc(transactionId).update(updateData);
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  // ── Admin: User Management ───────────────────────────────────────────────────

  /// Block a user dari redeem rewards
  static Future<void> blockUser(String uid) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(uid).set({
        'isBlocked': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Unblock a user untuk redeem rewards
  static Future<void> unblockUser(String uid) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(uid).set({
        'isBlocked': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Update user trust score dengan alasan dari admin
  static Future<void> updateUserTrustScore(
    String uid,
    int newScore,
    String reason,
  ) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(uid).set({
        'trustScore': newScore.clamp(0, 100),
        'trustScoreReason': reason,
        'trustScoreUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Check apakah user sedang diblokir (untuk redemption guard)
  static Future<bool> isUserBlocked() async {
    if (!isLoggedIn) return false;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data()?['isBlocked'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Reward Catalog Management ──────────────────────────────────────────────

  /// Fetch semua active rewards dari Firestore untuk catalog
  /// Returns list of RewardItem objects
  static Future<List<RewardItem>> fetchRewards() async {
    try {
      final snapshot = await _db
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RewardItem.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add new reward (admin only)
  static Future<void> addReward(RewardItem reward) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('rewards').doc(reward.id).set({
        ...reward.toMap(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Update existing reward (admin only)
  static Future<void> updateReward(RewardItem reward) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('rewards').doc(reward.id).update(reward.toMap());
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Delete reward - soft delete (set isActive=false) untuk preserve history
  static Future<void> deleteReward(String rewardId) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('rewards').doc(rewardId).update({
        'isActive': false,
      });
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  // ── ADMIN USER MANAGEMENT ────────────────────────────────────────────────

  /// Hapus user dari Firestore (admin only)
  static Future<void> deleteUser(String uid) async {
    if (!isLoggedIn) return;
    try {
      // Soft delete - set isActive=false untuk preserve audit trail
      await _db.collection('users').doc(uid).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
      });
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Reset semua coins user ke 0 (admin only)
  static Future<void> resetUserCoins(String uid) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('users').doc(uid).update({
        'totalCoins': 0,
        'coinsResetAt': FieldValue.serverTimestamp(),
        'coinsResetBy': userId,
      });
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }

  /// Hapus semua reward transactions user (admin only)
  static Future<void> clearUserRewardTransactions(String uid) async {
    if (!isLoggedIn) return;
    try {
      // Delete transactions subcollection
      final batch = _db.batch();
      final transactionsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .get();
      for (final doc in transactionsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[Firebase] Error: $e');
    }
  }
}
