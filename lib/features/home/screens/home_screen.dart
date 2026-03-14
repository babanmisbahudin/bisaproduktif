// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../../data/providers/goal_provider.dart';
import '../../habits/screens/add_habit_screen.dart';
import '../../goals/screens/add_goal_screen.dart';
import '../../goals/widgets/goals_tab.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/memo_provider.dart';
import '../../../data/providers/focus_timer_provider.dart';
import '../../../core/widgets/bottom_navbar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = '';
  int _selectedTab = 0;
  weather.WeatherData? _weatherData;
  bool _isRefreshing = false;

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
    _handlePulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _handlePulseCtrl, curve: Curves.easeInOut),
    );

    // Loop pulse setiap 3 detik (hint subtle)
    _handlePulseCtrl.repeat(reverse: true);

    _loadUserData();
    context.read<HabitProvider>().recordAppOpen();
    _fetchWeather();
    _checkShowTour();

    // Register logout callback untuk navigate ke splash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<auth_prov.AuthProvider>();
      authProvider.onLogoutNavigate = () async {
        if (mounted) {
          // Reload user data saat logout untuk update nama
          await _loadUserData();
          // Clear user name dari SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user_name');
          // Navigate ke splash screen menggunakan go_router
          if (mounted) {
            GoRouter.of(context).goNamed('splash');
          }
        }
      };

      // Listen untuk perubahan auth state (login/logout)
      authProvider.addListener(() {
        if (mounted) {
          _loadUserData();
        }
      });
    });
  }

  Future<void> _loadUserData() async {
    // Capture context-dependent values before async gap
    final authProvider = context.read<auth_prov.AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final prefs = await SharedPreferences.getInstance();

    // Jika sudah login via Google, gunakan nama dari Google account
    // Jika belum login, gunakan nama pengguna dari SharedPreferences
    if (authProvider.isLoggedIn && authProvider.displayName.isNotEmpty) {
      setState(() => _userName = authProvider.displayName);
    } else {
      setState(() => _userName = prefs.getString('user_name') ?? 'Pengguna');
    }

    if (mounted) {
      notificationProvider.init(userName: _userName);
    }
  }

  Future<void> _fetchWeather() async {
    final w = await weather.WeatherService.fetch();
    if (mounted) setState(() => _weatherData = w);
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _fetchWeather();
    if (mounted) setState(() => _isRefreshing = false);
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
    final pageCtrl = PageController();
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
              controller: pageCtrl,
              onPageChanged: (i) => setModalState(() {}),
              children: [
                // Step 1: Welcome
                _tourStep(
                  emoji: '👋',
                  title: 'Selamat Datang!',
                  desc:
                      'BisaProduktif adalah aplikasi untuk membantu kamu mencapai goals dengan cara yang fun dan terstruktur. Mari pelajari fitur-fiturnya!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 2: Koin COS
                _tourStep(
                  emoji: '🪙',
                  title: 'Koin COS',
                  desc:
                      'Koin COS adalah mata uang digital di app ini. Kumpulkan koin dengan menyelesaikan habit harian dan goals. Gunakan koin untuk tukar reward di shop!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 3: Habit Harian
                _tourStep(
                  emoji: '✅',
                  title: 'Habit Harian',
                  desc:
                      'Geser sheet ke atas untuk lihat daftar habit harianmu. Centang setiap habit yang selesai untuk dapat koin + streak counter naik. Semakin konsisten, semakin banyak koin!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 4: Goals
                _tourStep(
                  emoji: '🎯',
                  title: 'Goals (Target Besar)',
                  desc:
                      'Di tab Goals, buat target jangka panjang (misal: "Baca 5 buku bulan ini"). Habits akan otomatis dibuat berdasarkan goal-mu. Ketika goal selesai, dapat reward koin besar!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 5: Laporan
                _tourStep(
                  emoji: '📊',
                  title: 'Laporan Aktivitas',
                  desc:
                      'Tab Laporan menampilkan chart 7 hari, ringkasan mingguan, progress goals, dan aktivitas koin. Gunakan untuk track progress dan motivasi diri!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 6: Rewards
                _tourStep(
                  emoji: '🛍️',
                  title: 'Rewards & Shop',
                  desc:
                      'Tukar koin COS dengan rewards menarik: voucher makanan, tiket nonton, premium features, dan lainnya. Semakin banyak goal selesai, semakin banyak reward!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 7: Trust Score
                _tourStep(
                  emoji: '⭐',
                  title: 'Trust Score',
                  desc:
                      'Trust score dimulai dari 70. Jika kamu konsisten & jujur, score naik. Tapi jika ada aktivitas mencurigakan (misal: nge-cheat), score bisa turun. Score rendah bisa freeze akun!',
                  onNext: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                // Step 8: Profile & Settings
                _tourStep(
                  emoji: '👤',
                  title: 'Profil & Pengaturan',
                  desc:
                      'Di tab Profil, atur notifikasi reminder, pilih light/dark mode, login Google untuk sync data, dan lihat status admin access. Semua data disimpan aman!',
                  isLast: true,
                  onNext: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_tour_shown', true);
                    if (mounted) {
                      Navigator.pop(context);
                      pageCtrl.dispose();
                    }
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
    VoidCallback? onNext,
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
          onPressed: onNext,
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppColors.background,
          body: Column(
            children: [
              // ── Main content area (Stack with background + sheet) ──────────
              Expanded(
                child: Stack(
                  children: [
                    // ── 1. Full-screen dynamic scene ─────────────────────────
                    Positioned.fill(
                      child: DynamicSceneWidget(
                        weather: _weatherData?.type ?? WeatherType.clear,
                      ),
                    ),

                    // ── 2. Header (name + progress) ──────────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: _buildHeader(habitProvider),
                      ),
                    ),

                    // ── 3. Coin counter in the sky ──────────────────────────
                    Positioned(
                      top: topPad + mq.size.height * 0.32,
                      left: 0,
                      right: 0,
                      child: _buildCoinDisplay(habitProvider.totalCoins),
                    ),

                    // ── 4. Draggable bottom sheet ────────────────────────────
                    DraggableScrollableSheet(
                      initialChildSize: 0.50,
                      minChildSize: 0.28,
                      maxChildSize: 0.78,
                      snap: true,
                      snapSizes: const [0.28, 0.50, 0.78],
                      builder: (ctx, sc) {
                        return _buildSheet(habitProvider, sc);
                      },
                    ),
                  ],
                ),
              ),

              // ── Fixed bottom navbar ──────────────────────────────────────
              SafeArea(
                top: false,
                child: BottomNavBar(activeIndex: 0),
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
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFD54F),
                  size: 17,
                ),
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
      WeatherType.rainy => '🌧️',
      WeatherType.hot => '☀️',
      WeatherType.cloudy => '⛅',
      WeatherType.clear => '🌤️',
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: authProv.isLoggedIn
                                ? Border.all(
                                    color: Colors.greenAccent.withValues(
                                      alpha: 0.7,
                                    ),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: authProv.isLoggedIn
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                    size: 20,
                                  )
                                : const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 18),
                                  ),
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
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 28,
            offset: Offset(0, -4),
          ),
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
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 5,
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
                Row(
                  children: [
                    // Tombol refresh
                    GestureDetector(
                      onTap: _isRefreshing ? null : _handleRefresh,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: _isRefreshing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol add
                    GestureDetector(
                      onTap: _selectedTab == 0 ? _openAddHabit : _openAddGoal,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.38),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
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
            child: _buildTabContent(provider, sc),
          ),
        ],
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabPill('Daily habits', 0),
          const SizedBox(width: 8),
          _tabPill('Goals', 1),
          const SizedBox(width: 8),
          _tabPill('Memo', 2),
          const SizedBox(width: 8),
          _tabPill('Focus', 3),
        ],
      ),
    );
  }

  Widget _tabPill(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          // Underline untuk active tab
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: isSelected ? 3 : 0,
            width: label.length * 8.0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────────────────────────
  Widget _buildTabContent(HabitProvider habitProvider, ScrollController sc) {
    return switch (_selectedTab) {
      0 => // Daily habits
        (habitProvider.isLoaded
            ? ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 90),
                physics: const AlwaysScrollableScrollPhysics(),
                children: _buildHabitCards(habitProvider),
              )
            : const Center(child: CircularProgressIndicator())),
      1 => // Goals
        GoalsTab(
          onCoinEarned: () => setState(() {}),
          scrollController: sc,
        ),
      2 => // Memo
        Consumer<MemoProvider>(
            builder: (_, memoProvider, _) {
              final memos = memoProvider.memos;
              final memoInputCtrl = TextEditingController();

              final memoItems = [
              // Input field untuk memo baru (item 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tulis Memo',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: memoInputCtrl,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ketik memo...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final text = memoInputCtrl.text.trim();
                            if (text.isEmpty) {
                              _snack('Tulis memo terlebih dahulu');
                              return;
                            }
                            await memoProvider.addMemo(content: text);
                            memoInputCtrl.clear();
                            _snack('Memo ditambahkan ✓');
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Daftar memo items
              if (memos.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada memo',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...memos.map((memo) {
                  return GestureDetector(
                    onTap: () => _showEditMemoModal(context, memo),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 22),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  memo.content.length > 40
                                      ? '${memo.content.substring(0, 40)}...'
                                      : memo.content,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await memoProvider.deleteMemo(memo.id);
                                  if (mounted) {
                                    _snack('Memo dihapus');
                                  }
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatMemoDate(memo.updatedAt),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 80), // spacer untuk bottom nav
            ];

              return ListView(
                controller: sc,
                physics: const AlwaysScrollableScrollPhysics(),
                children: memoItems,
              );
            },
          ),
      3 => // Focus Timer
        Consumer<FocusTimerProvider>(
            builder: (_, focusProvider, _) {
              final isActive = focusProvider.currentSession != null;

              if (isActive) {
                // Active session display
                final remaining = focusProvider.remainingSeconds;
                final activity = focusProvider.currentSession!.activity;

                return ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 90),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                  // Timer display
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('⏱️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          _formatFocusTime(remaining),
                          style: GoogleFonts.poppins(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sisa waktu fokus',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Activity info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aktivitas',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                activity,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Control buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final coins = await focusProvider.completeSession();
                            if (mounted && coins > 0) {
                              await context.read<HabitProvider>().addCoins(coins);
                              _snack('Focus selesai! +$coins koin 🎉');
                            } else {
                              _snack('Focus selesai! Bagus! 🎉');
                            }
                          },
                          icon: const Icon(Icons.stop_circle),
                          label: Text(
                            'Selesai',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            focusProvider.toggleMusic();
                            _snack('🎵 Musik produktif aktif');
                          },
                          icon: const Icon(Icons.music_note),
                          label: Text(
                            'Musik',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tips
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jangan periksa ponsel, fokus pada aktivitas',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Idle state (no active session)
            return ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 90),
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 20),
                Text(
                  'Focus Timer',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tingkatkan produktivitas dengan fokus terukur',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // Big button
                GestureDetector(
                  onTap: () => _showFocusTimerSetup(context, focusProvider),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mulai Focus Sekarang',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Atur durasi 1-120 menit dan musik untuk tetap fokus',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            },
          ),
      _ => const SizedBox.shrink(),
    };
  }

  String _formatFocusTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatMemoDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditMemoModal(BuildContext context, dynamic memo) {
    final textCtrl = TextEditingController(text: memo.content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Memo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis memo...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final memoProvider = context.read<MemoProvider>();
                      if (textCtrl.text.isNotEmpty) {
                        memoProvider.updateMemo(
                          memoId: memo.id,
                          content: textCtrl.text,
                        );
                        Navigator.pop(context);
                        _snack('Memo diperbarui');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

  void _showFocusTimerSetup(BuildContext context, FocusTimerProvider focusProvider) {
    int selectedDuration = 10;
    final activityCtrl = TextEditingController(text: 'Fokus Belajar');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Focus Timer',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aktivitas',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: activityCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Baca Buku, Coding',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Durasi: $selectedDuration menit',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Slider(
                  value: selectedDuration.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
                  onChanged: (val) => setState(() => selectedDuration = val.toInt()),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final activity = activityCtrl.text.trim();
                      if (activity.isEmpty) {
                        _snack('Silakan isi aktivitas terlebih dahulu');
                        return;
                      }
                      focusProvider.startFocusSession(
                        activity: activity,
                        durationMinutes: selectedDuration,
                        category: 'reading',
                      );
                      Navigator.pop(context);
                      _snack('Focus dimulai! 🎯');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      'Mulai Focus',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Habit cards ───────────────────────────────────────────────────────────
  List<Widget> _buildHabitCards(HabitProvider provider) {
    // Only show habits not yet completed today
    final pending = provider.habits
        .where((h) => !h.isCompletedOnDate)
        .toList();

    // All done: every habit completed today
    final allDone = provider.habits.isNotEmpty &&
        provider.habits.every((h) => h.isCompletedOnDate);

    if (allDone) {
      return [_allDoneBanner(provider.habits.length)];
    }

    if (provider.habits.isEmpty) return [_emptyState()];

    return pending.map((h) => _habitCard(h, provider)).toList();
  }

  Widget _allDoneBanner(int total) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            'Semua selesai hari ini!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$total habit berhasil diselesaikan. Luar biasa!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(
            'Belum ada habit',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + untuk tambah habit pertamamu',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
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
          final goalProvider = context.read<GoalProvider>();
          final ok = await provider.completeHabit(habit.id, goalProvider: goalProvider);
          if (mounted) ok ? _showCoin(habit.coins, provider) : _showFraud();
          return false;
        }
        return await _confirmDelete(
              context,
              title: 'Hapus Habit?',
              content: '"${habit.title}" akan dihapus permanen.',
            ) ??
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
        onTap: () => _showHabitDetails(context, provider, habit),
        onLongPress: () => _openEditHabit(habit),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: done ? habit.color.withValues(alpha: 0.45) : habit.color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: habit.color.withValues(alpha: done ? 0.12 : 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done ? Colors.white : Colors.transparent,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: done
                          ? Icon(Icons.check, color: habit.color, size: 17)
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
                              color: Colors.white.withValues(
                                alpha: done ? 0.6 : 1.0,
                              ),
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
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Coin badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${habit.coins}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Coins',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showHabitDetails(BuildContext context, HabitProvider provider, HabitModel habit) {
    final done = habit.isCompletedOnDate;

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
                color: habit.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.title,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${habit.coins} COS coins',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (habit.streak > 0) ...[
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '${habit.streak} hari berturut-turut',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Sudah diselesaikan hari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (!done)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
          if (!done)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final goalProvider = context.read<GoalProvider>();
                final ok = await provider.completeHabit(habit.id, goalProvider: goalProvider);
                if (mounted) {
                  ok ? _showCoin(habit.coins, provider) : _showFraud();
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Ceklis',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: habit.color,
                foregroundColor: Colors.white,
              ),
            ),
          if (!done)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openEditHabit(habit);
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(
                'Edit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await _confirmDelete(
                context,
                title: 'Hapus Habit?',
                content: '"${habit.title}" akan dihapus permanen.',
              );
              if (confirm == true && mounted) {
                provider.deleteHabit(habit.id);
                _snack('Habit dihapus');
              }
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (authProv.isLoggedIn) ...[
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.person,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                authProv.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                authProv.email,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (!mounted) return;
                    // Clear semua provider data sebelum logout
                    final habitProv = context.read<HabitProvider>();
                    final goalProv = context.read<GoalProvider>();
                    final memoProv = context.read<MemoProvider>();
                    final focusProv = context.read<FocusTimerProvider>();

                    Navigator.pop(context); // tutup sheet dulu

                    // Lalu clear dan logout
                    await habitProv.clearUserData();
                    await goalProv.clearUserData();
                    await memoProv.clearUserData();
                    await focusProv.clearUserData();
                    // signOut() akan trigger onLogoutNavigate callback
                    await authProv.signOut();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    'Keluar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text('🔑', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'Login dengan Google',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Diperlukan untuk tukar koin & sync ke cloud.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (authProv.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await authProv.signInWithGoogle();
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                        _snack('Login berhasil! 🎉', color: AppColors.primary);
                      } else if (authProv.error != null) {
                        _snack(authProv.error!, color: AppColors.danger);
                      }
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: Text(
                      'Login dengan Google',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cloud, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OpenWeatherMap API',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
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
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Paste API key...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Cara Dapat API Key',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Paham',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '? Cara dapat API key gratis',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
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
                _snack(
                  'API key tersimpan! Refresh cuaca...',
                  color: AppColors.primary,
                );
                await _fetchWeather();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: AddHabitScreen(editHabit: habit),
        ),
      ),
    );
  }

  void _openAddGoal() {
    Navigator.push(
      context,
      AppTransition.slideRight(child: const AddGoalScreen()),
    );
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────
  void _showCoin(int coins, HabitProvider provider) {
    final allDone = provider.habits.isNotEmpty &&
        provider.habits.every((h) => h.isCompletedOnDate);
    final msg = allDone
        ? '+$coins koin! Semua habit selesai! 🎉'
        : '+$coins COS coins! 🎉';
    _snack(msg, color: AppColors.primary);
  }

  void _showFraud() {
    _snack('Aktivitas tidak biasa terdeteksi ⚠️', color: AppColors.warning);
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
