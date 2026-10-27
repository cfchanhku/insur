import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/backup/backup_crypto.dart';
import 'package:insur/core/backup/backup_exception.dart';
import 'package:insur/core/backup/backup_file.dart';
import 'package:insur/core/backup/backup_format.dart';
import 'package:insur/core/backup/backup_header.dart';
import 'package:insur/core/backup/backup_payload.dart';
import 'package:insur/core/backup/backup_service.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/schema.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

import '../database/database_test_helper.dart';
import 'fake_backup_file_service.dart';

void main() {
  const passphrase = 'synthetic backup passphrase';
  const sourceLoginPassphrase = 'synthetic original login';
  const targetLoginPassphrase = 'synthetic local login';
  late Directory temporaryDirectory;
  late FakeBackupFileService fileService;
  late String sourceDatabasePath;
  late String targetDatabasePath;
  late String sourceBackupPath;
  late String currentDatabasePath;
  late Uint8List sourceDatabaseBytes;
  late Uint8List targetDatabaseBytes;
  late AppDatabase sourceDatabase;
  late AppDatabase targetDatabase;
  late KeyManager sourceKeyManager;
  late KeyManager targetKeyManager;
  late String sourceRecoveryKey;

  BackupService makeService({
    required AppDatabase database,
    required AuditRepository auditRepository,
    required KeyManager keyManager,
  }) {
    return BackupService(
      database: database,
      keyManager: keyManager,
      auditRepository: auditRepository,
      fileService: fileService,
      appVersion: '0.1.0',
    );
  }

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'insur-backup-test-',
    );
    fileService = FakeBackupFileService(temporaryDirectory);
    sourceKeyManager = await _createKeyManager(sourceLoginPassphrase);
    targetKeyManager = await _createKeyManager(targetLoginPassphrase);
    sourceRecoveryKey = await sourceKeyManager.setupRecoveryKey(
      passphrase: sourceLoginPassphrase,
    );
    sourceDatabasePath = path.join(temporaryDirectory.path, 'source.db');
    targetDatabasePath = path.join(temporaryDirectory.path, 'target.db');
    sourceBackupPath = path.join(temporaryDirectory.path, 'source.enc');
    currentDatabasePath = path.join(temporaryDirectory.path, 'current.db');

    sourceDatabase = await openTestDatabase(
      dbKey: Uint8List.fromList(sourceKeyManager.dbKey),
      path: sourceDatabasePath,
    );
    await sourceDatabase.db.insert(Schema.appConfig, <String, Object?>{
      Schema.key: 'synthetic_config',
      Schema.value: 'source',
      Schema.updatedAt: DateTime.utc(2026).toIso8601String(),
    });
    await sourceDatabase.close();
    sourceDatabaseBytes = await File(sourceDatabasePath).readAsBytes();

    targetDatabase = await openTestDatabase(
      dbKey: Uint8List.fromList(targetKeyManager.dbKey),
      path: targetDatabasePath,
    );
    await targetDatabase.db.insert(Schema.appConfig, <String, Object?>{
      Schema.key: 'synthetic_config',
      Schema.value: 'target',
      Schema.updatedAt: DateTime.utc(2026).toIso8601String(),
    });
    await targetDatabase.close();
    targetDatabaseBytes = await File(targetDatabasePath).readAsBytes();

    final service = makeService(
      database: sourceDatabase,
      auditRepository: AuditRepository(db: sourceDatabase),
      keyManager: sourceKeyManager,
    );
    await service.createBackup(
      passphrase: passphrase,
      dbFilePath: sourceDatabasePath,
      destinationPath: sourceBackupPath,
    );
  });

  setUp(() async {
    if (!sourceKeyManager.isUnlocked) {
      expect(
        await sourceKeyManager.unlock(passphrase: sourceLoginPassphrase),
        isTrue,
      );
    }
    if (!targetKeyManager.isUnlocked) {
      final sourcePassphraseWorks = await targetKeyManager.unlock(
        passphrase: sourceLoginPassphrase,
      );
      if (!sourcePassphraseWorks) {
        expect(
          await targetKeyManager.unlock(passphrase: targetLoginPassphrase),
          isTrue,
        );
      }
    }
    await File(currentDatabasePath).writeAsBytes(targetDatabaseBytes);
  });

  tearDown(() {
    fileService.writeFailurePath = null;
  });

  tearDownAll(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  group('BackupService — createBackup', () {
    test(
      'writes a verifiable file that decrypts to the database bytes',
      () async {
        final createdPath = path.join(temporaryDirectory.path, 'created.enc');
        final service = makeService(
          database: sourceDatabase,
          auditRepository: AuditRepository(db: sourceDatabase),
          keyManager: sourceKeyManager,
        );

        final result = await service.createBackup(
          passphrase: passphrase,
          dbFilePath: sourceDatabasePath,
          destinationPath: createdPath,
        );
        final serialized = await File(createdPath).readAsBytes();
        final backup = BackupFile.fromBytes(serialized);
        final backupKey = await BackupCrypto.deriveBackupKey(
          passphrase: passphrase,
          salt: backup.header.salt,
        );
        final plaintext = await BackupCrypto.decrypt(
          backupKey: backupKey,
          ciphertextWithTag: backup.ciphertext,
          nonce: backup.header.nonce,
          aadHeader: backup.header.toBytes(),
        );

        expect(result.success, isTrue);
        expect(result.sizeBytes, serialized.length);
        final payload = BackupPayload.fromBytes(plaintext);
        expect(payload.databaseBytes, sourceDatabaseBytes);
        expect(payload.keyMaterial.masterKey, hasLength(32));
        expect(payload.keyMaterial.masterSalt, hasLength(32));
        expect(payload.keyMaterial.hasRecoveryKey, isTrue);
        expect(
          (await service.verifyBackup(
            passphrase: passphrase,
            sourcePath: createdPath,
          )).isValid,
          isTrue,
        );
        backupKey.fillRange(0, backupKey.length, 0);
        plaintext.fillRange(0, plaintext.length, 0);
        payload.clear();
      },
    );

    test('saves a backup through the platform save flow', () async {
      final service = makeService(
        database: sourceDatabase,
        auditRepository: AuditRepository(db: sourceDatabase),
        keyManager: sourceKeyManager,
      );

      final result = await service.createBackupToPicker(
        passphrase: passphrase,
        dbFilePath: sourceDatabasePath,
        suggestedName: 'picker-created.enc',
      );

      expect(result?.success, isTrue);
      expect(
        result?.path,
        path.join(temporaryDirectory.path, 'picker-created.enc'),
      );
      expect(
        (await service.verifyBackup(
          passphrase: passphrase,
          sourcePath: result!.path,
        )).isValid,
        isTrue,
      );
    });

    test('records the backup event after the database is reopened', () async {
      final serviceBeforeClose = makeService(
        database: sourceDatabase,
        auditRepository: AuditRepository(db: sourceDatabase),
        keyManager: sourceKeyManager,
      );
      final result = await serviceBeforeClose.createBackup(
        passphrase: passphrase,
        dbFilePath: sourceDatabasePath,
        destinationPath: path.join(temporaryDirectory.path, 'audited.enc'),
      );
      final reopened = await openTestDatabase(
        dbKey: Uint8List.fromList(sourceKeyManager.dbKey),
        path: sourceDatabasePath,
      );
      addTearDown(reopened.close);
      final auditRepository = AuditRepository(db: reopened);
      final service = makeService(
        database: reopened,
        auditRepository: auditRepository,
        keyManager: sourceKeyManager,
      );

      await service.recordBackupAudit(result);

      expect(await auditRepository.count(), 1);
      expect(
        (await auditRepository.findLast())?.eventType,
        AuditEventType.backup,
      );
    });
  });

  group('BackupService — restoreBackup', () {
    test('creates a pre-restore backup and replaces the database', () async {
      final service = makeService(
        database: targetDatabase,
        auditRepository: AuditRepository(db: targetDatabase),
        keyManager: targetKeyManager,
      );
      final preRestorePath = path.join(temporaryDirectory.path, 'before.enc');

      final result = await service.restoreBackup(
        passphrase: passphrase,
        sourcePath: sourceBackupPath,
        dbFilePath: currentDatabasePath,
        preRestoreBackupPath: preRestorePath,
      );

      expect(result.success, isTrue);
      expect(result.schemaVersion, Schema.currentSchemaVersion);
      expect(
        await File(currentDatabasePath).readAsBytes(),
        sourceDatabaseBytes,
      );
      expect(
        (await service.verifyBackup(
          passphrase: passphrase,
          sourcePath: preRestorePath,
        )).isValid,
        isTrue,
      );

      expect(targetKeyManager.isUnlocked, isFalse);
      expect(await targetKeyManager.hasRecoveryKey(), isTrue);
      expect(
        await targetKeyManager.confirmRecoveryKey(
          recoveryKey: sourceRecoveryKey,
        ),
        isTrue,
      );
      expect(
        await targetKeyManager.unlock(passphrase: sourceLoginPassphrase),
        isTrue,
      );
      final reopened = await openTestDatabase(
        dbKey: Uint8List.fromList(targetKeyManager.dbKey),
        path: currentDatabasePath,
      );
      addTearDown(reopened.close);
      final reopenedService = makeService(
        database: reopened,
        auditRepository: AuditRepository(db: reopened),
        keyManager: targetKeyManager,
      );
      await reopenedService.recordRestoreAudit(result);
      expect(await AuditRepository(db: reopened).count(), 1);
    });

    test(
      'rejects a wrong passphrase without changing the current database',
      () async {
        final original = await File(currentDatabasePath).readAsBytes();
        final service = makeService(
          database: targetDatabase,
          auditRepository: AuditRepository(db: targetDatabase),
          keyManager: targetKeyManager,
        );

        await expectLater(
          service.restoreBackup(
            passphrase: 'different synthetic passphrase',
            sourcePath: sourceBackupPath,
            dbFilePath: currentDatabasePath,
            preRestoreBackupPath: path.join(
              temporaryDirectory.path,
              'wrong.enc',
            ),
          ),
          throwsA(isA<BackupAuthenticationException>()),
        );

        expect(await File(currentDatabasePath).readAsBytes(), original);
        expect(
          File(path.join(temporaryDirectory.path, 'wrong.enc')).existsSync(),
          isFalse,
        );
      },
    );

    test('rejects a modified backup before restoring', () async {
      final modified = await File(sourceBackupPath).readAsBytes();
      modified[24] ^= 1;
      final corruptPath = path.join(temporaryDirectory.path, 'corrupt.enc');
      await File(corruptPath).writeAsBytes(modified);
      final service = makeService(
        database: targetDatabase,
        auditRepository: AuditRepository(db: targetDatabase),
        keyManager: targetKeyManager,
      );

      final result = await service.verifyBackup(
        passphrase: passphrase,
        sourcePath: corruptPath,
      );

      expect(result.isValid, isFalse);
      expect(result.reason, isNotEmpty);
    });

    test(
      'keeps the current database if the atomic replacement fails',
      () async {
        final original = await File(currentDatabasePath).readAsBytes();
        final preRestorePath = path.join(
          temporaryDirectory.path,
          'failed-restore-before.enc',
        );
        fileService.writeFailurePath = '$currentDatabasePath.restore-tmp';
        final service = makeService(
          database: targetDatabase,
          auditRepository: AuditRepository(db: targetDatabase),
          keyManager: targetKeyManager,
        );

        await expectLater(
          service.restoreBackup(
            passphrase: passphrase,
            sourcePath: sourceBackupPath,
            dbFilePath: currentDatabasePath,
            preRestoreBackupPath: preRestorePath,
          ),
          throwsA(isA<BackupIoException>()),
        );

        expect(await File(currentDatabasePath).readAsBytes(), original);
        expect(File(preRestorePath).existsSync(), isTrue);
      },
    );

    test(
      'refuses backups with a newer schema before replacing the database',
      () async {
        final newerBackup = await _makeBackup(
          plaintext: sourceDatabaseBytes,
          passphrase: passphrase,
          schemaVersion: Schema.currentSchemaVersion + 1,
          keyManager: sourceKeyManager,
        );
        final newerPath = path.join(temporaryDirectory.path, 'newer.enc');
        await File(newerPath).writeAsBytes(newerBackup);
        final service = makeService(
          database: targetDatabase,
          auditRepository: AuditRepository(db: targetDatabase),
          keyManager: targetKeyManager,
        );
        final original = await File(currentDatabasePath).readAsBytes();

        await expectLater(
          service.restoreBackup(
            passphrase: passphrase,
            sourcePath: newerPath,
            dbFilePath: currentDatabasePath,
            preRestoreBackupPath: path.join(
              temporaryDirectory.path,
              'newer-before.enc',
            ),
          ),
          throwsA(isA<BackupVersionException>()),
        );

        expect(await File(currentDatabasePath).readAsBytes(), original);
      },
    );
  });
}

Future<Uint8List> _makeBackup({
  required Uint8List plaintext,
  required String passphrase,
  required int schemaVersion,
  required KeyManager keyManager,
}) async {
  final random = Random.secure();
  final salt = Uint8List.fromList(
    List<int>.generate(BackupFormat.saltLength, (_) => random.nextInt(256)),
  );
  final nonce = Uint8List.fromList(
    List<int>.generate(BackupFormat.nonceLength, (_) => random.nextInt(256)),
  );
  final header = BackupHeader(
    formatVersion: BackupFormat.formatVersion,
    appVersionMajor: 0,
    appVersionMinor: 1,
    appVersionPatch: 0,
    schemaVersion: schemaVersion,
    createdAt: DateTime.now().toUtc(),
    kdfIterations: BackupFormat.kdfIterations,
    kdfMemoryKiB: BackupFormat.kdfMemoryKiB,
    kdfParallelism: BackupFormat.kdfParallelism,
    salt: salt,
    nonce: nonce,
  );
  final backupKey = await BackupCrypto.deriveBackupKey(
    passphrase: passphrase,
    salt: salt,
  );
  final keyMaterial = await keyManager.exportBackupMaterial();
  final payload = BackupPayload(
    databaseBytes: Uint8List.fromList(plaintext),
    keyMaterial: keyMaterial,
  );
  final payloadBytes = payload.toBytes();
  Uint8List? hmacKey;
  Uint8List? authenticatedData;
  try {
    final encryptedWithNonce = await BackupCrypto.encrypt(
      backupKey: backupKey,
      plaintext: payloadBytes,
      nonce: nonce,
      aadHeader: header.toBytes(),
    );
    final ciphertext = encryptedWithNonce.sublist(nonce.length);
    hmacKey = await BackupCrypto.deriveHmacKey(backupKey);
    final headerBytes = header.toBytes();
    authenticatedData = Uint8List(headerBytes.length + ciphertext.length)
      ..setRange(0, headerBytes.length, headerBytes)
      ..setRange(
        headerBytes.length,
        headerBytes.length + ciphertext.length,
        ciphertext,
      );
    final hmac = BackupCrypto.computeHmac(
      hmacKey: hmacKey,
      data: authenticatedData,
    );
    return BackupFile(
      header: header,
      ciphertext: ciphertext,
      hmac: hmac,
    ).toBytes();
  } finally {
    backupKey.fillRange(0, backupKey.length, 0);
    hmacKey?.fillRange(0, hmacKey.length, 0);
    authenticatedData?.fillRange(0, authenticatedData.length, 0);
    payload.clear();
    payloadBytes.fillRange(0, payloadBytes.length, 0);
  }
}

Future<KeyManager> _createKeyManager(String passphrase) async {
  final secureStorage = _MockSecureStorage();
  final values = <String, String>{};
  when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((
    invocation,
  ) async {
    final key = invocation.namedArguments[#key] as String;
    return values[key];
  });
  when(
    () => secureStorage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    final value = invocation.namedArguments[#value] as String;
    values[key] = value;
  });
  when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((
    invocation,
  ) async {
    final key = invocation.namedArguments[#key] as String;
    values.remove(key);
  });
  final manager = KeyManager(secureStorage: secureStorage);
  await manager.setup(passphrase: passphrase);
  return manager;
}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}
