import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';

class UserProfileProvider extends ChangeNotifier {
  static const String _keyName = 'user_name';
  static const String _keyAddress = 'user_address';
  static const String _keyWhatsapp = 'user_whatsapp';

  SharedPreferences? _prefs;

  String _name = '';
  String _address = '';
  String _whatsapp = '';

  String get name => _name;
  String get address => _address;
  String get whatsapp => _whatsapp;

  bool get isProfileComplete => _name.isNotEmpty && _address.isNotEmpty && _whatsapp.isNotEmpty;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    final prefs = await _getPrefs();
    _name = prefs.getString(_keyName) ?? '';
    _address = prefs.getString(_keyAddress) ?? '';
    _whatsapp = prefs.getString(_keyWhatsapp) ?? '';
  }

  Future<void> updateProfile({
    required String name,
    required String address,
    required String whatsapp,
  }) async {
    _name = name.trim();
    _address = address.trim();
    _whatsapp = whatsapp.replaceAll(RegExp(r'[^\d+]'), '');

    final prefs = await _getPrefs();
    await Future.wait([
      prefs.setString(_keyName, _name),
      prefs.setString(_keyAddress, _address),
      prefs.setString(_keyWhatsapp, _whatsapp),
    ]);

    notifyListeners();
  }

  Future<void> clearProfile() async {
    _name = '';
    _address = '';
    _whatsapp = '';

    final prefs = await _getPrefs();
    await Future.wait([
      prefs.remove(_keyName),
      prefs.remove(_keyAddress),
      prefs.remove(_keyWhatsapp),
    ]);

    notifyListeners();
  }

  /// Update nomor WhatsApp, simpan lokal + sync kontak ke Firebase.
  Future<void> updateWhatsapp(String whatsapp) async {
    _whatsapp = whatsapp.replaceAll(RegExp(r'[^\d+]'), '');
    final prefs = await _getPrefs();
    await prefs.setString(_keyWhatsapp, _whatsapp);
    notifyListeners();
    await FirebaseService.saveUserContactInfo(
      whatsapp: _whatsapp,
      address: _address,
    );
  }

  /// Update alamat, simpan lokal + sync kontak ke Firebase.
  Future<void> updateAddress(String address) async {
    _address = address.trim();
    final prefs = await _getPrefs();
    await prefs.setString(_keyAddress, _address);
    notifyListeners();
    await FirebaseService.saveUserContactInfo(
      whatsapp: _whatsapp,
      address: _address,
    );
  }

  /// Auto-populate profile dari Google user info (saat pertama kali login)
  Future<void> autoPopulateFromGoogle({
    required String googleName,
    required String googleEmail,
  }) async {
    final prefs = await _getPrefs();

    if (_name.isEmpty) {
      _name = googleName.isEmpty ? 'User' : googleName;
      await prefs.setString(_keyName, _name);
    }

    if (_address.isEmpty) {
      _address = googleEmail;
      await prefs.setString(_keyAddress, _address);
    }

    notifyListeners();
  }
}
