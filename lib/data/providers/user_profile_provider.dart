import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';

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

  /// Update nomor WhatsApp, simpan lokal + sync ke Firebase.
  Future<void> updateWhatsapp(String whatsapp) async {
    _whatsapp = whatsapp.replaceAll(RegExp(r'[^\d+]'), '');
    await _prefs.setString(_keyWhatsapp, _whatsapp);
    notifyListeners();
    await FirebaseService.saveWhatsapp(_whatsapp);
  }

  /// Auto-populate profile dari Google user info (saat pertama kali login)
  Future<void> autoPopulateFromGoogle({
    required String googleName,
    required String googleEmail,
  }) async {
    // Hanya auto-populate jika profile belum lengkap
    if (_name.isEmpty) {
      _name = googleName.isEmpty ? 'User' : googleName;
      await _prefs.setString(_keyName, _name);
    }

    // Address di-isi dengan placeholder (user harus edit nanti)
    if (_address.isEmpty) {
      _address = googleEmail; // Placeholder: gunakan email
      await _prefs.setString(_keyAddress, _address);
    }

    // WhatsApp tetap kosong (opsional, user harus isi)
    // Tidak ada perubahan pada _whatsapp

    notifyListeners();
  }
}
