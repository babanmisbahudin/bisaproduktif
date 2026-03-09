import 'dart:math';

class OtpService {
  static final OtpService _instance = OtpService._internal();

  factory OtpService() {
    return _instance;
  }

  OtpService._internal();

  /// Store the generated OTP temporarily (for verification)
  String? _currentOtp;
  String? _currentWhatsApp;
  DateTime? _otpGeneratedAt;

  /// Generate a 6-digit OTP code
  String generateOtp() {
    final random = Random();
    _currentOtp = (100000 + random.nextInt(900000)).toString();
    _otpGeneratedAt = DateTime.now();
    return _currentOtp!;
  }

  /// Verify the OTP code (free/development simulation)
  /// In production, you would send this via actual WhatsApp API
  bool verifyOtp(String enteredOtp) {
    if (_currentOtp == null) return false;

    // Check if OTP is still valid (5 minutes)
    final expirationTime = _otpGeneratedAt!.add(const Duration(minutes: 5));
    if (DateTime.now().isAfter(expirationTime)) {
      _currentOtp = null;
      return false;
    }

    // Verify the code
    final isValid = _currentOtp == enteredOtp;
    if (isValid) {
      _currentOtp = null; // Clear OTP after successful verification
    }
    return isValid;
  }

  /// Check if OTP has been generated and is still waiting for verification
  bool hasActiveOtp() {
    if (_currentOtp == null) return false;
    final expirationTime = _otpGeneratedAt!.add(const Duration(minutes: 5));
    return DateTime.now().isBefore(expirationTime);
  }

  /// Get remaining time in seconds
  int getRemainingSeconds() {
    if (_currentOtp == null) return 0;
    final expirationTime = _otpGeneratedAt!.add(const Duration(minutes: 5));
    final remaining = expirationTime.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Clear the OTP (when user cancels or after timeout)
  void clearOtp() {
    _currentOtp = null;
    _otpGeneratedAt = null;
    _currentWhatsApp = null;
  }

  /// Set the WhatsApp number being verified
  void setWhatsAppNumber(String waNumber) {
    _currentWhatsApp = waNumber;
  }

  /// Get the WhatsApp number being verified
  String? getWhatsAppNumber() {
    return _currentWhatsApp;
  }
}
