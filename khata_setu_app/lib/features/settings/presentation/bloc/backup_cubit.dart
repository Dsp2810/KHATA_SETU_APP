import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/backup_service.dart';
import '../../../../core/services/drive_service.dart';
import '../../../../core/services/restore_service.dart';
import '../../../../core/storage/local_storage.dart';
import 'backup_state.dart';

/// Cubit that orchestrates the Backup & Restore feature.
///
/// Keeps logic out of the UI — widgets only call methods and read state.
class BackupCubit extends Cubit<BackupState> {
  final DriveService _driveService;
  final BackupService _backupService;
  final RestoreService _restoreService;
  final LocalStorageService _localStorage;
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  static const _lastBackupKey = 'gdrive_last_backup_time';

  /// True while a backup or restore operation is in-flight.
  bool _busy = false;

  BackupCubit({
    required DriveService driveService,
    required BackupService backupService,
    required RestoreService restoreService,
    required LocalStorageService localStorage,
  })  : _driveService = driveService,
        _backupService = backupService,
        _restoreService = restoreService,
        _localStorage = localStorage,
        super(const BackupInitial());

  // ─── Initialization ───────────────────────────────────────

  /// Load connection status and last backup time.
  Future<void> init() async {
    try {
      await _driveService.init();
      final connected = await _driveService.isConnected;
      final email = await _driveService.connectedEmail;
      final lastMs = _localStorage.getInt(_lastBackupKey);
      final lastTime = lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : null;

      emit(BackupIdle(
        isConnected: connected,
        connectedEmail: email,
        lastBackupTime: lastTime,
      ));
    } catch (e) {
      _log.e('Init failed: $e');
      emit(const BackupIdle(isConnected: false));
    }
  }

  // ─── Connect / Disconnect ─────────────────────────────────

  Future<void> connectDrive() async {
    emit(const BackupConnecting());
    try {
      final email = await _driveService.signIn();
      if (email == null) {
        // User cancelled — go back to idle
        final lastMs = _localStorage.getInt(_lastBackupKey);
        emit(BackupIdle(
          isConnected: false,
          lastBackupTime: lastMs != null
              ? DateTime.fromMillisecondsSinceEpoch(lastMs)
              : null,
          message: 'Sign-in cancelled',
        ));
        return;
      }

      final lastMs = _localStorage.getInt(_lastBackupKey);
      emit(BackupIdle(
        isConnected: true,
        connectedEmail: email,
        lastBackupTime: lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : null,
        message: 'Connected to Google Drive',
      ));
    } catch (e) {
      _log.e('Connect failed: $e');
      emit(BackupIdle(
        isConnected: false,
        message: 'Failed to connect: ${e.toString().split(':').last.trim()}',
        isError: true,
      ));
    }
  }

  Future<void> disconnectDrive() async {
    try {
      await _driveService.disconnect();
      emit(const BackupIdle(
        isConnected: false,
        message: 'Google Drive disconnected',
      ));
    } catch (e) {
      _log.e('Disconnect failed: $e');
    }
  }

  // ─── Backup ───────────────────────────────────────────────

  Future<void> startBackup() async {
    if (_busy) return;
    _busy = true;

    try {
      emit(const BackupInProgress('exporting'));
      final encrypted = await _backupService.createBackup();

      emit(const BackupInProgress('uploading'));
      await _driveService.uploadBackup(encrypted);

      final now = DateTime.now();
      await _localStorage.setInt(
          _lastBackupKey, now.millisecondsSinceEpoch);

      final email = await _driveService.connectedEmail;
      emit(BackupIdle(
        isConnected: true,
        connectedEmail: email,
        lastBackupTime: now,
        message: 'Backup completed successfully!',
      ));
    } catch (e) {
      _log.e('Backup failed: $e');
      final email = await _driveService.connectedEmail;
      final lastMs = _localStorage.getInt(_lastBackupKey);
      emit(BackupIdle(
        isConnected: true,
        connectedEmail: email,
        lastBackupTime: lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : null,
        message: 'Backup failed: ${e.toString().split(':').last.trim()}',
        isError: true,
      ));
    } finally {
      _busy = false;
    }
  }

  // ─── Restore: List Backups ────────────────────────────────

  Future<void> listRestorePoints() async {
    emit(const BackupListingRestorePoints());
    try {
      final backups = await _driveService.listBackups();
      emit(BackupRestorePointsLoaded(backups));
    } catch (e) {
      _log.e('List backups failed: $e');
      final email = await _driveService.connectedEmail;
      final lastMs = _localStorage.getInt(_lastBackupKey);
      emit(BackupIdle(
        isConnected: true,
        connectedEmail: email,
        lastBackupTime: lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : null,
        message: 'Could not list backups: ${e.toString().split(':').last.trim()}',
        isError: true,
      ));
    }
  }

  /// Cancel restore selection and go back to idle.
  Future<void> cancelRestore() async {
    final email = await _driveService.connectedEmail;
    final lastMs = _localStorage.getInt(_lastBackupKey);
    emit(BackupIdle(
      isConnected: true,
      connectedEmail: email,
      lastBackupTime: lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : null,
    ));
  }

  // ─── Restore: Execute ─────────────────────────────────────

  Future<void> restoreFromBackup(String fileId) async {
    if (_busy) return;
    _busy = true;

    try {
      emit(const BackupRestoreInProgress('downloading'));
      final encrypted = await _driveService.downloadBackup(fileId);

      emit(const BackupRestoreInProgress('decrypting'));
      final snapshot = await _backupService.decryptBackup(encrypted);

      emit(const BackupRestoreInProgress('importing'));
      final result = await _restoreService.restore(snapshot);

      emit(BackupRestoreComplete(result));
    } catch (e) {
      _log.e('Restore failed: $e');
      final email = await _driveService.connectedEmail;
      final lastMs = _localStorage.getInt(_lastBackupKey);
      emit(BackupIdle(
        isConnected: true,
        connectedEmail: email,
        lastBackupTime: lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : null,
        message: 'Restore failed: ${e.toString().split(':').last.trim()}',
        isError: true,
      ));
    } finally {
      _busy = false;
    }
  }

  /// After restore completes successfully, return to idle.
  Future<void> acknowledgeRestore() async {
    final email = await _driveService.connectedEmail;
    final lastMs = _localStorage.getInt(_lastBackupKey);
    emit(BackupIdle(
      isConnected: true,
      connectedEmail: email,
      lastBackupTime: lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : null,
      message: 'Data restored successfully',
    ));
  }
}
