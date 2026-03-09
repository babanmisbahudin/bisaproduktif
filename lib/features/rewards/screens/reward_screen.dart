import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/reward_provider.dart';
import '../../../data/providers/user_profile_provider.dart';
import '../widgets/reward_card.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, RewardProvider>(
      builder: (context, habitProvider, rewardProvider, _) {
        final coins = habitProvider.totalCoins;
        final trustScore = habitProvider.trustScore;
        final rewards = rewardProvider.filteredCatalog('semua');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(coins),
          body: Column(
            children: [
              // Trust score warning
              TrustScoreBanner(
                trustScore: trustScore,
                coinsSpentToday: rewardProvider.coinsSpentToday,
              ),
              // Category filter
              _buildCategoryFilter(),
              // Reward grid (responsive columns)
              Expanded(
                child: rewards.isEmpty
                    ? _buildEmptyState()
                    : Builder(
                        builder: (ctx) {
                          final gridCols = ctx.gridColumns; // mobile: 1, tablet: 2, desktop: 3
                          final spacing = ctx.padding(14);
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 120),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridCols,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                            ),
                            itemCount: rewards.length,
                            itemBuilder: (ctx, i) => RewardCard(
                              reward: rewards[i],
                              userCoins: coins,
                              onTap: () => _showRedeemDialog(
                                  context, rewards[i], habitProvider, rewardProvider),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // Riwayat transaksi button
          floatingActionButton: rewardProvider.totalTransactions > 0
              ? FloatingActionButton.extended(
                  onPressed: () => _showHistory(context, rewardProvider),
                  backgroundColor: AppColors.primary,
                  elevation: 8,
                  icon: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                  label: Text(
                    'Riwayat (${rewardProvider.totalTransactions})',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                )
              : null,
        );
      },
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(int coins) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text('Toko Reward',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 7),
                  Text('$coins',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Category Filter ───────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text('🎁 Semua Reward',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Popular',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Belum ada reward',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Reward akan tersedia segera',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Redeem Dialog ─────────────────────────────────────────────────────────

  void _showRedeemDialog(
    BuildContext context,
    RewardItem reward,
    HabitProvider habitProvider,
    RewardProvider rewardProvider,
  ) {
    _checkWhatsAppAndShowDialog(
        context, reward, habitProvider, rewardProvider);
  }

  void _checkWhatsAppAndShowDialog(
    BuildContext context,
    RewardItem reward,
    HabitProvider habitProvider,
    RewardProvider rewardProvider,
  ) async {
    // Cek nomor WhatsApp di profile sebelum tukar koin
    final prefs = await SharedPreferences.getInstance();
    final waNumber = prefs.getString('user_whatsapp') ?? '';

    if (!mounted) return;

    if (waNumber.isEmpty) {
      if (context.mounted) {
        _showWhatsAppInputSheet(context, reward, habitProvider, rewardProvider);
      }
      return;
    }

    if (context.mounted) {
      _showRedeemDialogContent(context, reward, habitProvider, rewardProvider);
    }
  }

  void _showRedeemDialogContent(
    BuildContext context,
    RewardItem reward,
    HabitProvider habitProvider,
    RewardProvider rewardProvider,
  ) {
    final canAfford = habitProvider.totalCoins >= reward.price;
    final isFrozen = habitProvider.trustScore < 40;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            // Emoji
            Text(reward.emoji,
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            // Judul
            Text(reward.title,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            // Deskripsi
            Text(
              reward.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Harga
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: reward.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: reward.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
                  const SizedBox(width: 8),
                  Text('${reward.price} COS Coins',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: reward.color)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Saldo setelah
            if (canAfford && !isFrozen)
              Text(
                'Sisa koin setelah tukar: ${habitProvider.totalCoins - reward.price}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            if (!canAfford)
              Text(
                'Koin tidak cukup (kurang ${reward.price - habitProvider.totalCoins} koin)',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.danger),
              ),
            if (isFrozen)
              Text(
                '🔒 Koin dibekukan karena trust score terlalu rendah',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.danger),
              ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Batal',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (canAfford && !isFrozen)
                        ? () async {
                            Navigator.pop(context);
                            await _processRedeem(
                                reward, habitProvider, rewardProvider);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: reward.color,
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    child: Text('Tukar Sekarang',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── WhatsApp Input Sheet ──────────────────────────────────────────────────

  void _showWhatsAppInputSheet(
    BuildContext context,
    RewardItem reward,
    HabitProvider habitProvider,
    RewardProvider rewardProvider,
  ) {
    final waCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text('📱', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text('Verifikasi WhatsApp',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Masukkan nomor WhatsApp untuk menerima notifikasi approval reward dari admin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Input field
            TextField(
              controller: waCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '08xx / 62xx / +62xx',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Batal',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final wa = waCtrl.text.trim();
                      if (wa.isEmpty) {
                        _showSnack('Nomor WhatsApp tidak boleh kosong', AppColors.danger);
                        return;
                      }

                      // Validasi format nomor WA
                      if (!_isValidWhatsAppNumber(wa)) {
                        _showSnack(
                          'Format nomor tidak valid. Gunakan 08xx, 62xx, atau +62xx',
                          AppColors.danger,
                        );
                        return;
                      }

                      // Simpan ke SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_whatsapp', wa);

                      if (!sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);

                      if (!context.mounted) return;
                      // Langsung ke dialog redeem
                      _showRedeemDialogContent(context, reward, habitProvider, rewardProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Simpan & Lanjut',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processRedeem(
    RewardItem reward,
    HabitProvider habitProvider,
    RewardProvider rewardProvider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<UserProfileProvider>();

    // Check if profile is complete
    if (!profileProvider.isProfileComplete) {
      _showSnack('❌ Lengkapi profil terlebih dahulu (Nama, Alamat, WhatsApp)', AppColors.danger);
      return;
    }

    final userId = authProvider.user?.uid ?? 'anonymous';
    final userName = profileProvider.name.isNotEmpty ? profileProvider.name : 'User';

    final result = await rewardProvider.redeemReward(
      reward: reward,
      habitProvider: habitProvider,
      userId: userId,
      userName: userName,
    );

    if (!mounted) return;

    if (result == RedeemResult.success) {
      // Log ke Firestore untuk anti-fraud
      FirebaseService.logActivity(
        type: 'coin_redeem',
        data: {
          'reward': reward.title,
          'price': reward.price,
          'coinsAfter': habitProvider.totalCoins,
        },
      );
      FirebaseService.syncCoins(habitProvider.totalCoins);
      // Kirim notif ke admin via WhatsApp otomatis
      await _sendWhatsAppMessage(reward, profileProvider);
    }

    if (!mounted) return;
    switch (result) {
      case RedeemResult.success:
        _showSuccessDialog(context, reward, profileProvider);
        break;
      case RedeemResult.insufficientCoins:
        _showSnack('Koin tidak cukup 😅', AppColors.warning);
        break;
      case RedeemResult.trustFrozen:
        _showSnack('🔒 Koin dibekukan. Tingkatkan trust score dulu!', AppColors.danger);
        break;
      case RedeemResult.dailyLimitExceeded:
        _showSnack('Limit harian 500 koin sudah tercapai ⚠️', AppColors.warning);
        break;
      case RedeemResult.trustLimited:
        _showSnack('Trust score rendah. Limit 500 koin/hari ⚠️', AppColors.warning);
        break;
    }
  }

  void _showSuccessDialog(BuildContext context, RewardItem reward, UserProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('✅', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Permintaan Diterima',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              '${reward.emoji} ${reward.title}\n\nPermintaanmu sudah dikirim ke admin. Notifikasi WhatsApp sudah dikirimkan. Tunggu konfirmasi dari admin segera.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Kembali',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWhatsAppMessage(RewardItem reward, UserProfileProvider profileProvider) async {
    final adminPhoneNumber = AppStrings.adminWhatsappNumber;

    final message = '''
Halo Admin! 👋

Saya ingin menukar poin di aplikasi BisaProduktif:

📋 Data Penukar:
Nama: ${profileProvider.name}
Alamat: ${profileProvider.address}
WhatsApp: ${profileProvider.whatsapp}

🎁 Reward:
${reward.emoji} ${reward.title}
Harga: ${reward.price} koin

Mohon diproses. Terima kasih! 🙏
    ''';

    final whatsappUrl = 'https://wa.me/$adminPhoneNumber?text=${Uri.encodeFull(message)}';

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        _showSnack('WhatsApp tidak tersedia di device ini', AppColors.warning);
      }
    } catch (e) {
      _showSnack('Gagal membuka WhatsApp: $e', AppColors.danger);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Transaction History ───────────────────────────────────────────────────

  void _showHistory(BuildContext context, RewardProvider rewardProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Riwayat Penukaran',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${rewardProvider.totalTransactions} item',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: rewardProvider.transactions.length,
                itemBuilder: (_, i) {
                  final tx = rewardProvider.transactions[i];
                  return _buildTransactionTile(tx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(dynamic tx) {
    final date = tx.timestamp as DateTime;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(tx.rewardEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.rewardTitle,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(dateStr,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.remove, color: AppColors.danger, size: 13),
                Text('${tx.coinsCost}',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WhatsApp Number Validator ──────────────────────────────────────────────

  bool _isValidWhatsAppNumber(String number) {
    // Remove spaces dan hyphens
    final cleaned = number.replaceAll(RegExp(r'[\s\-]'), '');

    // Check format: 08xx (min 10), 62xx (min 11), +62xx (min 12)
    final regex = RegExp(r'^(08\d{8,})|(62\d{9,})|(\+62\d{9,})$');

    return regex.hasMatch(cleaned);
  }
}
