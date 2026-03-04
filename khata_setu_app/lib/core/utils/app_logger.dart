import 'package:flutter/foundation.dart';

/// Centralized logger that only outputs in debug mode.
/// Use instead of [debugPrint] or [print] to prevent
/// information leakage in production builds.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  Exception: $error');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
  }
}
