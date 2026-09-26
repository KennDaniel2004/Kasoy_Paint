import 'package:shared_preferences/shared_preferences.dart';

/// Local, on-device-only record of which Firebase account is linked to
/// biometric login on *this specific phone*.
///
/// Keys:
///   kasoy_biometric_enabled_uid  → uid of the account linked to biometrics
///   kasoy_device_registered      → true once ANY account has been registered
///                                   on this device (biometric or not)
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _kBiometricUidKey = 'kasoy_biometric_enabled_uid';
  static const _kDeviceRegisteredKey = 'kasoy_device_registered';

  // ── Biometric link ─────────────────────────────────────────────

  Future<void> setBiometricEnabledForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBiometricUidKey, uid);
  }

  Future<void> clearBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBiometricUidKey);
  }

  Future<String?> getBiometricUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBiometricUidKey);
  }

  // ── Device registration flag ───────────────────────────────────

  /// Called once after the very first successful registration on this
  /// device, whether or not biometrics were enabled.
  Future<void> markDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDeviceRegisteredKey, true);
  }

  Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDeviceRegisteredKey) ?? false;
  }

  /// Optional: full reset (useful for testing).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBiometricUidKey);
    await prefs.remove(_kDeviceRegisteredKey);
  }
}