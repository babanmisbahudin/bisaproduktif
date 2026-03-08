import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import 'habit_provider.dart';

// ── Reward Item (tidak disimpan di Hive) ──────────────────────────────────

class RewardItem {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int price;
  final String category; // 'semua', 'voucher', 'hiburan', 'makanan', 'premium'
  final Color color;

  const RewardItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.color,
  });
}

// ── Enum hasil redeem ──────────────────────────────────────────────────────

enum RedeemResult {
  success,
  insufficientCoins,
  trustFrozen,    // trust score < 40, koin dibekukan
  trustLimited,   // trust score 40-59, limit 500 koin/hari
  dailyLimitExceeded,
}

// ── Provider ──────────────────────────────────────────────────────────────

class RewardProvider extends ChangeNotifier {
  static const String _boxName = 'transactions';
  static const int _dailyLimitCoins = 500; // limit saat trust 40-59

  late Box<TransactionModel> _box;
  List<TransactionModel> _transactions = [];
  bool _isLoaded = false;

  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions);
  bool get isLoaded => _isLoaded;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<TransactionModel>(_boxName);
    _loadTransactions();
    _isLoaded = true;
    notifyListeners();
  }

  void _loadTransactions() {
    _transactions = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ── Catalog ───────────────────────────────────────────────────────────────

  static const List<RewardItem> catalog = [
    // ── Kopi ──────────────────────────────────────────────────────────────────
    RewardItem(
      id: 'kopi1',
      emoji: '☕',
      title: 'Kopi Premium',
      description: 'Kopi premium arabika pilihan. Sempurna untuk menemani hari produktifmu!',
      price: 20000,
      category: 'merchandise',
      color: Color(0xFF6F4E37),
    ),

    // ── Kaos ───────────────────────────────────────────────────────────────────
    RewardItem(
      id: 'kaos1',
      emoji: '👕',
      title: 'Kaos BisaProduktif',
      description: 'Kaos eksklusif branded BisaProduktif premium quality. Banggakan prestasimu!',
      price: 80000,
      category: 'merchandise',
      color: Color(0xFF4A7C59),
    ),

    // ── Buku Self Improvement ─────────────────────────────────────────────────
    RewardItem(
      id: 'buku1',
      emoji: '📖',
      title: 'Buku Self Improvement',
      description: 'Koleksi buku pengembangan diri terbaik. Investasi terbaik untuk masa depanmu!',
      price: 50000,
      category: 'merchandise',
      color: Color(0xFF1565C0),
    ),

    // ── Al Quran ───────────────────────────────────────────────────────────────
    RewardItem(
      id: 'quran1',
      emoji: '📕',
      title: 'Al Quran Premium',
      description: 'Al Quran edisi premium dengan terjemahan dan tajwid berwarna. Berkah untuk jiwa.',
      price: 100000,
      category: 'merchandise',
      color: Color(0xFF2E7D32),
    ),
  ];

  List<RewardItem> filteredCatalog(String category) {
    if (category == 'semua') return catalog;
    return catalog.where((r) => r.category == category).toList();
  }

  // ── Redeem ────────────────────────────────────────────────────────────────

  Future<RedeemResult> redeemReward({
    required RewardItem reward,
    required HabitProvider habitProvider,
    required String userId,
    required String userName,
  }) async {
    final trustScore = habitProvider.trustScore;
    final totalCoins = habitProvider.totalCoins;

    // Cek trust score
    if (trustScore < 40) return RedeemResult.trustFrozen;

    // Cek daily limit jika trust 40-59
    if (trustScore < 60) {
      if (reward.price > _dailyLimitCoins) return RedeemResult.dailyLimitExceeded;
      final spentToday = _coinsSpentToday();
      if (spentToday + reward.price > _dailyLimitCoins) {
        return RedeemResult.dailyLimitExceeded;
      }
    }

    // Cek koin cukup
    if (totalCoins < reward.price) return RedeemResult.insufficientCoins;

    // Simpan transaksi dengan status PENDING (waiting for admin approval)
    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      rewardId: reward.id,
      rewardTitle: reward.title,
      rewardEmoji: reward.emoji,
      coinsCost: reward.price,
      timestamp: DateTime.now(),
      status: 'pending', // Status pending, menunggu approval admin
      category: reward.category,
    );
    await _box.put(tx.id, tx);
    _loadTransactions();
    notifyListeners();

    return RedeemResult.success;
  }

  /// Admin approve redemption
  Future<bool> approvePendingRedemption({
    required String transactionId,
    required String adminEmail,
    required HabitProvider habitProvider,
  }) async {
    final tx = _box.get(transactionId);
    if (tx == null || tx.status != 'pending') return false;

    // Deduct coins saat approval
    await habitProvider.deductCoins(tx.coinsCost);

    // Update status
    tx.status = 'approved';
    tx.approvedBy = adminEmail;
    tx.approvedAt = DateTime.now();
    await _box.put(transactionId, tx);
    _loadTransactions();
    notifyListeners();
    return true;
  }

  /// Admin reject redemption
  Future<bool> rejectPendingRedemption({
    required String transactionId,
    required String adminEmail,
    required String reason,
  }) async {
    final tx = _box.get(transactionId);
    if (tx == null || tx.status != 'pending') return false;

    tx.status = 'rejected';
    tx.approvedBy = adminEmail;
    tx.approvedAt = DateTime.now();
    tx.rejectionReason = reason;
    await _box.put(transactionId, tx);
    _loadTransactions();
    notifyListeners();
    return true;
  }

  /// Get pending redemptions only
  List<TransactionModel> get pendingRedemptions =>
      _transactions.where((t) => t.status == 'pending').toList();

  /// Get all transactions (for history)
  List<TransactionModel> get approvedTransactions =>
      _transactions.where((t) => t.status == 'approved').toList();

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _coinsSpentToday() {
    final today = DateTime.now();
    return _transactions
        .where((t) =>
            t.timestamp.year == today.year &&
            t.timestamp.month == today.month &&
            t.timestamp.day == today.day)
        .fold(0, (sum, t) => sum + t.coinsCost);
  }

  int get coinsSpentToday => _coinsSpentToday();

  int get totalTransactions => _transactions.length;

  List<TransactionModel> get recentTransactions =>
      _transactions.take(10).toList();
}
