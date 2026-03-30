import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../models/transaction_model.dart';
import 'reward_provider.dart';
import 'habit_provider.dart';

class AdminProvider extends ChangeNotifier {
  static const String _adminEmailPref = 'admin_email';
  static const int _maxLoginAttempts = 3;
  static const int _lockoutMinutes = 60;

  // List admin email yang diizinkan
  static const List<String> allowedAdmins = [
    'babanmisbahudin200@gmail.com',
  ];

  String? _adminEmail;
  bool _isAdmin = false;
  int _loginAttempts = 0;
  DateTime? _lockedUntil;

  // User management
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  // Redemption management (from Firebase)
  List<Map<String, dynamic>> _pendingRedemptions = [];
  bool _isLoadingRedemptions = false;
  String? _redemptionsError;

  // Reward catalog management
  List<RewardItem> _adminRewards = [];
  bool _isLoadingRewards = false;
  StreamSubscription? _rewardsSub;

  String? get adminEmail => _adminEmail;
  bool get isAdmin => _isAdmin;
  bool get isLockedOut => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);
  List<Map<String, dynamic>> get allUsers => List.unmodifiable(_allUsers);
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;
  List<Map<String, dynamic>> get pendingRedemptions => List.unmodifiable(_pendingRedemptions);
  bool get isLoadingRedemptions => _isLoadingRedemptions;
  String? get redemptionsError => _redemptionsError;
  List<RewardItem> get adminRewards => List.unmodifiable(_adminRewards);
  bool get isLoadingRewards => _isLoadingRewards;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminEmail = prefs.getString(_adminEmailPref);
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    _isAdmin = _adminEmail != null && allowedAdmins.contains(_adminEmail);
    notifyListeners();
  }

  /// Set admin email (dengan rate limiting & security)
  Future<void> setAdminEmail(String email) async {
    // Cek lockout
    if (isLockedOut) {
      final minutesLeft = _lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      throw Exception('Akun terkunci. Coba lagi dalam $minutesLeft menit');
    }

    // Normalisasi dan validasi email
    final normalizedEmail = email.trim().toLowerCase();
    if (!allowedAdmins.contains(normalizedEmail)) {
      _loginAttempts++;
      if (_loginAttempts >= _maxLoginAttempts) {
        _lockedUntil = DateTime.now().add(Duration(minutes: _lockoutMinutes));
        debugPrint('[Admin Security] Account locked after $_loginAttempts attempts');
        notifyListeners();
        throw Exception('Terlalu banyak percobaan gagal. Akun terkunci 1 jam');
      }
      throw Exception('Email tidak terdaftar sebagai admin. Percobaan: $_loginAttempts/$_maxLoginAttempts');
    }

    // Login berhasil - reset attempts
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminEmailPref, normalizedEmail);
    _adminEmail = normalizedEmail;
    _loginAttempts = 0;
    _lockedUntil = null;

    // Log login
    debugPrint('[Admin Security] Admin login successful: $normalizedEmail at ${DateTime.now()}');

    _checkAdminStatus();
  }

  /// Clear admin login
  Future<void> clearAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminEmailPref);
    _adminEmail = null;
    _isAdmin = false;
    notifyListeners();
  }

  // ── Admin Actions ───────────────────────────────────────────────────────────

  /// Approve pending redemption
  Future<bool> approvePendingRedemption({
    required String transactionId,
    required RewardProvider rewardProvider,
    required HabitProvider habitProvider,
  }) async {
    if (!_isAdmin) return false;

    return await rewardProvider.approvePendingRedemption(
      transactionId: transactionId,
      adminEmail: _adminEmail!,
      habitProvider: habitProvider,
    );
  }

  /// Reject pending redemption
  Future<bool> rejectPendingRedemption({
    required String transactionId,
    required String reason,
    required RewardProvider rewardProvider,
    required HabitProvider habitProvider,
  }) async {
    if (!_isAdmin) return false;

    return await rewardProvider.rejectPendingRedemption(
      transactionId: transactionId,
      adminEmail: _adminEmail!,
      reason: reason,
      habitProvider: habitProvider,
    );
  }

  /// Get count of pending redemptions
  int getPendingCount(RewardProvider rewardProvider) {
    return rewardProvider.pendingRedemptions.length;
  }

  /// Get all pending redemptions
  List<TransactionModel> getPendingRedemptions(RewardProvider rewardProvider) {
    return rewardProvider.pendingRedemptions;
  }

  // ── User Management (Admin Dashboard) ─────────────────────────────────────

  /// Fetch semua user dari Firebase untuk admin dashboard
  Future<void> fetchAllUsers() async {
    if (!_isAdmin) return;

    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      _allUsers = await FirebaseService.getAllUsers();
      // Sort by totalCoins descending (terbanyak di atas)
      _allUsers.sort((a, b) => (b['totalCoins'] as int).compareTo(a['totalCoins'] as int));
      _usersError = null;
    } catch (e) {
      _usersError = 'Error: ${e.toString()}';
      debugPrint('[Admin] Error fetching users: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Get total coins beredar (sum semua user coins)
  int getTotalCoinsInCirculation() {
    return _allUsers.fold<int>(0, (total, user) => total + (user['totalCoins'] as int? ?? 0));
  }

  /// Get trust score distribution untuk chart
  Map<String, int> getTrustScoreDistribution() {
    final distribution = {
      'high': 0,    // 80-100
      'medium': 0,  // 60-79
      'low': 0,     // 0-59
    };

    for (final user in _allUsers) {
      final trustScore = user['trustScore'] as int? ?? 70;
      if (trustScore >= 80) {
        distribution['high'] = distribution['high']! + 1;
      } else if (trustScore >= 60) {
        distribution['medium'] = distribution['medium']! + 1;
      } else {
        distribution['low'] = distribution['low']! + 1;
      }
    }

    return distribution;
  }

  /// Get flagged users (trust score < 60) untuk fraud alerts
  List<Map<String, dynamic>> get flaggedUsers =>
      _allUsers.where((u) => (u['trustScore'] as int? ?? 70) < 60).toList();

  // ── User Management: Block/Unblock ──────────────────────────────────────────

  /// Block a user dari redeem rewards
  Future<bool> blockUser(String uid) async {
    if (!_isAdmin) return false;
    try {
      await FirebaseService.blockUser(uid);
      // Update local list untuk instant UI feedback
      final idx = _allUsers.indexWhere((u) => u['uid'] == uid);
      if (idx != -1) {
        _allUsers[idx] = Map.from(_allUsers[idx])..['isBlocked'] = true;
        notifyListeners();
        // Log admin action
        await FirebaseService.logAdminAction(
          action: 'block_user',
          targetUid: uid,
          data: {
            'adminEmail': _adminEmail,
            'userName': _allUsers[idx]['name'],
          },
        );
      }
      return true;
    } catch (e) {
      debugPrint('[Admin] Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user untuk redeem rewards
  Future<bool> unblockUser(String uid) async {
    if (!_isAdmin) return false;
    try {
      await FirebaseService.unblockUser(uid);
      // Update local list untuk instant UI feedback
      final idx = _allUsers.indexWhere((u) => u['uid'] == uid);
      if (idx != -1) {
        _allUsers[idx] = Map.from(_allUsers[idx])..['isBlocked'] = false;
        notifyListeners();
        // Log admin action
        await FirebaseService.logAdminAction(
          action: 'unblock_user',
          targetUid: uid,
          data: {
            'adminEmail': _adminEmail,
            'userName': _allUsers[idx]['name'],
          },
        );
      }
      return true;
    } catch (e) {
      debugPrint('[Admin] Error unblocking user: $e');
      return false;
    }
  }

  /// Adjust user trust score dengan alasan
  Future<bool> adjustUserTrustScore(
    String uid,
    int adjustment, // contoh: -10, -20, -30, +10
    String reason,
  ) async {
    if (!_isAdmin) return false;
    try {
      final idx = _allUsers.indexWhere((u) => u['uid'] == uid);
      if (idx == -1) return false;

      final current = _allUsers[idx]['trustScore'] as int? ?? 70;
      final newScore = (current + adjustment).clamp(0, 100);

      await FirebaseService.updateUserTrustScore(uid, newScore, reason);
      _allUsers[idx] = Map.from(_allUsers[idx])..['trustScore'] = newScore;
      notifyListeners();
      // Log admin action
      await FirebaseService.logAdminAction(
        action: 'trust_adjust',
        targetUid: uid,
        data: {
          'adminEmail': _adminEmail,
          'adjustment': adjustment,
          'newScore': newScore,
          'reason': reason,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[Admin] Error adjusting trust score: $e');
      return false;
    }
  }

  // ── Redemption Management (Firebase) ────────────────────────────────────────

  /// Fetch semua pending redemptions dari Firebase
  Future<void> fetchAllPendingRedemptions() async {
    if (!_isAdmin) return;

    _isLoadingRedemptions = true;
    _redemptionsError = null;
    notifyListeners();

    try {
      _pendingRedemptions = await FirebaseService.getAllPendingRedemptions();
      _redemptionsError = null;
    } catch (e) {
      _redemptionsError = 'Error: ${e.toString()}';
      debugPrint('[Admin] Error fetching redemptions: $e');
    } finally {
      _isLoadingRedemptions = false;
      notifyListeners();
    }
  }

  /// Approve pending redemption dari Firebase
  Future<bool> approveFirebaseRedemption({
    required String transactionId,
    required RewardProvider rewardProvider,
    required HabitProvider habitProvider,
  }) async {
    if (!_isAdmin) return false;

    try {
      await FirebaseService.updateRedemptionStatus(
        transactionId: transactionId,
        status: 'approved',
        adminEmail: _adminEmail!,
      );

      // Reload redemptions dari Firebase
      await fetchAllPendingRedemptions();
      return true;
    } catch (e) {
      debugPrint('[Admin] Error approving redemption: $e');
      return false;
    }
  }

  /// Reject pending redemption dari Firebase
  Future<bool> rejectFirebaseRedemption({
    required String transactionId,
    required String reason,
    required RewardProvider rewardProvider,
    required HabitProvider habitProvider,
  }) async {
    if (!_isAdmin) return false;

    try {
      await FirebaseService.updateRedemptionStatus(
        transactionId: transactionId,
        status: 'rejected',
        adminEmail: _adminEmail!,
        rejectionReason: reason,
      );

      // Reload redemptions dari Firebase
      await fetchAllPendingRedemptions();
      return true;
    } catch (e) {
      debugPrint('[Admin] Error rejecting redemption: $e');
      return false;
    }
  }

  // ── Reward Catalog Management ──────────────────────────────────────────────

  /// Subscribe real-time ke rewards Firestore untuk admin catalog
  void fetchAdminRewards() {
    if (!_isAdmin) return;

    _rewardsSub?.cancel();
    _isLoadingRewards = true;
    notifyListeners();

    _rewardsSub = FirebaseFirestore.instance
        .collection('rewards')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _adminRewards = snapshot.docs.map((doc) {
        final data = doc.data();
        return RewardItem(
          id: doc.id,
          emoji: data['emoji'] ?? '🎁',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          price: data['price'] ?? 0,
          category: data['category'] ?? 'merchandise',
          color: Color(data['colorValue'] ?? 0xFF4A7C59),
        );
      }).toList();
      _isLoadingRewards = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('[Admin] Error stream rewards: $e');
      _isLoadingRewards = false;
      notifyListeners();
    });
  }

  /// Add new reward
  Future<bool> addReward(RewardItem reward) async {
    if (!_isAdmin) return false;

    try {
      await FirebaseService.addReward(reward);
      // Stream listener akan auto-update _adminRewards
      return true;
    } catch (e) {
      debugPrint('[Admin] Error adding reward: $e');
      return false;
    }
  }

  /// Update existing reward
  Future<bool> updateReward(RewardItem reward) async {
    if (!_isAdmin) return false;

    try {
      await FirebaseService.updateReward(reward);
      // Update local list untuk instant UI feedback
      final idx = _adminRewards.indexWhere((r) => r.id == reward.id);
      if (idx != -1) {
        _adminRewards[idx] = reward;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Admin] Error updating reward: $e');
      return false;
    }
  }

  /// Delete reward (soft delete)
  Future<bool> deleteReward(String rewardId) async {
    if (!_isAdmin) return false;

    try {
      await FirebaseService.deleteReward(rewardId);
      // Remove dari local list
      _adminRewards.removeWhere((r) => r.id == rewardId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Admin] Error deleting reward: $e');
      return false;
    }
  }

  // ── USER MANAGEMENT ─────────────────────────────────────────────────────────

  /// Hapus user dari sistem (dari Firestore + local storage)
  Future<bool> deleteUser(String uid) async {
    try {
      await FirebaseService.deleteUser(uid);
      _allUsers.removeWhere((u) => u['uid'] == uid);
      notifyListeners();
      debugPrint('[Admin] User deleted successfully: $uid');
      return true;
    } catch (e) {
      debugPrint('[Admin] Error deleting user: $e');
      return false;
    }
  }

  /// Reset/hapus semua reward points (coins) user
  Future<bool> resetUserCoins(String uid) async {
    try {
      await FirebaseService.resetUserCoins(uid);
      // Refresh dari Firebase untuk ensure data latest
      await fetchAllUsers();
      debugPrint('[Admin] User coins reset: $uid');
      return true;
    } catch (e) {
      debugPrint('[Admin] Error resetting user coins: $e');
      return false;
    }
  }

  /// Reset reward transactions user (hapus riwayat transaksi reward)
  Future<bool> clearUserRewardHistory(String uid) async {
    try {
      await FirebaseService.clearUserRewardTransactions(uid);
      debugPrint('[Admin] User reward history cleared: $uid');
      return true;
    } catch (e) {
      debugPrint('[Admin] Error clearing reward history: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _rewardsSub?.cancel();
    super.dispose();
  }
}
