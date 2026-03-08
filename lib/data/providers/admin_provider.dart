import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import 'reward_provider.dart';
import 'habit_provider.dart';

class AdminProvider extends ChangeNotifier {
  static const String _adminEmailPref = 'admin_email';

  // List admin email yang diizinkan
  static const List<String> allowedAdmins = [
    'admin@bisaproduktif.com',
    'developer@bisaproduktif.com',
  ];

  String? _adminEmail;
  bool _isAdmin = false;

  String? get adminEmail => _adminEmail;
  bool get isAdmin => _isAdmin;

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

  /// Set admin email (untuk testing/setup)
  Future<void> setAdminEmail(String email) async {
    if (!allowedAdmins.contains(email)) {
      throw Exception('Email tidak terdaftar sebagai admin');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminEmailPref, email);
    _adminEmail = email;
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
  }) async {
    if (!_isAdmin) return false;

    return await rewardProvider.rejectPendingRedemption(
      transactionId: transactionId,
      adminEmail: _adminEmail!,
      reason: reason,
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
}
