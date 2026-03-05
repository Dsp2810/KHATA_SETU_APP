import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Metadata for a backup file stored on Google Drive.
class DriveBackupMeta {
  final String fileId;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;

  DriveBackupMeta({
    required this.fileId,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
  });
}

/// Handles Google Sign-In authentication and Google Drive file operations.
///
/// All files are stored in the hidden `appDataFolder` so users cannot
/// accidentally delete backups from the Drive UI.
class DriveService {
  static const _scopes = [drive.DriveApi.driveAppdataScope];
  static const _backupPrefix = 'khatasetu_backup_';
  static const _backupSuffix = '.enc';
  static const _maxBackups = 5;
  static const _connectedAccountKey = 'gdrive_connected_email';

  /// Web OAuth 2.0 Client ID (also used as serverClientId on Android).
  static const _webClientId =
      '410088655694-rvjc877881gnblajk0s6lm510unnt2vu.apps.googleusercontent.com';

  final FlutterSecureStorage _secureStorage;
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentAccount;
  drive.DriveApi? _driveApi;

  DriveService(this._secureStorage);

  // ─── Authentication ────────────────────────────────────────

  /// Whether the user has previously connected a Google account.
  Future<bool> get isConnected async {
    final email = await _secureStorage.read(key: _connectedAccountKey);
    return email != null && email.isNotEmpty;
  }

  /// The connected Google account email, or null.
  Future<String?> get connectedEmail async {
    return _secureStorage.read(key: _connectedAccountKey);
  }

  /// Initialize Google Sign-In and try silent sign-in.
  Future<void> init() async {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: kIsWeb ? null : _webClientId,
    );
    try {
      _currentAccount = await _googleSignIn!.signInSilently();
      if (_currentAccount != null) {
        await _initDriveApi();
      }
    } catch (e) {
      _log.w('Silent sign-in failed: $e');
    }
  }

  /// Interactive sign-in. Returns the connected email or null on cancel.
  Future<String?> signIn() async {
    _googleSignIn ??= GoogleSignIn(
      scopes: _scopes,
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: kIsWeb ? null : _webClientId,
    );
    try {
      _currentAccount = await _googleSignIn!.signIn();
      if (_currentAccount == null) return null; // user cancelled

      await _initDriveApi();
      await _secureStorage.write(
        key: _connectedAccountKey,
        value: _currentAccount!.email,
      );
      _log.i('Google Drive connected: ${_currentAccount!.email}');
      return _currentAccount!.email;
    } catch (e) {
      _log.e('Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// Disconnect Google account and clear stored credentials.
  Future<void> disconnect() async {
    try {
      await _googleSignIn?.disconnect();
    } catch (_) {}
    _currentAccount = null;
    _driveApi = null;
    await _secureStorage.delete(key: _connectedAccountKey);
    _log.i('Google Drive disconnected');
  }

  Future<void> _initDriveApi() async {
    final httpClient = (await _googleSignIn!.authenticatedClient())!;
    _driveApi = drive.DriveApi(httpClient);
  }

  /// Ensure we have a valid DriveApi, performing silent sign-in if needed.
  Future<drive.DriveApi> _ensureDriveApi() async {
    if (_driveApi != null) return _driveApi!;

    _googleSignIn ??= GoogleSignIn(scopes: _scopes);
    _currentAccount = await _googleSignIn!.signInSilently();
    if (_currentAccount == null) {
      throw StateError('Not signed in to Google. Please connect first.');
    }
    await _initDriveApi();
    return _driveApi!;
  }

  // ─── Upload ────────────────────────────────────────────────

  /// Upload encrypted backup bytes to appDataFolder.
  /// Returns the created file's ID.
  Future<String> uploadBackup(Uint8List data) async {
    final api = await _ensureDriveApi();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$_backupPrefix$timestamp$_backupSuffix';

    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];

    final media = drive.Media(
      Stream.value(data),
      data.length,
    );

    final created = await api.files.create(
      fileMetadata,
      uploadMedia: media,
    );

    _log.i('Backup uploaded: ${created.id} ($fileName, ${data.length} bytes)');

    // Prune old backups to keep only the latest _maxBackups
    await _pruneOldBackups(api);

    return created.id!;
  }

  // ─── List & Download ───────────────────────────────────────

  /// List available backups, newest first.
  Future<List<DriveBackupMeta>> listBackups() async {
    final api = await _ensureDriveApi();

    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_backupPrefix'",
      orderBy: 'createdTime desc',
      $fields: 'files(id, name, createdTime, size)',
    );

    return (result.files ?? []).map((f) {
      return DriveBackupMeta(
        fileId: f.id!,
        fileName: f.name!,
        createdAt: f.createdTime ?? DateTime.now(),
        sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
      );
    }).toList();
  }

  /// Download a backup file by ID.
  Future<Uint8List> downloadBackup(String fileId) async {
    final api = await _ensureDriveApi();

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final chunks = <List<int>>[];
    await for (final chunk in media.stream) {
      chunks.add(chunk);
    }

    final totalLength = chunks.fold<int>(0, (sum, c) => sum + c.length);
    final bytes = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    _log.i('Backup downloaded: $fileId (${bytes.length} bytes)');
    return bytes;
  }

  // ─── Cleanup ───────────────────────────────────────────────

  /// Delete backups beyond the latest [_maxBackups].
  Future<void> _pruneOldBackups(drive.DriveApi api) async {
    try {
      final result = await api.files.list(
        spaces: 'appDataFolder',
        q: "name contains '$_backupPrefix'",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime)',
      );

      final files = result.files ?? [];
      if (files.length <= _maxBackups) return;

      final toDelete = files.sublist(_maxBackups);
      for (final file in toDelete) {
        await api.files.delete(file.id!);
        _log.i('Pruned old backup: ${file.name}');
      }
    } catch (e) {
      _log.w('Prune failed (non-critical): $e');
    }
  }
}
