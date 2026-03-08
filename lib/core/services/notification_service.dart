import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ID tetap per jenis notifikasi
  static const int _morningId = 1;
  static const int _eveningId = 2;
  static const int _goalBaseId = 100; // goal notif pakai id = 100 + index

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTz = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Fallback jika nama timezone tidak dikenali
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Minta izin notifikasi (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService initialized ✅');
  }

  void _onTap(NotificationResponse response) {
    debugPrint('[Notif] Tapped id=${response.id}');
  }

  // ── Morning Reminder (daily) ──────────────────────────────────────────────

  Future<void> scheduleMorningReminder({
    required int hour,
    required int minute,
    String userName = '',
  }) async {
    await _plugin.cancel(_morningId);
    final name = userName.isNotEmpty ? userName : 'kamu';
    await _scheduleDaily(
      id: _morningId,
      title: 'Selamat pagi, $name! 🌅',
      body: 'Yuk mulai hari dengan menyelesaikan habit harianmu!',
      hour: hour,
      minute: minute,
    );
    debugPrint(
        '[Notif] Morning reminder dijadwalkan $hour:${minute.toString().padLeft(2, '0')}');
  }

  Future<void> cancelMorningReminder() async {
    await _plugin.cancel(_morningId);
    debugPrint('[Notif] Morning reminder dibatalkan');
  }

  // ── Evening Streak Warning (daily) ───────────────────────────────────────

  Future<void> scheduleEveningWarning({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_eveningId);
    await _scheduleDaily(
      id: _eveningId,
      title: 'Jangan putuskan streakmu! 🔥',
      body: 'Masih ada habit yang belum selesai hari ini. Ayo semangat!',
      hour: hour,
      minute: minute,
    );
    debugPrint(
        '[Notif] Evening warning dijadwalkan $hour:${minute.toString().padLeft(2, '0')}');
  }

  Future<void> cancelEveningWarning() async {
    await _plugin.cancel(_eveningId);
    debugPrint('[Notif] Evening warning dibatalkan');
  }

  // ── Goal Deadline Reminder (H-1) ─────────────────────────────────────────

  Future<void> scheduleGoalDeadlineReminder({
    required int goalIndex,
    required String goalTitle,
    required DateTime deadline,
  }) async {
    final reminderDate = deadline.subtract(const Duration(days: 1));
    if (reminderDate.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, 0,
    );

    try {
      await _plugin.zonedSchedule(
        _goalBaseId + goalIndex,
        '⚠️ Deadline goal besok!',
        '"$goalTitle" deadline besok. Segera update progress kamu!',
        scheduled,
        _notifDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Notif] Goal deadline reminder untuk "$goalTitle"');
    } catch (e) {
      debugPrint('[Notif] Gagal schedule goal reminder: $e');
    }
  }

  Future<void> cancelGoalReminder(int goalIndex) async {
    await _plugin.cancel(_goalBaseId + goalIndex);
  }

  // ── Test Notification ─────────────────────────────────────────────────────

  Future<void> showTestNotification() async {
    await _plugin.show(
      0,
      'BisaProduktif ✅',
      'Notifikasi berfungsi! Habit reminder akan muncul sesuai jadwal.',
      _notifDetails(),
    );
  }

  // ── Cancel All ────────────────────────────────────────────────────────────

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _notifDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Fallback: exact alarm tidak tersedia, pakai inexact
      debugPrint('[Notif] Exact alarm tidak tersedia, fallback inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          _notifDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e2) {
        debugPrint('[Notif] Gagal schedule notifikasi: $e2');
      }
    }
  }

  NotificationDetails _notifDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'bisaproduktif_reminder',
          'BisaProduktif Reminders',
          channelDescription: 'Pengingat habit harian dan goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4A7C59),
          enableVibration: true,
          playSound: true,
          ticker: 'BisaProduktif',
        ),
      );
}
