import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/backup/backup_exception.dart';
import 'package:insur/core/backup/backup_file.dart';
import 'package:insur/core/backup/backup_format.dart';
import 'package:insur/core/backup/backup_header.dart';

void main() {
  group('BackupFile — round trip', () {
    test('serializes and parses header, ciphertext, and HMAC', () {
      final source = _backupFile();

      final result = BackupFile.fromBytes(source.toBytes());

      expect(result.header.appVersionString, source.header.appVersionString);
      expect(result.header.schemaVersion, source.header.schemaVersion);
      expect(result.ciphertext, source.ciphertext);
      expect(result.hmac, source.hmac);
      expect(result.totalSize, source.totalSize);
    });

    test('total size includes header, payload, and HMAC', () {
      expect(
        _backupFile().totalSize,
        BackupFormat.headerSize + 20 + BackupFormat.hmacLength,
      );
    });
  });

  group('BackupFile — truncated input', () {
    test('rejects a file shorter than its fixed header', () {
      expect(
        () => BackupFile.fromBytes(Uint8List(BackupFormat.headerSize - 1)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a file without an AES-GCM tag', () {
      expect(
        () => BackupFile.fromBytes(
          Uint8List(BackupFormat.headerSize + BackupFormat.hmacLength),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a file missing part of its HMAC', () {
      expect(
        () => BackupFile.fromBytes(
          Uint8List(
            BackupFormat.headerSize +
                BackupFormat.tagLength +
                BackupFormat.hmacLength -
                1,
          ),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}

BackupFile _backupFile() {
  final header = BackupHeader(
    formatVersion: BackupFormat.formatVersion,
    appVersionMajor: 1,
    appVersionMinor: 0,
    appVersionPatch: 0,
    schemaVersion: 2,
    createdAt: DateTime.utc(2026, 10, 19),
    kdfIterations: BackupFormat.kdfIterations,
    kdfMemoryKiB: BackupFormat.kdfMemoryKiB,
    kdfParallelism: BackupFormat.kdfParallelism,
    salt: Uint8List(BackupFormat.saltLength),
    nonce: Uint8List(BackupFormat.nonceLength),
  );
  return BackupFile(
    header: header,
    ciphertext: Uint8List(20),
    hmac: Uint8List(BackupFormat.hmacLength),
  );
}
