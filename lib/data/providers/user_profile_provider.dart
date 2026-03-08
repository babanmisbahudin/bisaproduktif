import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileProvider extends ChangeNotifier {
  static const String _keyName = 'user_name';
  static const String _keyAddress = 'user_address';
  static const String _keyWhatsapp = 'user_whatsapp';

  late SharedPreferences _prefs;

  String _name = '';
  String _address = '';
  String _whatsapp = '';

  String get name => _name;
  String get address => _address;
  String get whatsapp => _whatsapp;

  bool get isProfileComplete => _name.isNotEmpty && _address.isNotEmpty && _whatsapp.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProfile();
  }

  void _loadProfile() {
    _name = _prefs.getString(_keyName) ?? '';
    _address = _prefs.getString(_keyAddress) ?? '';
    _whatsapp = _prefs.getString(_keyWhatsapp) ?? '';
  }

  Future<void> updateProfile({
    required String name,
    required String address,
    required String whatsapp,
  }) async {
    _name = name.trim();
    _address = address.trim();
    _whatsapp = whatsapp.replaceAll(RegExp(r'[^\d+]'), ''); // Sanitize whatsapp (hanya angka & +)

    await Future.wait([
      _prefs.setString(_keyName, _name),
      _prefs.setString(_keyAddress, _address),
      _prefs.setString(_keyWhatsapp, _whatsapp),
    ]);

    notifyListeners();
  }

  Future<void> clearProfile() async {
    _name = '';
    _address = '';
    _whatsapp = '';

    await Future.wait([
      _prefs.remove(_keyName),
      _prefs.remove(_keyAddress),
      _prefs.remove(_keyWhatsapp),
    ]);

    notifyListeners();
  }
}
