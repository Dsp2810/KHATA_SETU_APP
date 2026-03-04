import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/app_logger.dart';

/// Service that monitors network connectivity.
///
/// Provides a stream of connectivity status and a current-check method.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Whether the device currently has network access
  bool get isOnline => _isOnline;

  /// Stream that emits `true` when online, `false` when offline
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Start listening for connectivity changes
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      AppLogger.info('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      _controller.add(_isOnline);
    }
  }

  /// Manual check — call before critical network operations
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
