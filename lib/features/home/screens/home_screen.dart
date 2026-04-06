// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/widgets/responsive_layout_widget.dart';
import '../../../core/widgets/dynamic_scene_painter.dart';
import '../../../core/services/weather_service.dart' as weather;
import '../../../data/providers/auth_provider.dart' as auth_prov;
import '../../../data/models/habit_model.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/goal_provider.dart';
import '../../habits/screens/add_habit_screen.dart';
import '../../focus/screens/focus_timer_screen.dart';
import '../../focus/widgets/focus_tab.dart';
import '../../goals/widgets/goals_tab.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/memo_provider.dart';
import '../../../data/providers/focus_timer_provider.dart';
import '../../../core/widgets/bottom_navbar_widget.dart';
import '../../../data/providers/user_profile_provider.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = '';
  int _selectedTab = 0;
  weather.WeatherData? _weatherData;
  bool _waReminderShown = false;

  // Sheet state — menggantikan DraggableScrollableController yg sering bug
  double _sheetFraction = 0.47;
  bool _sheetDragging = false;
  late final PageController _pageCtrl = PageController();

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
          _checkAndShowWaReminder();
        }
      });

      // Cek reminder WA saat pertama buka
      Future.delayed(const Duration(milliseconds: 800), _checkAndShowWaReminder);
    });
  }

  Future<void> _checkAndShowWaReminder() async {
    if (!mounted || _waReminderShown) return;
    final authProvider = context.read<auth_prov.AuthProvider>();
    if (!authProvider.isLoggedIn) return;
    final profileProvider = context.read<UserProfileProvider>();
    if (profileProvider.whatsapp.isNotEmpty && profileProvider.address.isNotEmpty) return;

    // Cek flag "jangan tampilkan lagi" dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('wa_reminder_dismissed') == true) return;
    if (!mounted) return;

    _waReminderShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📱', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lengkapi Nomor WhatsApp',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Data kontakmu belum lengkap!\n\nAdmin butuh nomor WhatsApp dan alamat pengirimanmu untuk memproses reward yang kamu tukarkan.\n\nTanpa data ini, admin tidak bisa menghubungimu dan rewardmu tidak bisa dikirim — padahal koin sudah terpakai.\n\nLengkapi sekarang biar klaim reward-mu aman dan lancar! 🔒',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Atur Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Nanti saja',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('wa_reminder_dismissed', true);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    'Jangan tampilkan lagi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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



  @override
  void dispose() {
    _handlePulseCtrl.dispose();
    _pageCtrl.dispose();
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

                    // ── 4. Custom bottom sheet (AnimatedContainer) ──────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: _sheetDragging
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: mq.size.height * _sheetFraction,
                        child: _buildSheet(habitProvider),
                      ),
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
        final iconSize = context.iconSize(17);
        final labelFontSize = context.fontSize(13);
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: const Color(0xFFFFD54F),
                  size: iconSize,
                ),
                SizedBox(width: context.padding(5)),
                Text(
                  'COS coins collected',
                  style: GoogleFonts.poppins(
                    fontSize: labelFontSize,
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

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () async {
          await _fetchWeather();
        },
        onLongPress: _showWeatherApiDialog,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.padding(10),
            vertical: context.padding(6),
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(context.radius(16)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: TextStyle(fontSize: context.fontSize(18))),
              if (tempDisplay.isNotEmpty) ...[
                SizedBox(width: context.padding(4)),
                Text(
                  tempDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: context.fontSize(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(HabitProvider provider) {
    return Consumer<auth_prov.AuthProvider>(
      builder: (_, authProv, context) {
        return Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.fromLTRB(
              context.padding(20),
              context.padding(12),
              context.padding(20),
              0,
            ),
            child: Column(
              children: [
                // Top row: name + weather (responsive layout)
                context.isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildNameSection(authProv, context),
                          ),
                          SizedBox(width: context.padding(16)),
                          _buildWeatherChip(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: _buildNameSection(authProv, context),
                          ),
                          _buildWeatherChip(),
                        ],
                      ),
                ResponsiveSpacing(baseHeight: 12),
                // Bottom row: progress pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.padding(14),
                        vertical: context.padding(8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius:
                            BorderRadius.circular(context.radius(22)),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        '${provider.completedToday} / ${provider.totalHabits}',
                        style: GoogleFonts.poppins(
                          fontSize: context.fontSize(13),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameSection(
    auth_prov.AuthProvider authProv,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _showProfileSheet(authProv),
      child: Row(
        children: [
          Container(
            width: context.iconSize(40),
            height: context.iconSize(40),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(context.radius(14)),
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
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: context.iconSize(20),
                    )
                  : Text(
                      '👋',
                      style: TextStyle(fontSize: context.fontSize(18)),
                    ),
            ),
          ),
          SizedBox(width: context.padding(10)),
          Flexible(
            child: Text(
              _userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(16),
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
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────
  Widget _buildSheet(HabitProvider provider) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(context.radius(32))),
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
            // Drag handle area — tap toggle + drag naik/turun sheet
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // Cycle: collapsed → max → half → collapsed
                setState(() {
                  if (_sheetFraction <= 0.35) {
                    _sheetFraction = 0.75;
                  } else if (_sheetFraction >= 0.65) {
                    _sheetFraction = 0.47;
                  } else {
                    _sheetFraction = 0.28;
                  }
                });
              },
              onVerticalDragStart: (_) {
                setState(() => _sheetDragging = true);
              },
              onVerticalDragUpdate: (d) {
                final screenH = MediaQuery.of(context).size.height;
                final delta = -(d.primaryDelta ?? 0) / screenH;
                setState(() {
                  _sheetFraction = (_sheetFraction + delta).clamp(0.28, 0.75);
                });
              },
              onVerticalDragEnd: (d) {
                final velocity = d.primaryVelocity ?? 0;
                const snaps = [0.28, 0.47, 0.75];
                double target;
                if (velocity < -600) {
                  target = 0.75; // swipe up cepat → max
                } else if (velocity > 600) {
                  target = 0.28; // swipe down cepat → collapse
                } else {
                  target = snaps.reduce((a, b) =>
                    (_sheetFraction - a).abs() < (_sheetFraction - b).abs() ? a : b);
                }
                setState(() {
                  _sheetDragging = false;
                  _sheetFraction = target;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.padding(20),
                  horizontal: context.padding(16),
                ),
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
                        width: context.padding(48),
                        height: context.padding(5),
                        decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(
                              context.radius(2.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab switcher
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.padding(22),
                context.padding(14),
                context.padding(22),
                0,
              ),
              child: _buildTabs(context),
            ),

            // Content
            Expanded(
              child: _buildTabContent(provider),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────
  Widget _buildTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabPill('Daily habits', 0, context),
          SizedBox(width: context.padding(8)),
          _tabPill('Goals', 1, context),
          SizedBox(width: context.padding(8)),
          _tabPill('Fokus', 2, context),
          SizedBox(width: context.padding(8)),
          _tabPill('Memo', 3, context),
        ],
      ),
    );
  }

  Widget _tabPill(String label, int index, BuildContext context) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _sheetFraction = 0.75; // expand ke max, tidak ada controller conflict
        });
        _pageCtrl.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.padding(16),
              vertical: context.padding(10),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(14),
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
            width: label.length * context.fontSize(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(context.radius(1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────────────────────────
  Widget _buildTabContent(HabitProvider habitProvider) {
    return PageView(
      controller: _pageCtrl,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedTab = index;
          if (_sheetFraction < 0.70) _sheetFraction = 0.75; // expand jika belum max
        });
      },
      children: [
        // ── Page 0: Daily habits ─────────────────────────────────────────
        habitProvider.isLoaded
            ? ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 90),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ..._buildHabitCards(habitProvider),
                  if (habitProvider.habits.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _addHabitButton(context),
                  ],
                ],
              )
            : const Center(child: CircularProgressIndicator()),

        // ── Page 1: Goals ────────────────────────────────────────────────
        GoalsTab(
          onCoinEarned: () => setState(() {}),
        ),

        // ── Page 2: Fokus ────────────────────────────────────────────────
        const FocusTab(),

        // ── Page 3: Memo ─────────────────────────────────────────────────
        _MemoPage(onSnack: _snack),
      ],
    );
  }




  // ── Habit cards ───────────────────────────────────────────────────────────
  Widget _addHabitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openAddHabit,
        icon: const Icon(Icons.add, size: 18),
        label: Text(
          'Tambah Habit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: context.padding(14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radius(14)),
          ),
          elevation: 0,
        ),
      ),
    );
  }

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
              child: const Icon(Icons.self_improvement_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada habit',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat habit harian dan selesaikan untuk mendapatkan koin!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddHabit,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Tambah Habit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
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
                    // Timer button (hanya jika belum selesai)
                    if (!done)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FocusTimerScreen(linkedHabit: habit),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '⏱️',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header: warna aksen + nama + status ────────────────────────
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: habit.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: habit.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.radio_button_unchecked,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: done
                              ? Colors.green.withValues(alpha: 0.12)
                              : habit.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          done ? '✅ Selesai hari ini' : '⏳ Belum selesai',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: done ? Colors.green.shade700 : habit.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Info chips: koin, streak, kategori ────────────────────────
            Row(
              children: [
                _infoChip(
                  '💰', '${habit.coins} koin',
                  Colors.amber.shade700, Colors.amber.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 10),
                _infoChip(
                  '🔥', habit.streak > 0 ? '${habit.streak} hari' : 'Mulai hari ini',
                  Colors.deepOrange, Colors.deepOrange.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 10),
                _infoChip(
                  habit.category.emoji, habit.category.label,
                  AppColors.primary, AppColors.primary.withValues(alpha: 0.08),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Divider tipis ──────────────────────────────────────────────
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 20),

            // ── Tombol aksi ────────────────────────────────────────────────
            if (!done) ...[
              // Ceklis: full-width, warna habit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final goalProvider = context.read<GoalProvider>();
                    final ok = await provider.completeHabit(
                        habit.id, goalProvider: goalProvider);
                    if (mounted) {
                      ok ? _showCoin(habit.coins, provider) : _showFraud();
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    'Ceklis Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: habit.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Edit + Hapus: dua kolom sejajar
            Row(
              children: [
                // Edit
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditHabit(habit);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Hapus
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
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
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.danger,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Info chip kecil untuk koin / streak / kategori
  Widget _infoChip(
      String emoji, String label, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

    showDialog<void>(
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
    ).then((_) => keyCtrl.dispose());
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

// ── Memo Page ─────────────────────────────────────────────────────────────────
class _MemoPage extends StatefulWidget {
  final void Function(String msg, {Color? color}) onSnack;
  const _MemoPage({required this.onSnack});

  @override
  State<_MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<_MemoPage> {
  final TextEditingController _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hari ini ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditModal(dynamic memo, MemoProvider memoProvider) {
    final textCtrl = TextEditingController(text: memo.content);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Edit Memo',
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                autofocus: true,
                minLines: 4,
                maxLines: 10,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis apapun yang kamu mau...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF6F6F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Batal', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (textCtrl.text.trim().isNotEmpty) {
                          memoProvider.updateMemo(memoId: memo.id, content: textCtrl.text.trim());
                          Navigator.pop(context);
                          widget.onSnack('Memo diperbarui ✓');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => textCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<MemoProvider>(
      builder: (_, memoProvider, _) {
        final memos = memoProvider.memos;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // ── Banner deskripsi ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Text('📌', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kamu bisa simpan apapun di sini. Jika kamu pelupa, ini tempat yang tepat!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Textarea input ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _inputCtrl,
                minLines: 4,
                maxLines: 8,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis catatan, ide, atau pengingat...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Tombol simpan ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final text = _inputCtrl.text.trim();
                  if (text.isEmpty) {
                    widget.onSnack('Tulis memo terlebih dahulu');
                    return;
                  }
                  await memoProvider.addMemo(content: text);
                  _inputCtrl.clear();
                  widget.onSnack('Memo disimpan ✓');
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Simpan Memo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // ── Daftar memo ────────────────────────────────────────────────
            if (memos.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Text('🗒️', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text('Belum ada catatan tersimpan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 6),
                    Text('Mulai tulis sesuatu di atas',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Text(
                '${memos.length} catatan tersimpan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...memos.map((memo) => _memoCard(memo, memoProvider, isDark)),
            ],
          ],
        );
      },
    );
  }

  Widget _memoCard(dynamic memo, MemoProvider memoProvider, bool isDark) {
    return GestureDetector(
      onTap: () => _showEditModal(memo, memoProvider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    memo.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await memoProvider.deleteMemo(memo.id);
                    widget.onSnack('Memo dihapus');
                  },
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(memo.updatedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap untuk edit',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
