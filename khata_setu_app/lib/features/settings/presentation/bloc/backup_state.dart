import 'package:equatable/equatable.dart';

import '../../../../core/services/drive_service.dart';
import '../../../../core/services/restore_service.dart';

/// All possible states for the Backup & Restore feature.
abstract class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

/// Initial state — loading connection status.
class BackupInitial extends BackupState {
  const BackupInitial();
}

/// Idle state — shows current connection status and last backup info.
class BackupIdle extends BackupState {
  final bool isConnected;
  final String? connectedEmail;
  final DateTime? lastBackupTime;
  final String? message;
  final bool isError;

  const BackupIdle({
    required this.isConnected,
    this.connectedEmail,
    this.lastBackupTime,
    this.message,
    this.isError = false,
  });

  @override
  List<Object?> get props =>
      [isConnected, connectedEmail, lastBackupTime, message, isError];

  BackupIdle copyWith({
    bool? isConnected,
    String? connectedEmail,
    DateTime? lastBackupTime,
    String? message,
    bool? isError,
  }) {
    return BackupIdle(
      isConnected: isConnected ?? this.isConnected,
      connectedEmail: connectedEmail ?? this.connectedEmail,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      message: message,
      isError: isError ?? this.isError,
    );
  }
}

/// Connecting to Google Drive.
class BackupConnecting extends BackupState {
  const BackupConnecting();
}

/// Backup in progress.
class BackupInProgress extends BackupState {
  final String stage; // 'exporting', 'encrypting', 'uploading'

  const BackupInProgress(this.stage);

  @override
  List<Object?> get props => [stage];
}

/// Restore: listing available backups from Drive.
class BackupListingRestorePoints extends BackupState {
  const BackupListingRestorePoints();
}

/// Restore: showing available backups for user selection.
class BackupRestorePointsLoaded extends BackupState {
  final List<DriveBackupMeta> backups;

  const BackupRestorePointsLoaded(this.backups);

  @override
  List<Object?> get props => [backups];
}

/// Restore in progress.
class BackupRestoreInProgress extends BackupState {
  final String stage; // 'downloading', 'decrypting', 'importing'

  const BackupRestoreInProgress(this.stage);

  @override
  List<Object?> get props => [stage];
}

/// Restore completed successfully.
class BackupRestoreComplete extends BackupState {
  final RestoreResult result;

  const BackupRestoreComplete(this.result);

  @override
  List<Object?> get props => [result];
}
