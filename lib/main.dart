import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'data/models/habit_model.dart';
import 'data/models/goal_model.dart';
import 'data/models/transaction_model.dart';
import 'data/models/memo_model.dart';
import 'data/models/focus_session_model.dart';
import 'data/providers/habit_provider.dart';
import 'data/providers/goal_provider.dart';
import 'data/providers/reward_provider.dart';
import 'data/providers/memo_provider.dart';
import 'data/providers/focus_timer_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/admin_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/user_profile_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/admob_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init Notification Service
  await NotificationService().init();

  // Init Google Mobile Ads (AdMob)
  await MobileAds.instance.initialize();

  // Init Hive (local storage)
  await Hive.initFlutter();
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(MemoModelAdapter());
  Hive.registerAdapter(FocusSessionModelAdapter());

  // Init Firebase (graceful fallback jika google-services.json belum dikonfigurasi)
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    debugPrint('Firebase initialized ✅');
  } catch (e) {
    debugPrint('Firebase not configured yet (ganti google-services.json dengan yang asli): $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => HabitProvider()..init()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..init()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) {
          final auth = AuthProvider();
          if (firebaseReady) auth.init();
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => AdminProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()..init()),
        ChangeNotifierProvider(create: (_) => MemoProvider()..init()),
        ChangeNotifierProvider(create: (_) {
          final focusTimer = FocusTimerProvider()..init();
          // Restore session jika ada yang aktif saat app dibuka
          Future.delayed(const Duration(milliseconds: 100), () {
            focusTimer.restoreSessionIfActive();
          });
          return focusTimer;
        }),
        ChangeNotifierProvider(create: (_) => AdMobProvider()..init()),
      ],
      child: const BisaProduktifApp(),
    ),
  );
}

class BisaProduktifApp extends StatelessWidget {
  const BisaProduktifApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'bisaproduktif',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
