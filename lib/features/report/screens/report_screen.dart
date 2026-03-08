import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/goal_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, GoalProvider>(
      builder: (_, habitProvider, goalProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── Section 1: 7-Day Chart ─────────────────────────────────────────
              _buildChartSection(context, habitProvider),
              const SizedBox(height: 20),

              // ── Section 2: Weekly Summary ──────────────────────────────────────
              _buildSummarySection(context, habitProvider),
              const SizedBox(height: 20),

              // ── Section 3: Goals Progress ──────────────────────────────────────
              _buildGoalsSection(context, goalProvider),
              const SizedBox(height: 20),

              // ── Section 4: Coin Activity ───────────────────────────────────────
              _buildCoinSection(context, habitProvider),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Builder(
        builder: (ctx) => Text(
          'Laporan Aktivitas',
          style: GoogleFonts.poppins(
            fontSize: ctx.fontSize(18),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, HabitProvider provider) {
    final weekData = _getWeekData(provider);
    final maxCount = weekData.isEmpty ? 1.0 : weekData.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
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
          Text(
            '📊 7 Hari Terakhir',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: WeeklyBarChartPainter(
                data: weekData,
                maxValue: maxCount,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, HabitProvider provider) {
    final weekData = _getWeekData(provider);
    final total = weekData.fold(0, (a, b) => a + b);
    final avg = weekData.isEmpty ? 0 : (total / 7).round();
    final maxStreak = provider.habits.fold(0, (max, h) => h.streak > max ? h.streak : max);

    return Container(
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
          Text(
            '📈 Ringkasan Mingguan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('Total', '$total', '🎯'),
              const SizedBox(width: 12),
              _buildStatBox('Rata-rata/Hari', '$avg', '📅'),
              const SizedBox(width: 12),
              _buildStatBox('Streak Terbaik', '$maxStreak', '🔥'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, GoalProvider provider) {
    final activeGoals = provider.activeGoals;
    final completedCount = provider.completedCount;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🎯 Progress Goals',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selesai: $completedCount',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeGoals.isEmpty)
            Text(
              'Belum ada goal aktif',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: activeGoals.take(3).map((goal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${goal.currentProgress}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: goal.progressPercent,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(goal.color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinSection(BuildContext context, HabitProvider provider) {
    final weekData = _getWeekData(provider);
    final totalCoinsThisWeek = weekData.fold(0, (sum, count) {
      // Approximate: assume average 25 coins per habit
      return sum + (count * 25);
    });

    return Container(
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
          Text(
            '💰 Aktivitas Koin',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('Minggu Ini', '$totalCoinsThisWeek', '📈'),
              const SizedBox(width: 12),
              _buildStatBox('Total Saat Ini', '${provider.totalCoins}', '🪙'),
            ],
          ),
        ],
      ),
    );
  }

  /// Get 7 days of completion counts
  List<int> _getWeekData(HabitProvider provider) {
    final now = DateTime.now();
    final result = <int>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      int count = 0;
      for (final habit in provider.habits) {
        if (habit.lastCompletedDate == dateKey) {
          count++;
        }
      }
      result.add(count);
    }

    return result;
  }
}

// ── Custom Painter for Weekly Bar Chart ────────────────────────────────────

class WeeklyBarChartPainter extends CustomPainter {
  final List<int> data;
  final double maxValue;

  WeeklyBarChartPainter({
    required this.data,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final paint = Paint()..color = AppColors.primary;
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const padding = 40.0;
    const barSpacing = 8.0;
    final availableWidth = size.width - padding * 2;
    final barWidth = (availableWidth - barSpacing * (data.length - 1)) / data.length;
    final chartHeight = size.height - padding - 20;

    // Draw Y axis
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = Colors.grey[300]!,
    );

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final barHeight = maxValue > 0 ? (data[i] / maxValue) * chartHeight : 0.0;
      final x = padding + (i * (barWidth + barSpacing));
      final y = size.height - padding - barHeight;

      // Bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Label
      textPaint.text = TextSpan(
        text: dayLabels[i],
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      );
      textPaint.layout();
      textPaint.paint(
        canvas,
        Offset(x + (barWidth - textPaint.width) / 2, size.height - padding + 5),
      );

      // Value on top of bar
      if (data[i] > 0) {
        textPaint.text = TextSpan(
          text: '${data[i]}',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPaint.layout();
        textPaint.paint(
          canvas,
          Offset(x + (barWidth - textPaint.width) / 2, y - 15),
        );
      }
    }

    // Draw X axis
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = Colors.grey[300]!,
    );
  }

  @override
  bool shouldRepaint(WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}
