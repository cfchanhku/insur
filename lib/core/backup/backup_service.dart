/// Creates, verifies, and restores passphrase-protected SQLCipher backups.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../audit/audit_event_type.dart';
import '../database/database.dart';
import '../database/repositories/audit_repository.dart';
import '../database/schema.dart';
import '../security/key_backup_material.dart';
import '../security/key_manager.dart';
import 'backup_crypto.dart';
import 'backup_exception.dart';
import 'backup_file.dart';
import 'backup_file_service.dart';
import 'backup_format.dart';
import 'backup_header.dart';
import 'backup_payload.dart';
import 'backup_result.dart';

/// Encrypts database-file snapshots using a dedicated backup passphrase.
///
/// Callers must stop writes, checkpoint SQLCipher, and close the database
/// before invoking [createBackup] or [restoreBackup]. The unlocked key manager
/// exports disposable vault key state into the encrypted payload, allowing
/// recovery on a replacement device. Restore leaves the key manager locked;
/// the user must log in with the existing passphrase.
///
/// Restore writes the authenticated database bytes atomically but deliberately
/// does not open or migrate the resulting database. The caller must
/// reopen/migrate it and use the pre-restore backup to recover if that later
/// step fails.
///
/// Audit records are written only after the caller reopens the database using
/// [recordBackupAudit] or [recordRestoreAudit]. This avoids writing to a
/// closed SQLCipher connection during a consistent file snapshot or restore.
class BackupService {
  /// Creates a backup service.
  BackupService({
    required this.database,
    required KeyManager keyManager,
    required AuditRepository auditRepository,
    required BackupFileService fileService,
    required String appVersion,
  }) : _keyManager = keyManager,
       _auditRepository = auditRepository,
       _fileService = fileService,
       _appVersion = appVersion;

  final AuditRepository _auditRepository;
  final BackupFileService _fileService;
  final String _appVersion;
  final KeyManager _keyManager;

  /// Database connection the caller closes before file-level backup work and
  /// reopens before writing the deferred audit event.
  final AppDatabase database;

  /// Creates an encrypted backup from a closed, checkpointed database file.
  ///
  /// The backup passphrase is independent from the login passphrase and is
  /// never stored. The returned file includes the database, audit log, and
  /// app configuration because all reside in the SQLCipher database.
  Future<BackupResult> createBackup({
    required String passphrase,
    required String dbFilePath,
    required String destinationPath,
  }) async {
    _validatePassphrase(passphrase);
    if (_samePath(dbFilePath, destinationPath)) {
      throw ArgumentError('Backup destination must differ from the database');
    }
    final databaseBytes = await _readDatabaseFile(dbFilePath);
    KeyBackupMaterial? keyMaterial;
    Uint8List? payloadBytes;
    try {
      keyMaterial = await _keyManager.exportBackupMaterial();
      final payload = BackupPayload(
        databaseBytes: databaseBytes,
        keyMaterial: keyMaterial,
      );
      payloadBytes = payload.toBytes();
      final createdAt = DateTime.now().toUtc();
      final (int major, int minor, int patch) = _parseAppVersion(_appVersion);
      final salt = _randomBytes(BackupFormat.saltLength);
      final nonce = _randomBytes(BackupFormat.nonceLength);
      final header = BackupHeader(
        formatVersion: BackupFormat.formatVersion,
        appVersionMajor: major,
        appVersionMinor: minor,
        appVersionPatch: patch,
        schemaVersion: Schema.currentSchemaVersion,
        createdAt: createdAt,
        kdfIterations: BackupFormat.kdfIterations,
        kdfMemoryKiB: BackupFormat.kdfMemoryKiB,
        kdfParallelism: BackupFormat.kdfParallelism,
        salt: salt,
        nonce: nonce,
      );
      final bytes = await _encryptDatabase(
        passphrase: passphrase,
        plaintext: payloadBytes,
        header: header,
      );
      await _fileService.writeBytes(destinationPath, bytes);
      return BackupResult(
        success: true,
        path: destinationPath,
        sizeBytes: bytes.length,
        createdAt: createdAt,
      );
    } finally {
      databaseBytes.fillRange(0, databaseBytes.length, 0);
      payloadBytes?.fillRange(0, payloadBytes.length, 0);
      keyMaterial?.clear();
    }
  }

  /// Restores an authenticated backup to a closed database file.
  ///
  /// A pre-restore backup is written before replacement. The database must
  /// remain closed during the atomic file swap. This method does not emit the
  /// `RESTORE_DB` audit event; call [recordRestoreAudit] after reopening.
  Future<RestoreResult> restoreBackup({
    required String passphrase,
    required String sourcePath,
    required String dbFilePath,
    required String preRestoreBackupPath,
  }) async {
    _validatePassphrase(passphrase);
    if (_samePath(sourcePath, dbFilePath) ||
        _samePath(preRestoreBackupPath, dbFilePath) ||
        _samePath(sourcePath, preRestoreBackupPath)) {
      throw ArgumentError('Backup, database, and recovery paths must differ');
    }

    final backupBytes = await _fileService.readBytes(sourcePath);
    final backup = BackupFile.fromBytes(backupBytes);
    _validateKdfParameters(backup.header);
    if (backup.header.formatVersion != BackupFormat.formatVersion) {
      throw const BackupVersionException(
        'Backup format version is not supported',
      );
    }
    final plaintext = await _decryptBackup(
      backup: backup,
      passphrase: passphrase,
    );
    BackupPayload? payload;
    try {
      payload = BackupPayload.fromBytes(plaintext);
      if (backup.header.schemaVersion > Schema.currentSchemaVersion) {
        throw const BackupVersionException(
          'Backup is from a newer database schema',
        );
      }
      if (await _fileService.exists(preRestoreBackupPath)) {
        throw const BackupIoException('Pre-restore backup path already exists');
      }
      await createBackup(
        passphrase: passphrase,
        dbFilePath: dbFilePath,
        destinationPath: preRestoreBackupPath,
      );
      await _atomicReplaceDatabase(dbFilePath, payload.databaseBytes);
      await _keyManager.restoreBackupMaterial(
        payload.keyMaterial,
        replaceExisting: true,
      );
      return RestoreResult(
        success: true,
        restoredFrom: sourcePath,
        schemaVersion: backup.header.schemaVersion,
        preRestoreBackupPath: preRestoreBackupPath,
      );
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
      payload?.clear();
    }
  }

  /// Verifies an encrypted backup without writing files or audit records.
  ///
  /// Invalid files and authentication failures are returned as an invalid
  /// result with a safe reason rather than exposing cryptographic details.
  Future<VerificationResult> verifyBackup({
    required String passphrase,
    required String sourcePath,
  }) async {
    if (passphrase.runes.length < 12) {
      return const VerificationResult(
        isValid: false,
        reason: 'Backup authentication failed',
      );
    }
    Uint8List? plaintext;
    BackupHeader? header;
    try {
      final bytes = await _fileService.readBytes(sourcePath);
      final backup = BackupFile.fromBytes(bytes);
      header = backup.header;
      _validateKdfParameters(backup.header);
      plaintext = await _decryptBackup(backup: backup, passphrase: passphrase);
      BackupPayload.fromBytes(plaintext).clear();
      return VerificationResult(isValid: true, header: header);
    } on BackupException catch (error) {
      return VerificationResult(
        isValid: false,
        header: header,
        reason: error.message,
      );
    } finally {
      plaintext?.fillRange(0, plaintext.length, 0);
    }
  }

  /// Records the successful backup after the caller has reopened the database.
  Future<void> recordBackupAudit(BackupResult result) async {
    if (!result.success || result.createdAt == null || result.sizeBytes <= 0) {
      throw ArgumentError.value(
        result,
        'result',
        'Must be a successful backup',
      );
    }
    await _auditRepository.append(
      eventType: AuditEventType.backup,
      metadata: <String, Object?>{
        'size_bytes': result.sizeBytes,
        'schema_version': Schema.currentSchemaVersion,
      },
    );
  }

  /// Records a completed restore after the caller has reopened the database.
  Future<void> recordRestoreAudit(RestoreResult result) async {
    if (!result.success || result.schemaVersion < 1) {
      throw ArgumentError.value(
        result,
        'result',
        'Must be a successful restore',
      );
    }
    await _auditRepository.append(
      eventType: AuditEventType.restoreDb,
      metadata: <String, Object?>{'schema_version': result.schemaVersion},
    );
  }

  Future<Uint8List> _encryptDatabase({
    required String passphrase,
    required Uint8List plaintext,
    required BackupHeader header,
  }) async {
    Uint8List? backupKey;
    Uint8List? hmacKey;
    Uint8List? encryptedWithNonce;
    Uint8List? ciphertext;
    Uint8List? authenticatedData;
    try {
      backupKey = await BackupCrypto.deriveBackupKey(
        passphrase: passphrase,
        salt: header.salt,
      );
      hmacKey = await BackupCrypto.deriveHmacKey(backupKey);
      final headerBytes = header.toBytes();
      encryptedWithNonce = await BackupCrypto.encrypt(
        backupKey: backupKey,
        plaintext: plaintext,
        nonce: header.nonce,
        aadHeader: headerBytes,
      );
      if (encryptedWithNonce.length <
              BackupFormat.nonceLength + BackupFormat.tagLength ||
          !_constantTimeEquals(
            Uint8List.sublistView(
              encryptedWithNonce,
              0,
              BackupFormat.nonceLength,
            ),
            header.nonce,
          )) {
        throw const BackupException('Unable to create encrypted backup');
      }
      ciphertext = Uint8List.fromList(
        encryptedWithNonce.sublist(BackupFormat.nonceLength),
      );
      authenticatedData = _concat(headerBytes, ciphertext);
      final hmac = BackupCrypto.computeHmac(
        hmacKey: hmacKey,
        data: authenticatedData,
      );
      final backup = BackupFile(
        header: header,
        ciphertext: ciphertext,
        hmac: hmac,
      );

      final decrypted = await _decryptBackup(
        backup: backup,
        passphrase: passphrase,
      );
      try {
        if (!_constantTimeEquals(decrypted, plaintext)) {
          throw const BackupException('Backup self-verification failed');
        }
      } finally {
        decrypted.fillRange(0, decrypted.length, 0);
      }
      return backup.toBytes();
    } finally {
      backupKey?.fillRange(0, backupKey.length, 0);
      hmacKey?.fillRange(0, hmacKey.length, 0);
      encryptedWithNonce?.fillRange(0, encryptedWithNonce.length, 0);
      ciphertext?.fillRange(0, ciphertext.length, 0);
      authenticatedData?.fillRange(0, authenticatedData.length, 0);
    }
  }

  Future<Uint8List> _decryptBackup({
    required BackupFile backup,
    required String passphrase,
  }) async {
    Uint8List? backupKey;
    Uint8List? hmacKey;
    Uint8List? authenticatedData;
    try {
      backupKey = await BackupCrypto.deriveBackupKey(
        passphrase: passphrase,
        salt: backup.header.salt,
      );
      hmacKey = await BackupCrypto.deriveHmacKey(backupKey);
      authenticatedData = _concat(backup.header.toBytes(), backup.ciphertext);
      if (!BackupCrypto.verifyHmac(
        hmacKey: hmacKey,
        data: authenticatedData,
        expected: backup.hmac,
      )) {
        throw const BackupAuthenticationException(
          'Backup authentication failed',
        );
      }
      return await BackupCrypto.decrypt(
        backupKey: backupKey,
        ciphertextWithTag: backup.ciphertext,
        nonce: backup.header.nonce,
        aadHeader: backup.header.toBytes(),
      );
    } finally {
      backupKey?.fillRange(0, backupKey.length, 0);
      hmacKey?.fillRange(0, hmacKey.length, 0);
      authenticatedData?.fillRange(0, authenticatedData.length, 0);
    }
  }

  Future<void> _atomicReplaceDatabase(
    String dbFilePath,
    Uint8List plaintext,
  ) async {
    final temporaryPath = '$dbFilePath.restore-tmp';
    try {
      await _fileService.writeBytes(temporaryPath, plaintext);
      await File(temporaryPath).rename(dbFilePath);
    } on BackupException {
      await _deleteTemporaryFile(temporaryPath);
      rethrow;
    } on FileSystemException {
      await _deleteTemporaryFile(temporaryPath);
      throw const BackupIoException('Unable to replace database file');
    }
  }

  Future<void> _deleteTemporaryFile(String temporaryPath) async {
    try {
      final temporaryFile = File(temporaryPath);
      if (temporaryFile.existsSync()) {
        await temporaryFile.delete();
      }
    } on FileSystemException {
      throw const BackupIoException(
        'Unable to remove temporary restored database data',
      );
    }
  }

  Future<Uint8List> _readDatabaseFile(String dbFilePath) async {
    try {
      return await File(dbFilePath).readAsBytes();
    } on FileSystemException {
      throw const BackupIoException('Unable to read database file');
    }
  }

  static void _validatePassphrase(String passphrase) {
    if (passphrase.runes.length < 12) {
      throw ArgumentError.value(
        passphrase.runes.length,
        'passphrase.length',
        'Must be at least 12 characters',
      );
    }
  }

  static void _validateKdfParameters(BackupHeader header) {
    if (header.kdfIterations != BackupFormat.kdfIterations ||
        header.kdfMemoryKiB != BackupFormat.kdfMemoryKiB ||
        header.kdfParallelism != BackupFormat.kdfParallelism) {
      throw const BackupFormatException(
        'Backup key-derivation parameters are unsupported',
      );
    }
  }

  static (int, int, int) _parseAppVersion(String version) {
    final match = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$',
    ).firstMatch(version);
    if (match == null) {
      throw ArgumentError.value(
        version,
        'appVersion',
        'Must be semantic version',
      );
    }
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    for (final component in <int>[major, minor, patch]) {
      if (component > 0xffffffff) {
        throw ArgumentError.value(
          version,
          'appVersion',
          'Version component is too large',
        );
      }
    }
    return (major, minor, patch);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _concat(Uint8List first, Uint8List second) {
    final combined = Uint8List(first.length + second.length);
    combined
      ..setRange(0, first.length, first)
      ..setRange(first.length, combined.length, second);
    return combined;
  }

  static bool _constantTimeEquals(Uint8List first, Uint8List second) {
    if (first.length != second.length) {
      return false;
    }
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }

  static bool _samePath(String first, String second) {
    final normalizedFirst = path.normalize(path.absolute(first));
    final normalizedSecond = path.normalize(path.absolute(second));
    return Platform.isWindows
        ? normalizedFirst.toLowerCase() == normalizedSecond.toLowerCase()
        : normalizedFirst == normalizedSecond;
  }
}
