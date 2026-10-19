import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/backup/backup_exception.dart';
import 'package:insur/core/backup/backup_format.dart';
import 'package:insur/core/backup/backup_header.dart';

void main() {
  group('BackupHeader — round trip', () {
    test('preserves every field', () {
      final source = _header();

      final result = BackupHeader.fromBytes(source.toBytes());

      expect(result.formatVersion, source.formatVersion);
      expect(result.appVersionMajor, source.appVersionMajor);
      expect(result.appVersionMinor, source.appVersionMinor);
      expect(result.appVersionPatch, source.appVersionPatch);
      expect(result.schemaVersion, source.schemaVersion);
      expect(result.createdAt, source.createdAt);
      expect(result.kdfIterations, source.kdfIterations);
      expect(result.kdfMemoryKiB, source.kdfMemoryKiB);
      expect(result.kdfParallelism, source.kdfParallelism);
      expect(result.salt, source.salt);
      expect(result.nonce, source.nonce);
    });

    test('reports a semantic app version', () {
      expect(_header().appVersionString, '1.2.3');
    });

    test('uses the specified 92-byte encoding', () {
      final bytes = _header().toBytes();

      expect(bytes.length, BackupFormat.headerSize);
      expect(bytes.take(BackupFormat.magic.length), BackupFormat.magic);
      expect(ByteData.sublistView(bytes).getUint32(8), 1);
    });

    test('toString excludes salt and nonce', () {
      final header = _header();

      expect(header.toString(), contains('1.2.3'));
      expect(header.toString(), isNot(contains('090909')));
    });
  });

  group('BackupHeader — validation', () {
    test('rejects a short header', () {
      expect(
        () => BackupHeader.fromBytes(Uint8List(BackupFormat.headerSize - 1)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a long header', () {
      expect(
        () => BackupHeader.fromBytes(Uint8List(BackupFormat.headerSize + 1)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects incorrect magic', () {
      final bytes = _header().toBytes()..[0] = 0;

      expect(
        () => BackupHeader.fromBytes(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects an unsupported format version', () {
      final bytes = _header().toBytes();
      ByteData.sublistView(bytes).setUint32(8, 2);

      expect(
        () => BackupHeader.fromBytes(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}

BackupHeader _header() {
  return BackupHeader(
    formatVersion: BackupFormat.formatVersion,
    appVersionMajor: 1,
    appVersionMinor: 2,
    appVersionPatch: 3,
    schemaVersion: 2,
    createdAt: DateTime.utc(2026, 10, 19, 8, 30),
    kdfIterations: BackupFormat.kdfIterations,
    kdfMemoryKiB: BackupFormat.kdfMemoryKiB,
    kdfParallelism: BackupFormat.kdfParallelism,
    salt: Uint8List.fromList(List<int>.filled(BackupFormat.saltLength, 9)),
    nonce: Uint8List.fromList(List<int>.filled(BackupFormat.nonceLength, 7)),
  );
}
