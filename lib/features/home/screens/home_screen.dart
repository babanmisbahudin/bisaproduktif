import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/utils/app_transition.dart';
import '../../../core/widgets/dynamic_scene_painter.dart';
import '../../../core/services/weather_service.dart' as weather;
import '../../../data/providers/auth_provider.dart' as auth_prov;
import '../../../data/models/habit_model.dart';
import '../../../data/providers/habit_provider.dart';
import '../../habits/screens/add_habit_screen.dart';
import '../../goals/screens/add_goal_screen.dart';
import '../../goals/widgets/goals_tab.dart';
import '../../rewards/screens/reward_screen.dart';
import '../../report/screens/report_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../data/providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  String _userName = '';
  int _selectedTab = 0;
  weather.WeatherData? _weatherData;

  late AnimationController _handlePulseCtrl;
  late Animation<double> _handlePulseAnim;

  @override
  void initState() {
    super.initState();
    // Pulse animation untuk hint handle draggable
    _handlePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _handlePulseAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _handlePulseCtrl, curve: Curves.easeInOut));

    // Loop pulse setiap 3 detik (hint subtle)
    _handlePulseCtrl.repeat(reverse: true);

    _loadUserData();
    context.read<HabitProvider>().recordAppOpen();
    _fetchWeather();
    _checkShowTour();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('user_name') ?? 'Pengguna');
    if (mounted) {
      context.read<NotificationProvider>().init(userName: _userName);
    }
  }

  Future<void> _fetchWeather() async {
    final w = await weather.WeatherService.fetch();
    if (mounted) setState(() => _weatherData = w);
  }

  Future<void> _checkShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('app_tour_shown') != true) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showTourSheet());
      }
    }
  }

  void _showTourSheet() {
    int _currentStep = 0;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: PageView(
              onPageChanged: (i) => setModalState(() => _currentStep = i),
              children: [
                // Step 1
                _tourStep(
                  emoji: '🪙',
                  title: 'Koin COS Kamu',
                  desc:
                      'Koin COS tampil di sini. Kumpulkan dengan menyelesaikan habit harian!',
                ),
                // Step 2
                _tourStep(
                  emoji: '☝️',
                  title: 'Aktivitas Harian',
                  desc:
                      'Geser sheet ke atas untuk melihat dan mencentang habit-habit harianmu.',
                ),
                // Step 3
                _tourStep(
                  emoji: '🧭',
                  title: 'Menu Navigasi',
                  desc:
                      'Gunakan menu bawah untuk akses Laporan, Rewards, dan Profil kamu.',
                  isLast: true,
                  onFinish: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_tour_shown', true);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tourStep({
    required String emoji,
    required String title,
    required String desc,
    bool isLast = false,
    VoidCallback? onFinish,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: isLast
              ? onFinish
              : () {
                  // PageView handles navigation
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isLast ? 'Mulai!' : 'Lanjut',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _handlePulseCtrl.dispose();
    super.dispose();
  }

  String _formatCoins(int c) {
    if (c == 0) return '0';
    final s = c.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;

    return Consumer<HabitProvider>(
      builder: (_, habitProvider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF020912),
          body: Stack(
            children: [
              // ── 1. Full-screen dynamic scene ─────────────────────────────
              Positioned.fill(
                child: DynamicSceneWidget(weather: _weatherData?.type ?? WeatherType.clear),
              ),

              // ── 2. Header (name + progress) ──────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _buildHeader(habitProvider),
                ),
              ),

              // ── 3. Coin counter in the sky ───────────────────────────────
              Positioned(
                top: topPad + mq.size.height * 0.32,
                left: 0, right: 0,
                child: _buildCoinDisplay(habitProvider.totalCoins),
              ),

              // ── 5. Draggable bottom sheet ────────────────────────────────
              DraggableScrollableSheet(
                initialChildSize: 0.50,
                minChildSize: 0.18,
                maxChildSize: 0.78,
                snap: true,
                snapSizes: const [0.18, 0.50, 0.78],
                builder: (ctx, sc) => _buildSheet(habitProvider, sc),
              ),

              // ── 6. Floating bottom nav (on top) ──────────────────────────
              Positioned(
                bottom: 12, left: 0, right: 0,
                child: Center(child: _buildNav()),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Coin display ─────────────────────────────────────────────────────────
  Widget _buildCoinDisplay(int coins) {
    return Builder(
      builder: (context) {
        final fontSize = context.fontSize(46);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCoins(coins),
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.05,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.padding(4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on,
                    color: Color(0xFFFFD54F), size: 17),
                const SizedBox(width: 5),
                Text(
                  'COS coins collected',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Weather chip ─────────────────────────────────────────────────────────
  Widget _buildWeatherChip() {
    final weatherData = _weatherData;
    final type = weatherData?.type ?? WeatherType.clear;

    final icon = switch (type) {
      WeatherType.rainy   => '🌧️',
      WeatherType.hot     => '☀️',
      WeatherType.cloudy  => '⛅',
      WeatherType.clear   => '🌤️',
    };

    final tempDisplay = weatherData?.tempC != null && weatherData!.tempC > 0
        ? '${weatherData.tempC.toStringAsFixed(0)}°C'
        : '';

    return GestureDetector(
      onTap: () async {
        await _fetchWeather();
      },
      onLongPress: _showWeatherApiDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            if (tempDisplay.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                tempDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(HabitProvider provider) {
    return Consumer<auth_prov.AuthProvider>(
      builder: (_, authProv, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              // Top row: name + weather
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: wave + name
                  GestureDetector(
                    onTap: () => _showProfileSheet(authProv),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: authProv.isLoggedIn
                                ? Border.all(
                                    color: Colors.greenAccent.withValues(alpha: 0.7),
                                    width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: authProv.isLoggedIn
                                ? const Icon(Icons.check_circle,
                                    color: Colors.greenAccent, size: 20)
                                : const Text('👋',
                                    style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _userName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: weather
                  _buildWeatherChip(),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom row: progress pill
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      '${provider.completedToday} / ${provider.totalHabits}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────
  Widget _buildSheet(HabitProvider provider, ScrollController sc) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 28,
              offset: Offset(0, -4))
        ],
      ),
      child: Column(
        children: [
          // Drag handle area — large touch target for drag
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Tap handle to expand/collapse sheet
              sc.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _handlePulseAnim,
                    builder: (ctx, child) {
                      // Subtle scale + opacity pulse
                      final scale = 1.0 + (_handlePulseAnim.value * 0.2);
                      final opacity = 0.65 + (_handlePulseAnim.value * 0.2);
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 48, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[350],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Today" + add button
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap:
                      _selectedTab == 0 ? _openAddHabit : _openAddGoal,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // Tab switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: _buildTabs(),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? (provider.isLoaded
                    ? ListView(
                        controller: sc,
                        padding:
                            const EdgeInsets.fromLTRB(22, 12, 22, 90),
                        children: _buildHabitCards(provider),
                      )
                    : const Center(
                        child: CircularProgressIndicator()))
                : GoalsTab(
                    onCoinEarned: () => setState(() {}),
                    scrollController: sc,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: [
        _tabPill('Daily habits', 0),
        const SizedBox(width: 8),
        _tabPill('Goals', 1),
      ],
    );
  }

  Widget _tabPill(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ── Habit cards ───────────────────────────────────────────────────────────
  List<Widget> _buildHabitCards(HabitProvider provider) {
    if (provider.habits.isEmpty) return [_emptyState()];
    return provider.habits
        .map((h) => _habitCard(h, provider))
        .toList();
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text('Belum ada habit',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + untuk tambah habit pertamamu',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _habitCard(HabitModel habit, HabitProvider provider) {
    final done = habit.isCompletedOnDate;
    return Dismissible(
      key: Key('habit_${habit.id}'),
      background: _swipeBg(
        color: done ? Colors.grey.shade400 : Colors.green.shade500,
        icon: done ? Icons.check_circle_rounded : Icons.check_rounded,
        alignment: Alignment.centerLeft,
        label: done ? 'Sudah Selesai' : 'Selesaikan',
      ),
      secondaryBackground: _swipeBg(
        color: AppColors.danger,
        icon: Icons.delete_rounded,
        alignment: Alignment.centerRight,
        label: 'Hapus',
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          if (done) return false;
          final ok = await provider.completeHabit(habit.id);
          if (mounted) ok ? _showCoin(habit.coins) : _showFraud();
          return false;
        }
        return await _confirmDelete(context,
            title: 'Hapus Habit?',
            content: '"${habit.title}" akan dihapus permanen.') ??
            false;
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          provider.deleteHabit(habit.id);
          _snack('Habit dihapus');
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (done) return;
          final ok = await provider.completeHabit(habit.id);
          if (!mounted) return;
          ok ? _showCoin(habit.coins) : _showFraud();
        },
        onLongPress: () => _openEditHabit(habit),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color:
                    done ? habit.color.withValues(alpha: 0.45) : habit.color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: habit.color
                        .withValues(alpha: done ? 0.12 : 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: done ? Colors.white : Colors.transparent,
                        border: Border.all(
                            color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: done
                          ? Icon(Icons.check,
                              color: habit.color, size: 17)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Title + streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white
                              .withValues(alpha: done ? 0.6 : 1.0),
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (habit.streak > 0)
                        Text(
                          '🔥 ${habit.streak} hari berturut',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color:
                                Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Coin badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text('${habit.coins}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('Coins',
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              color:
                                  Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ),
            // Goal badge jika habit dari goal
            if (habit.goalId != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🎯', style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context,
      {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 17))),
        ]),
        content: Text(content,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Batal',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Hapus',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(
                icon: Icons.home_rounded,
                isActive: true,
                badge: 0,
                onTap: () {},
              ),
              const SizedBox(width: 2),
              _navItem(
                icon: Icons.bar_chart_rounded,
                isActive: false,
                badge: 0,
                onTap: () => Navigator.push(
                    context,
                    AppTransition.slideRight(
                        child: const ReportScreen())),
              ),
              const SizedBox(width: 2),
              _navItem(
                icon: Icons.shopping_bag_outlined,
                isActive: false,
                badge: 0,
                onTap: () => Navigator.push(context,
                    AppTransition.slideRight(
                        child: const RewardScreen())),
              ),
              const SizedBox(width: 2),
              _navItem(
                icon: Icons.person_outlined,
                isActive: false,
                badge: 0,
                onTap: () => Navigator.push(context,
                    AppTransition.slideRight(
                        child: const ProfileScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required bool isActive,
    required int badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon,
                color: isActive
                    ? Colors.white
                    : AppColors.navInactive,
                size: 24),
          ),
          if (badge > 0)
            Positioned(
              top: 2, right: 6,
              child: Container(
                width: 17, height: 17,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text('$badge',
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Profile sheet ─────────────────────────────────────────────────────────
  void _showProfileSheet(auth_prov.AuthProvider authProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            if (authProv.isLoggedIn) ...[
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(authProv.displayName,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(authProv.email,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authProv.signOut();
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('Keluar',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              const Text('🔑', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text('Login dengan Google',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Diperlukan untuk tukar koin & sync ke cloud.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              if (authProv.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok =
                          await authProv.signInWithGoogle();
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                        _snack('Login berhasil! 🎉',
                            color: AppColors.primary);
                      } else if (authProv.error != null) {
                        _snack(authProv.error!,
                            color: AppColors.danger);
                      }
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: Text('Login dengan Google',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Weather API Setup Dialog ──────────────────────────────────────────────
  void _showWeatherApiDialog() {
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.cloud, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
              child: Text('OpenWeatherMap API',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 17))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan API key OpenWeatherMap untuk cuaca lebih akurat dengan suhu real-time.',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Paste API key...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('Cara Dapat API Key',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. Buka openweathermap.org/api',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '2. Klik "Sign Up" → verifikasi email',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '3. Login → My API Keys',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '4. Copy key yang pertama',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Paham',
                                style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '? Cara dapat API key gratis',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary))),
          ElevatedButton(
              onPressed: () async {
                final key = keyCtrl.text.trim();
                if (key.isEmpty) {
                  _snack('API key tidak boleh kosong', color: AppColors.danger);
                  return;
                }
                await weather.WeatherService.setApiKey(key);
                if (mounted) {
                  Navigator.pop(context);
                  _snack('API key tersimpan! Refresh cuaca...', color: AppColors.primary);
                  await _fetchWeather();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Simpan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ── Open screens ──────────────────────────────────────────────────────────
  void _openAddHabit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sc) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: const AddHabitScreen(),
        ),
      ),
    );
  }

  void _openEditHabit(HabitModel habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sc) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: AddHabitScreen(editHabit: habit),
        ),
      ),
    );
  }

  void _openAddGoal() {
    Navigator.push(
        context,
        AppTransition.slideRight(child: const AddGoalScreen()));
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────
  void _showCoin(int coins) {
    _snack('+$coins COS coins! 🎉', color: AppColors.primary);
  }

  void _showFraud() {
    _snack('Aktivitas tidak biasa terdeteksi ⚠️',
        color: AppColors.warning);
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }
}
