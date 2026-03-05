import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/sync_service_v2.dart';

/// State for the global sync banner.
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;

  const SyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
  });

  bool get showBanner => !isOnline || isSyncing || pendingCount > 0 || failedCount > 0;
  bool get isIdle => isOnline && !isSyncing && pendingCount == 0 && failedCount == 0;

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
  }) =>
      SyncState(
        isOnline: isOnline ?? this.isOnline,
        isSyncing: isSyncing ?? this.isSyncing,
        pendingCount: pendingCount ?? this.pendingCount,
        failedCount: failedCount ?? this.failedCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncState &&
          isOnline == other.isOnline &&
          isSyncing == other.isSyncing &&
          pendingCount == other.pendingCount &&
          failedCount == other.failedCount;

  @override
  int get hashCode => Object.hash(isOnline, isSyncing, pendingCount, failedCount);
}

/// Cubit that listens to [SyncService.progressStream] and exposes
/// a [SyncState] for the UI sync banner.
class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService;
  StreamSubscription<SyncProgress>? _sub;

  SyncCubit(this._syncService) : super(const SyncState()) {
    _sub = _syncService.progressStream.listen(_onProgress);

    // Emit initial state from service
    final initial = _syncService.lastProgress;
    emit(SyncState(
      isOnline: initial.isOnline,
      isSyncing: initial.isSyncing,
      pendingCount: initial.pendingCount,
      failedCount: initial.failedCount,
    ));
  }

  void _onProgress(SyncProgress progress) {
    emit(SyncState(
      isOnline: progress.isOnline,
      isSyncing: progress.isSyncing,
      pendingCount: progress.pendingCount,
      failedCount: progress.failedCount,
    ));
  }

  /// Manual sync trigger.
  Future<void> syncNow() async {
    await _syncService.syncNow();
  }

  /// Retry all permanently failed items.
  Future<void> retryFailed() async {
    await _syncService.retryFailed();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
