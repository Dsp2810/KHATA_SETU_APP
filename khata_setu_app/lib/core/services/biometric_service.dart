import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/types/auth_exception.dart';

/// Result of a biometric authentication attempt.
enum BiometricResult {
  /// Authentication succeeded.
  success,

  /// User cancelled the prompt.
  cancelled,

  /// Authentication failed (wrong fingerprint / face).
  failed,

  /// Device has no biometric hardware.
  noHardware,

  /// Biometric hardware present but no fingerprints enrolled.
  notEnrolled,

  /// OS-level lockout (too many failed attempts).
  lockedOut,

  /// Permanent lockout — strong auth (PIN/password) required.
  permanentlyLockedOut,

  /// Unexpected error.
  error,
}

/// Abstract interface for biometric operations.
/// Enables easy mocking/testing without touching OS APIs.
abstract class IBiometricService {
  /// Whether device has biometric hardware (fingerprint sensor / face ID).
  Future<bool> isDeviceCapable();

  /// Whether at least one biometric is enrolled on the device.
  Future<bool> hasEnrolledBiometrics();

  /// Returns the list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics();

  /// Prompts the user for biometric authentication.
  /// [localizedReason] is shown in the OS dialog.
  Future<BiometricResult> authenticate({required String localizedReason});
}

/// Production implementation using [LocalAuthentication].
class BiometricService implements IBiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isDeviceCapable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('BiometricService.isDeviceCapable error: $e');
      return false;
    }
  }

  @override
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('BiometricService.hasEnrolledBiometrics error: $e');
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricService.getAvailableBiometrics error: $e');
      return [];
    }
  }

  @override
  Future<BiometricResult> authenticate({
    required String localizedReason,
  }) async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      debugPrint('BiometricService.authenticate LocalAuthException: ${e.code} – ${e.description}');
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.userRequestedFallback:
          return BiometricResult.cancelled;
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricResult.noHardware;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          return BiometricResult.notEnrolled;
        case LocalAuthExceptionCode.temporaryLockout:
          return BiometricResult.lockedOut;
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricResult.permanentlyLockedOut;
        default:
          return BiometricResult.error;
      }
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate PlatformException: ${e.code} – ${e.message}');
      switch (e.code) {
        case 'NotAvailable':
          return BiometricResult.noHardware;
        case 'NotEnrolled':
          return BiometricResult.notEnrolled;
        case 'LockedOut':
          return BiometricResult.lockedOut;
        case 'PermanentlyLockedOut':
          return BiometricResult.permanentlyLockedOut;
        case 'UserCancel':
        case 'SystemCancel':
          return BiometricResult.cancelled;
        default:
          return BiometricResult.error;
      }
    } catch (e) {
      debugPrint('BiometricService.authenticate unexpected error: $e');
      return BiometricResult.cancelled;
    }
  }
}
