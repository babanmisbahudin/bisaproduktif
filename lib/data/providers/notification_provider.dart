import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _morningEnabled = true;
  int _morningHour = 7;
  int _morningMinute = 0;

  bool _eveningEnabled = true;
  int _eveningHour = 20;
  int _eveningMinute = 0;

  bool get morningEnabled => _morningEnabled;
  int get morningHour => _morningHour;
  int get morningMinute => _morningMinute;
  TimeOfDay get morningTime => TimeOfDay(hour: _morningHour, minute: _morningMinute);

  bool get eveningEnabled => _eveningEnabled;
  int get eveningHour => _eveningHour;
  int get eveningMinute => _eveningMinute;
  TimeOfDay get eveningTime => TimeOfDay(hour: _eveningHour, minute: _eveningMinute);

  /// Jumlah notifikasi aktif (untuk badge)
  int get activeCount => (_morningEnabled ? 1 : 0) + (_eveningEnabled ? 1 : 0);

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init({String userName = ''}) async {
    await _loadSettings();
    await _rescheduleAll(userName: userName);
  }

  // ── Morning Reminder ──────────────────────────────────────────────────────

  Future<void> setMorningEnabled(bool enabled, {String userName = ''}) async {
    _morningEnabled = enabled;
    await _saveSettings();
    if (enabled) {
      await NotificationService().scheduleMorningReminder(
        hour: _morningHour,
        minute: _morningMinute,
        userName: userName,
      );
    } else {
      await NotificationService().cancelMorningReminder();
    }
    notifyListeners();
  }

  Future<void> setMorningTime(TimeOfDay time, {String userName = ''}) async {
    _morningHour = time.hour;
    _morningMinute = time.minute;
    await _saveSettings();
    if (_morningEnabled) {
      await NotificationService().scheduleMorningReminder(
        hour: _morningHour,
        minute: _morningMinute,
        userName: userName,
      );
    }
    notifyListeners();
  }

  // ── Evening Warning ───────────────────────────────────────────────────────

  Future<void> setEveningEnabled(bool enabled) async {
    _eveningEnabled = enabled;
    await _saveSettings();
    if (enabled) {
      await NotificationService().scheduleEveningWarning(
        hour: _eveningHour,
        minute: _eveningMinute,
      );
    } else {
      await NotificationService().cancelEveningWarning();
    }
    notifyListeners();
  }

  Future<void> setEveningTime(TimeOfDay time) async {
    _eveningHour = time.hour;
    _eveningMinute = time.minute;
    await _saveSettings();
    if (_eveningEnabled) {
      await NotificationService().scheduleEveningWarning(
        hour: _eveningHour,
        minute: _eveningMinute,
      );
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _rescheduleAll({String userName = ''}) async {
    if (_morningEnabled) {
      await NotificationService().scheduleMorningReminder(
        hour: _morningHour,
        minute: _morningMinute,
        userName: userName,
      );
    }
    if (_eveningEnabled) {
      await NotificationService().scheduleEveningWarning(
        hour: _eveningHour,
        minute: _eveningMinute,
      );
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_morning_enabled', _morningEnabled);
    await prefs.setInt('notif_morning_hour', _morningHour);
    await prefs.setInt('notif_morning_minute', _morningMinute);
    await prefs.setBool('notif_evening_enabled', _eveningEnabled);
    await prefs.setInt('notif_evening_hour', _eveningHour);
    await prefs.setInt('notif_evening_minute', _eveningMinute);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _morningEnabled = prefs.getBool('notif_morning_enabled') ?? true;
    _morningHour = prefs.getInt('notif_morning_hour') ?? 7;
    _morningMinute = prefs.getInt('notif_morning_minute') ?? 0;
    _eveningEnabled = prefs.getBool('notif_evening_enabled') ?? true;
    _eveningHour = prefs.getInt('notif_evening_hour') ?? 20;
    _eveningMinute = prefs.getInt('notif_evening_minute') ?? 0;
  }
}
