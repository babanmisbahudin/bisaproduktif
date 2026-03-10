import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/widgets/bottom_navbar_widget.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/goal_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ── Helper Methods for Theme-Aware Colors ──────────────────────────────

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F0F0F)
        : AppColors.background;
  }

  Color _getContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : Colors.white;
  }

  Color _getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.textPrimary;
  }

  Color _getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : AppColors.textSecondary;
  }

  Color _getStatBoxColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF333333)
        : const Color(0xFFF0F0F0);
  }

  Color _getChartDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF444444)
        : const Color(0xFFE0E0E0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, GoalProvider>(
      builder: (_, habitProvider, goalProvider, _) {
        return Scaffold(
          backgroundColor: _getBackgroundColor(context),
          appBar: _buildAppBar(context),
          body: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
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
          bottomNavigationBar: SafeArea(
            top: false,
            child: BottomNavBar(activeIndex: 1),
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
        color: _getContainerColor(context),
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
              color: _getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: WeeklyBarChartPainter(
                data: weekData,
                maxValue: maxCount,
                dividerColor: _getChartDividerColor(context),
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
        color: _getContainerColor(context),
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
              color: _getTextPrimaryColor(context),
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
          color: _getStatBoxColor(context),
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
                color: _getTextPrimaryColor(context),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: _getTextSecondaryColor(context),
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
        color: _getContainerColor(context),
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
                  color: _getTextPrimaryColor(context),
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
                color: _getTextSecondaryColor(context),
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
                                color: _getTextPrimaryColor(context),
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
                          backgroundColor: _getStatBoxColor(context),
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
        color: _getContainerColor(context),
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
              color: _getTextPrimaryColor(context),
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
  final Color dividerColor;

  WeeklyBarChartPainter({
    required this.data,
    required this.maxValue,
    this.dividerColor = const Color(0xFF444444),
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
      Paint()..color = dividerColor,
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
      Paint()..color = dividerColor,
    );
  }

  @override
  bool shouldRepaint(WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.maxValue != maxValue ||
           oldDelegate.dividerColor != dividerColor;
  }
}
