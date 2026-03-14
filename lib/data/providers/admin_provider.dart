import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String? get adminEmail => _adminEmail;
  bool get isAdmin => _isAdmin;
  bool get isLockedOut => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);
  List<Map<String, dynamic>> get allUsers => List.unmodifiable(_allUsers);
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;

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
    return _allUsers.fold<int>(0, (sum, user) => sum + (user['totalCoins'] as int? ?? 0));
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
}
