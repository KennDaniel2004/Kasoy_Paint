import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricCheckResult {
  success,
  notAvailable,
  notEnrolled,
  failed,
  error,
}

/// Wraps `local_auth` and makes it safe to call on platforms that don't
/// support biometrics (web, Windows, Linux). On those platforms every
/// method short-circuits to a safe "not available" result instead of
/// throwing a `MissingPluginException`.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Biometrics are a native mobile/desktop feature. Web has no
  /// `local_auth` implementation, so we refuse to touch the plugin there.
  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    if (!_isSupportedPlatform) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      debugPrint(
        'local_auth isDeviceSupported=$supported canCheckBiometrics=$canCheck',
      );
      return supported && canCheck;
    } catch (e) {
      debugPrint('local_auth isDeviceSupported() threw: $e');
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    if (!_isSupportedPlatform) return <BiometricType>[];
    try {
      final types = await _auth.getAvailableBiometrics();
      debugPrint('local_auth availableBiometrics=$types');
      return types;
    } catch (e) {
      debugPrint('local_auth availableBiometrics() threw: $e');
      return <BiometricType>[];
    }
  }

  Future<BiometricCheckResult> authenticate({
    String reason = 'Scan your fingerprint to continue',
  }) async {
    if (!_isSupportedPlatform) {
      debugPrint('local_auth skipped: platform does not support biometrics.');
      return BiometricCheckResult.notAvailable;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate
          ? BiometricCheckResult.success
          : BiometricCheckResult.failed;
    } on PlatformException catch (e) {
      debugPrint('local_auth PlatformException: ${e.code} — ${e.message}');
      switch (e.code) {
        case 'NotEnrolled':
          return BiometricCheckResult.notEnrolled;

        case 'NotAvailable':
        case 'PasscodeNotSet':
          return BiometricCheckResult.notAvailable;

        // Android: MainActivity must extend FlutterFragmentActivity.
        case 'no_fragment_activity':
          debugPrint(
            'FIX: Change MainActivity.kt to extend FlutterFragmentActivity.',
          );
          return BiometricCheckResult.notAvailable;

        case 'LockedOut':
        case 'PermanentlyLockedOut':
        case 'auth_in_progress':
        case 'device_credentials_unsupported':
          return BiometricCheckResult.failed;

        default:
          return BiometricCheckResult.error;
      }
    } catch (e) {
      debugPrint('local_auth unexpected error: $e');
      return BiometricCheckResult.error;
    }
  }
}