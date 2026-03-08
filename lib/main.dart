import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'data/models/habit_model.dart';
import 'data/models/goal_model.dart';
import 'data/providers/habit_provider.dart';
import 'data/providers/goal_provider.dart';
import 'data/models/transaction_model.dart';
import 'data/providers/reward_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/admin_provider.dart';
import 'data/providers/notification_provider.dart';
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

  // Init Hive (local storage)
  await Hive.initFlutter();
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());

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
      ],
      child: const BisaProduktifApp(),
    ),
  );
}

class BisaProduktifApp extends StatelessWidget {
  const BisaProduktifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'bisaproduktif',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
