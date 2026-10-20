import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/backup/backup_payload.dart';
import 'package:insur/core/security/key_backup_material.dart';

void main() {
  test('round-trips a separate passphrase verifier', () {
    final material = KeyBackupMaterial(
      masterKey: Uint8List.fromList(List<int>.filled(32, 1)),
      masterSalt: Uint8List.fromList(List<int>.filled(32, 2)),
      passphraseVerifier: Uint8List.fromList(List<int>.filled(32, 3)),
      kdfParameters: 'Argon2id test parameters',
    );
    final payload = BackupPayload(
      databaseBytes: Uint8List.fromList(<int>[4, 5, 6]),
      keyMaterial: material,
    );
    final encoded = payload.toBytes();
    final decoded = BackupPayload.fromBytes(encoded);

    expect(decoded.keyMaterial.passphraseVerifier, List<int>.filled(32, 3));
    expect(decoded.keyMaterial.masterKey, List<int>.filled(32, 1));
    expect(decoded.databaseBytes, <int>[4, 5, 6]);

    decoded.clear();
    payload.clear();
  });

  test('reads legacy payloads using the master key as the verifier', () {
    final legacy = _legacyPayload();
    final payload = BackupPayload.fromBytes(legacy);

    expect(payload.keyMaterial.masterKey, List<int>.filled(32, 7));
    expect(payload.keyMaterial.passphraseVerifier, List<int>.filled(32, 7));
    expect(payload.databaseBytes, <int>[8, 9]);

    payload.clear();
    legacy.fillRange(0, legacy.length, 0);
  });
}

Uint8List _legacyPayload() {
  const magic = <int>[0x53, 0x49, 0x50, 0x4d, 0x2d, 0x50, 0x59, 0x31];
  final parameters = utf8.encode('Argon2id test parameters');
  final bytes = Uint8List(
    magic.length + 32 + 32 + 2 + parameters.length + 1 + 8 + 2,
  );
  final data = ByteData.sublistView(bytes);
  var offset = 0;
  bytes.setRange(offset, offset + magic.length, magic);
  offset += magic.length;
  bytes.setRange(offset, offset + 32, List<int>.filled(32, 7));
  offset += 32;
  bytes.setRange(offset, offset + 32, List<int>.filled(32, 6));
  offset += 32;
  data.setUint16(offset, parameters.length);
  offset += 2;
  bytes.setRange(offset, offset + parameters.length, parameters);
  offset += parameters.length;
  bytes[offset] = 0;
  offset++;
  data.setUint64(offset, 2);
  offset += 8;
  bytes.setRange(offset, bytes.length, <int>[8, 9]);
  return bytes;
}
