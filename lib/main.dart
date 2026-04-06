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
import 'data/models/goal_task_model.dart';
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

  // Hive: WAJIB await sebelum provider dibuat
  await Hive.initFlutter();
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(GoalTaskAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(MemoModelAdapter());
  Hive.registerAdapter(FocusSessionModelAdapter());

  // Firebase: await tapi cepat, dibutuhkan AuthProvider
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    debugPrint('Firebase initialized ✅');
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => HabitProvider()..init()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..init()),
        ChangeNotifierProvider(create: (_) => RewardProvider()..init()),
        ChangeNotifierProvider(create: (_) {
          final auth = AuthProvider();
          if (firebaseReady) auth.init();
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => AdminProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()), // init dipanggil HomeScreen setelah NotificationService siap
        ChangeNotifierProvider(create: (_) => UserProfileProvider()..init()),
        ChangeNotifierProvider(create: (_) => MemoProvider()..init()),
        ChangeNotifierProvider(create: (_) {
          final focusTimer = FocusTimerProvider();
          focusTimer.init().then((_) => focusTimer.restoreSessionIfActive());
          return focusTimer;
        }),
        ChangeNotifierProvider(create: (_) => AdMobProvider()..init()),
      ],
      child: const BisaProduktifApp(),
    ),
  );

  // Heavy init setelah UI tampil — tidak block startup
  NotificationService().init();
  MobileAds.instance.initialize().then((_) {
    debugPrint('AdMob initialized ✅');
  });
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
