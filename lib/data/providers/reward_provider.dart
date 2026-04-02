import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../core/services/firebase_service.dart';
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

  // Convert ke Firestore map
  Map<String, dynamic> toMap() => {
    'id': id,
    'emoji': emoji,
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'colorValue': color.toARGB32(), // int (ARGB), e.g. 0xFF6F4E37
  };

  // Construct dari Firestore doc
  factory RewardItem.fromMap(Map<String, dynamic> map) => RewardItem(
    id: map['id'] as String? ?? '',
    emoji: map['emoji'] as String? ?? '🎁',
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    price: map['price'] as int? ?? 0,
    category: map['category'] as String? ?? 'merchandise',
    color: Color(map['colorValue'] as int? ?? 0xFF4A7C59),
  );
}

// ── Enum hasil redeem ──────────────────────────────────────────────────────

enum RedeemResult {
  success,
  insufficientCoins,
  trustFrozen,        // trust score < 40, koin dibekukan
  trustLimited,       // trust score 40-59, limit 500 koin/hari
  dailyLimitExceeded,
  blocked,            // user diblokir oleh admin
  alreadyRequested,   // duplicate pending redemption
  tooManyPending,     // terlalu banyak redemption pending
}

// ── Provider ──────────────────────────────────────────────────────────────

class RewardProvider extends ChangeNotifier {
  static const String _boxName = 'transactions';
  static const int _dailyLimitCoins = 500; // limit saat trust 40-59
  static const String _lastRedeemKey = 'last_redeem_timestamp';
  static const int _cooldownMinutes = 5; // cooldown 5 menit antar redeem
  static const int _maxPendingRedemptions = 3; // max 3 pending sekaligus

  late Box<TransactionModel> _box;
  List<TransactionModel> _transactions = [];
  bool _isLoaded = false;
  List<RewardItem> _dynamicCatalog = [];
  bool _isCatalogLoaded = false;
  StreamSubscription? _rewardsSub;

  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions);
  bool get isLoaded => _isLoaded;
  List<RewardItem> get dynamicCatalog =>
      List.unmodifiable(_dynamicCatalog);
  bool get isCatalogLoaded => _isCatalogLoaded;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<TransactionModel>(_boxName);
    _loadTransactions();
    _isLoaded = true;
    // Subscribe to real-time reward updates dari Firestore
    _subscribeToRewards();
    notifyListeners();
  }

  void _loadTransactions() {
    _transactions = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ── Dynamic Catalog (Real-time dari Firestore) ────────────────────────────

  void _subscribeToRewards() {
    try {
      _rewardsSub = FirebaseFirestore.instance
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        _dynamicCatalog = snapshot.docs.map((doc) {
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
        _isCatalogLoaded = true;
        notifyListeners();
      }, onError: (error) {
        // Jika error, gunakan hardcoded catalog
        debugPrint('[RewardProvider] Firestore error: $error');
        _dynamicCatalog = List.from(catalog);
        _isCatalogLoaded = true;
        notifyListeners();
      });
    } catch (e) {
      // Jika exception, gunakan hardcoded catalog
      debugPrint('[RewardProvider] Error subscribing to rewards: $e');
      _dynamicCatalog = List.from(catalog);
      _isCatalogLoaded = true;
      notifyListeners();
    }
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
      category: 'makanan',
      color: Color(0xFF6F4E37),
    ),

    // ── Kaos ───────────────────────────────────────────────────────────────────
    RewardItem(
      id: 'kaos1',
      emoji: '👕',
      title: 'Kaos BisaProduktif',
      description: 'Kaos eksklusif branded BisaProduktif premium quality. Banggakan prestasimu!',
      price: 80000,
      category: 'premium',
      color: Color(0xFF4A7C59),
    ),

    // ── Buku Self Improvement ─────────────────────────────────────────────────
    RewardItem(
      id: 'buku1',
      emoji: '📖',
      title: 'Buku Self Improvement',
      description: 'Koleksi buku pengembangan diri terbaik. Investasi terbaik untuk masa depanmu!',
      price: 50000,
      category: 'voucher',
      color: Color(0xFF1565C0),
    ),

    // ── Al Quran ───────────────────────────────────────────────────────────────
    RewardItem(
      id: 'quran1',
      emoji: '📕',
      title: 'Al Quran Premium',
      description: 'Al Quran edisi premium dengan terjemahan dan tajwid berwarna. Berkah untuk jiwa.',
      price: 100000,
      category: 'premium',
      color: Color(0xFF2E7D32),
    ),
  ];

  List<RewardItem> filteredCatalog(String category) {
    final source = _isCatalogLoaded ? _dynamicCatalog : catalog;
    if (category == 'semua') return source;
    return source.where((r) => r.category == category).toList();
  }

  // ── Redeem ────────────────────────────────────────────────────────────────

  Future<RedeemResult> redeemReward({
    required RewardItem reward,
    required HabitProvider habitProvider,
    required String userId,
    required String userName,
    String userWhatsapp = '',
    String userAddress = '',
  }) async {
    final trustScore = habitProvider.trustScore;
    final totalCoins = habitProvider.totalCoins;

    // Cek trust score
    if (trustScore < 40) return RedeemResult.trustFrozen;

    // Cek daily limit jika trust 40-59
    if (trustScore < 60) {
      if (reward.price > _dailyLimitCoins) return RedeemResult.dailyLimitExceeded;
      final spentToday = _coinsSpentToday(); // hanya approved
      if (spentToday + reward.price > _dailyLimitCoins) {
        return RedeemResult.dailyLimitExceeded;
      }
    }

    // Cek koin cukup
    if (totalCoins < reward.price) return RedeemResult.insufficientCoins;

    // Cek apakah user diblokir oleh admin
    final isBlocked = await FirebaseService.isUserBlocked();
    if (isBlocked) return RedeemResult.blocked;

    // Anti-fraud: cek duplikat pending untuk reward yang sama
    final hasDuplicate = pendingRedemptions.any((t) =>
        t.rewardId == reward.id && t.userId == userId);
    if (hasDuplicate) {
      debugPrint('[Anti-Fraud] Duplicate pending redemption detected for reward ${reward.id}');
      return RedeemResult.alreadyRequested; // Return proper error
    }

    // Anti-fraud: max 3 pending sekaligus
    if (pendingRedemptions.length >= _maxPendingRedemptions) {
      debugPrint('[Anti-Fraud] Max pending redemptions reached (${pendingRedemptions.length})');
      return RedeemResult.tooManyPending; // Return proper error
    }

    // Anti-fraud: cek cooldown 5 menit
    final prefs = await SharedPreferences.getInstance();
    final lastRedeemStr = prefs.getString(_lastRedeemKey);
    if (lastRedeemStr != null) {
      final lastRedeem = DateTime.tryParse(lastRedeemStr);
      if (lastRedeem != null) {
        final minutesSinceLastRedeem = DateTime.now().difference(lastRedeem).inMinutes;
        if (minutesSinceLastRedeem < _cooldownMinutes) {
          debugPrint('[Anti-Fraud] Redeem cooldown active. Last redeem: $minutesSinceLastRedeem minutes ago');
          return RedeemResult.success; // Silent fail
        }
      }
    }

    // FREEZE COINS: deduct coins segera saat pending (akan direfund jika reject)
    await habitProvider.deductCoins(reward.price);

    // Simpan transaksi dengan status PENDING
    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      rewardId: reward.id,
      rewardTitle: reward.title,
      rewardEmoji: reward.emoji,
      coinsCost: reward.price,
      timestamp: DateTime.now(),
      status: 'pending',
      category: reward.category,
    );
    await _box.put(tx.id, tx);

    // Sync redemption ke Firebase (async, tidak perlu await)
    FirebaseService.saveRedemptionRequest(
      tx,
      userWhatsapp: userWhatsapp,
      userAddress: userAddress,
    );

    // Simpan last redeem timestamp
    await prefs.setString(_lastRedeemKey, DateTime.now().toIso8601String());

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

    // CATATAN: koin sudah dipotong saat user request (status pending)
    // Jangan deduct lagi di sini — cukup update status saja

    // Update status lokal
    tx.status = 'approved';
    tx.approvedBy = adminEmail;
    tx.approvedAt = DateTime.now();
    await _box.put(transactionId, tx);

    // Sync ke Firebase agar user tahu statusnya diupdate
    FirebaseService.updateRedemptionStatus(
      transactionId: transactionId,
      status: 'approved',
      adminEmail: adminEmail,
    );

    _loadTransactions();
    notifyListeners();
    return true;
  }

  /// Admin reject redemption + refund coins
  Future<bool> rejectPendingRedemption({
    required String transactionId,
    required String adminEmail,
    required String reason,
    required HabitProvider habitProvider,
  }) async {
    final tx = _box.get(transactionId);
    if (tx == null || tx.status != 'pending') return false;

    // REFUND: kembalikan koin ke user karena direject
    await habitProvider.addCoins(tx.coinsCost);

    tx.status = 'rejected';
    tx.approvedBy = adminEmail;
    tx.approvedAt = DateTime.now();
    tx.rejectionReason = reason;
    await _box.put(transactionId, tx);

    // Sync ke Firebase agar user tahu statusnya diupdate
    FirebaseService.updateRedemptionStatus(
      transactionId: transactionId,
      status: 'rejected',
      adminEmail: adminEmail,
      rejectionReason: reason,
    );

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
            t.status == 'approved' && // Hanya hitung approved
            t.timestamp.year == today.year &&
            t.timestamp.month == today.month &&
            t.timestamp.day == today.day)
        .fold(0, (total, t) => total + t.coinsCost);
  }

  int get coinsSpentToday => _coinsSpentToday();

  int get totalTransactions => _transactions.length;

  List<TransactionModel> get recentTransactions =>
      _transactions.take(10).toList();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _rewardsSub?.cancel();
    super.dispose();
  }
}
