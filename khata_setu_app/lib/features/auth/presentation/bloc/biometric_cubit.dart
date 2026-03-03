import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';

// ─── States ────────────────────────────────────────────────────

abstract class BiometricState extends Equatable {
  const BiometricState();
  @override
  List<Object?> get props => [];
}

/// Initial / loading state.
class BiometricInitial extends BiometricState {
  const BiometricInitial();
}

/// Device has no biometric hardware or no enrolled biometrics.
class BiometricUnavailable extends BiometricState {
  final String reason; // 'noHardware' | 'notEnrolled'
  const BiometricUnavailable(this.reason);
  @override
  List<Object?> get props => [reason];
}

/// Biometric is available but not enabled by the user.
class BiometricAvailable extends BiometricState {
  const BiometricAvailable();
}

/// Biometric is enabled and ready.
class BiometricEnabled extends BiometricState {
  const BiometricEnabled();
}

/// Authentication is in progress (prompt is showing).
class BiometricAuthenticating extends BiometricState {
  const BiometricAuthenticating();
}

/// Authentication succeeded.
class BiometricAuthSuccess extends BiometricState {
  const BiometricAuthSuccess();
}

/// Authentication failed or was cancelled.
class BiometricAuthFailed extends BiometricState {
  final BiometricResult result;
  const BiometricAuthFailed(this.result);
  @override
  List<Object?> get props => [result];
}

// ─── Cubit ─────────────────────────────────────────────────────

class BiometricCubit extends Cubit<BiometricState> {
  final IBiometricService _biometricService;
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  BiometricCubit({
    required IBiometricService biometricService,
    required LocalStorageService localStorage,
    required SecureStorageService secureStorage,
  })  : _biometricService = biometricService,
        _localStorage = localStorage,
        _secureStorage = secureStorage,
        super(const BiometricInitial());

  // ─── Initialization ──────────────────────────────────────────

  /// Check device capabilities and user preference.
  /// Call this once at app startup or when Settings page opens.
  Future<void> checkBiometricStatus() async {
    final capable = await _biometricService.isDeviceCapable();
    if (!capable) {
      emit(const BiometricUnavailable('noHardware'));
      return;
    }

    final enrolled = await _biometricService.hasEnrolledBiometrics();
    if (!enrolled) {
      // Biometrics were removed after being enabled → auto-disable
      if (_localStorage.isBiometricEnabled()) {
        await _localStorage.setBiometricEnabled(false);
      }
      emit(const BiometricUnavailable('notEnrolled'));
      return;
    }

    final isEnabled = _localStorage.isBiometricEnabled();
    emit(isEnabled ? const BiometricEnabled() : const BiometricAvailable());
  }

  // ─── Toggle ──────────────────────────────────────────────────

  /// Enable or disable biometric lock.
  /// When enabling, verifies biometric first.
  Future<void> toggleBiometric(bool enable, {required String localizedReason}) async {
    if (enable) {
      // Verify identity before enabling
      emit(const BiometricAuthenticating());
      final result = await _biometricService.authenticate(
        localizedReason: localizedReason,
      );
      if (result == BiometricResult.success) {
        await _localStorage.setBiometricEnabled(true);
        emit(const BiometricEnabled());
      } else {
        emit(BiometricAuthFailed(result));
        // Reset to available (user can try again)
        await Future.delayed(const Duration(milliseconds: 300));
        emit(const BiometricAvailable());
      }
    } else {
      await _localStorage.setBiometricEnabled(false);
      emit(const BiometricAvailable());
    }
  }

  // ─── Authentication ──────────────────────────────────────────

  /// Prompt biometric authentication (used at app launch).
  /// Returns true if authenticated, false otherwise.
  Future<bool> authenticate({required String localizedReason}) async {
    emit(const BiometricAuthenticating());
    final result = await _biometricService.authenticate(
      localizedReason: localizedReason,
    );

    if (result == BiometricResult.success) {
      emit(const BiometricAuthSuccess());
      return true;
    } else {
      emit(BiometricAuthFailed(result));
      return false;
    }
  }

  // ─── Queries ─────────────────────────────────────────────────

  /// Whether biometric lock is enabled in user preferences.
  bool get isEnabled => _localStorage.isBiometricEnabled();

  /// Whether the device has biometric hardware + enrolled biometrics
  /// AND the user has enabled the feature → biometric should be required at launch.
  Future<bool> shouldRequireBiometric() async {
    if (!_localStorage.isBiometricEnabled()) return false;

    // Check token exists (user is logged in)
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return false;

    // Check device still has biometric capability
    final capable = await _biometricService.isDeviceCapable();
    if (!capable) {
      // Device lost biometric capability → silently disable
      await _localStorage.setBiometricEnabled(false);
      return false;
    }

    final enrolled = await _biometricService.hasEnrolledBiometrics();
    if (!enrolled) {
      // Biometrics removed → silently disable
      await _localStorage.setBiometricEnabled(false);
      return false;
    }

    return true;
  }
}
