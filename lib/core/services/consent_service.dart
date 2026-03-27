import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk manage user consent (GDPR compliance untuk EEA/UK/Switzerland)
class ConsentService {
  static const String _consentKey = 'user_consent_given';
  static const String _consentTimestampKey = 'user_consent_timestamp';

  /// Check apakah user sudah memberikan consent
  static Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Set user consent
  static Future<void> setConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, consent);
    await prefs.setString(
      _consentTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Clear consent (untuk reset)
  static Future<void> clearConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
    await prefs.remove(_consentTimestampKey);
  }

  /// Get consent timestamp
  static Future<String?> getConsentTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_consentTimestampKey);
  }
}
