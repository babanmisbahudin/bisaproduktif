import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_transition.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../screens/add_goal_screen.dart';
import 'goal_card.dart';

class GoalsTab extends StatelessWidget {
  final VoidCallback? onCoinEarned;
  final ScrollController? scrollController;

  const GoalsTab({super.key, this.onCoinEarned, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (context, provider, _) {
        final goals = provider.goals;

        if (goals.isEmpty) {
          return ListView(
            controller: scrollController,
            children: [_buildEmptyState(context)],
          );
        }

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            // Goal list
            ...goals.map((goal) => _buildGoalCard(context, provider, goal)),
          ],
        );
      },
    );
  }


  Widget _buildGoalCard(
      BuildContext context, GoalProvider provider, GoalModel goal) {
    return Dismissible(
      key: Key('goal_${goal.id}'),
      // Hanya swipe kiri = hapus
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              'Hapus',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hapus Goal?',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            '"${goal.title}" akan dihapus secara permanen.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Batal',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Hapus',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        provider.deleteGoal(goal.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Goal dihapus', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      },
      child: GoalCard(
        goal: goal,
        onTap: () => _showGoalDetails(context, provider, goal),
        onLongPress: goal.status == GoalStatus.active
            ? () => _openEditGoal(context, goal)
            : null,
      ),
    );
  }

  void _openEditGoal(BuildContext context, GoalModel goal) {
    Navigator.push(
      context,
      AppTransition.slideRight(child: AddGoalScreen(editGoal: goal)),
    );
  }

  void _showGoalDetails(BuildContext context, GoalProvider provider, GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: goal.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                goal.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.targetDescription,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${goal.coins} Coins',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${goal.currentProgress}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: goal.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressPercent,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(goal.color),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    goal.status == GoalStatus.active
                        ? Icons.flag_rounded
                        : Icons.check_circle_rounded,
                    color: goal.color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    goal.statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: goal.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          if (goal.status == GoalStatus.active)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  AppTransition.slideRight(child: AddGoalScreen(editGoal: goal)),
                );
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(
                'Edit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          if (goal.status == GoalStatus.active && goal.currentProgress >= goal.targetProgress)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final coins = await provider.completeGoal(goal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '+$coins koin! Goal selesai! 🎉',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  onCoinEarned?.call();
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                'Selesaikan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: goal.color,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada goal',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambah goal pertamamu dan raih reward koin saat berhasil!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                AppTransition.slideRight(child: const AddGoalScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Tambah Goal',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
