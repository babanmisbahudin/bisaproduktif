import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/providers/reward_provider.dart';
import '../../../core/constants/app_colors.dart';

class RewardCard extends StatelessWidget {
  final RewardItem reward;
  final int userCoins;
  final VoidCallback onTap;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userCoins,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = userCoins >= reward.price;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: canAfford ? reward.color : reward.color.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: reward.color.withValues(alpha: canAfford ? 0.35 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji + kategori badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(reward.emoji,
                      style: TextStyle(
                          fontSize: canAfford ? 32 : 28,
                          color: canAfford ? null : Colors.white.withValues(alpha: 0.5))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _categoryLabel(reward.category),
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Judul
              Text(
                reward.title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: canAfford ? 1.0 : 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Deskripsi
              Text(
                reward.description,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: canAfford ? 0.85 : 0.45),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Harga + tombol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.price}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      canAfford ? 'Tukar' : 'Kurang',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: canAfford ? reward.color : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'voucher':
        return '🎟️ Voucher';
      case 'hiburan':
        return '🎮 Hiburan';
      case 'makanan':
        return '🍴 Makanan';
      case 'premium':
        return '⭐ Premium';
      default:
        return category;
    }
  }
}

// ── Trust Score Banner ─────────────────────────────────────────────────────

class TrustScoreBanner extends StatelessWidget {
  final int trustScore;
  final int coinsSpentToday;

  const TrustScoreBanner({
    super.key,
    required this.trustScore,
    required this.coinsSpentToday,
  });

  @override
  Widget build(BuildContext context) {
    if (trustScore >= 60) return const SizedBox.shrink();

    final isFrozen = trustScore < 40;
    final bgColor = isFrozen ? AppColors.danger : AppColors.warning;
    final icon = isFrozen ? '🔒' : '⚠️';
    final message = isFrozen
        ? 'Koin dibekukan (Trust Score terlalu rendah). Selesaikan habit dengan jujur.'
        : 'Limit tukar koin: 500/hari (Trust Score rendah). Sudah dipakai: $coinsSpentToday.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: bgColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
