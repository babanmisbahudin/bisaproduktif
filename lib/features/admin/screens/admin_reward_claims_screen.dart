import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/reward_provider.dart';

class AdminRewardClaimsScreen extends StatefulWidget {
  const AdminRewardClaimsScreen({super.key});

  @override
  State<AdminRewardClaimsScreen> createState() => _AdminRewardClaimsScreenState();
}

class _AdminRewardClaimsScreenState extends State<AdminRewardClaimsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer3<AdminProvider, RewardProvider, HabitProvider>(
        builder: (context, adminProvider, rewardProvider, habitProvider, _) {
          final pending = adminProvider.getPendingRedemptions(rewardProvider);

          if (pending.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (ctx, idx) => _buildClaimCard(
              context,
              pending[idx],
              adminProvider,
              rewardProvider,
              habitProvider,
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Builder(
        builder: (context) => Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('📋', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Text(
              'Klaim Reward',
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(18),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            'Tidak ada klaim menunggu',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua reward sudah diproses',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(
    BuildContext context,
    TransactionModel transaction,
    AdminProvider adminProvider,
    RewardProvider rewardProvider,
    HabitProvider habitProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Reward name + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${transaction.rewardEmoji} ${transaction.rewardTitle}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.coinsCost} COS coins',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⏳ Menunggu',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Information',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  transaction.userName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Claimed: ${_formatDate(transaction.timestamp)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectClaim(
                    context,
                    transaction.id,
                    adminProvider,
                    rewardProvider,
                    habitProvider,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(
                    'Tolak',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveClaim(
                    context,
                    transaction.id,
                    adminProvider,
                    rewardProvider,
                    habitProvider,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    'Setujui',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveClaim(
    BuildContext context,
    String transactionId,
    AdminProvider adminProvider,
    RewardProvider rewardProvider,
    HabitProvider habitProvider,
  ) async {
    try {
      final success = await adminProvider.approvePendingRedemption(
        transactionId: transactionId,
        rewardProvider: rewardProvider,
        habitProvider: habitProvider,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Reward disetujui',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _rejectClaim(
    BuildContext context,
    String transactionId,
    AdminProvider adminProvider,
    RewardProvider rewardProvider,
    HabitProvider habitProvider,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Alasan Penolakan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Masukkan alasan penolakan',
            hintStyle: GoogleFonts.poppins(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'Ditolak oleh admin'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('Tolak', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || !mounted) return;

    try {
      final success = await adminProvider.rejectPendingRedemption(
        transactionId: transactionId,
        reason: reason,
        rewardProvider: rewardProvider,
        habitProvider: habitProvider,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Reward ditolak',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
