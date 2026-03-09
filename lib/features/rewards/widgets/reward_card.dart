import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/providers/reward_provider.dart';
import '../../../core/constants/app_colors.dart';

class RewardCard extends StatefulWidget {
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
  State<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<RewardCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = widget.userCoins >= widget.reward.price;

    return GestureDetector(
      onTap: () {
        _hoverCtrl.forward().then((_) => _hoverCtrl.reverse());
        widget.onTap();
      },
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) => _hoverCtrl.reverse(),
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _hoverCtrl,
        builder: (ctx, _) {
          final scale = 1.0 - (_hoverCtrl.value * 0.04);
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.reward.color.withValues(
                        alpha: canAfford ? 0.4 : 0.15),
                    blurRadius: 24,
                    offset: Offset(0, 8 + (_hoverCtrl.value * 4)),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: canAfford
                        ? [
                            widget.reward.color,
                            widget.reward.color.withValues(alpha: 0.85),
                          ]
                        : [
                            widget.reward.color.withValues(alpha: 0.5),
                            widget.reward.color.withValues(alpha: 0.35),
                          ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji large
                      Text(
                        widget.reward.emoji,
                        style: TextStyle(
                          fontSize: canAfford ? 32 : 28,
                          color: canAfford
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Judul
                      Text(
                        widget.reward.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(
                              alpha: canAfford ? 1.0 : 0.65),
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Deskripsi
                      Text(
                        widget.reward.description,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withValues(
                              alpha: canAfford ? 0.9 : 0.5),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Bottom row: harga + badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Harga
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: canAfford ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: Colors.amber, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  '${widget.reward.price}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              canAfford ? '✓ Tukar' : 'Kurang',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: canAfford
                                    ? widget.reward.color
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
