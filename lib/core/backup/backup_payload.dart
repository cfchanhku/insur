import 'dart:convert';
import 'dart:typed_data';

import '../security/key_backup_material.dart';
import 'backup_exception.dart';

/// Authenticated inner payload containing the SQLCipher file and vault state.
///
/// The inner state is encrypted by the outer backup envelope. It contains no
/// login passphrase or plaintext recovery key.
class BackupPayload {
  /// Creates a payload from owned database bytes and key material.
  BackupPayload({required this.databaseBytes, required this.keyMaterial});

  static const List<int> _magic = <int>[
    0x53,
    0x49,
    0x50,
    0x4d,
    0x2d,
    0x50,
    0x59,
    0x31,
  ];

  /// SQLCipher database file bytes.
  final Uint8List databaseBytes;

  /// Master-key and recovery-key secure-storage state for portable restore.
  final KeyBackupMaterial keyMaterial;

  /// Serializes all key material and the database into the encrypted payload.
  Uint8List toBytes() {
    _validateMaterial(keyMaterial);
    final parameters = Uint8List.fromList(
      utf8.encode(keyMaterial.kdfParameters),
    );
    if (parameters.length > 0xffff) {
      throw const BackupFormatException('Backup key metadata is too large');
    }
    final recoveryLength = keyMaterial.hasRecoveryKey
        ? 32 + 2 + keyMaterial.recoveryWrappedMasterKey!.length + 32
        : 0;
    final totalLength =
        _magic.length +
        32 +
        32 +
        2 +
        parameters.length +
        1 +
        recoveryLength +
        8 +
        databaseBytes.length;
    final bytes = Uint8List(totalLength);
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    bytes.setRange(offset, offset + _magic.length, _magic);
    offset += _magic.length;
    bytes.setRange(offset, offset + 32, keyMaterial.masterKey);
    offset += 32;
    bytes.setRange(offset, offset + 32, keyMaterial.masterSalt);
    offset += 32;
    data.setUint16(offset, parameters.length);
    offset += 2;
    bytes.setRange(offset, offset + parameters.length, parameters);
    offset += parameters.length;
    bytes[offset] = keyMaterial.hasRecoveryKey ? 1 : 0;
    offset++;
    if (keyMaterial.hasRecoveryKey) {
      bytes.setRange(offset, offset + 32, keyMaterial.recoverySalt!);
      offset += 32;
      final wrappedKey = keyMaterial.recoveryWrappedMasterKey!;
      data.setUint16(offset, wrappedKey.length);
      offset += 2;
      bytes.setRange(offset, offset + wrappedKey.length, wrappedKey);
      offset += wrappedKey.length;
      bytes.setRange(
        offset,
        offset + 32,
        keyMaterial.recoveryVerificationHash!,
      );
      offset += 32;
    }
    data.setUint64(offset, databaseBytes.length);
    offset += 8;
    bytes.setRange(offset, bytes.length, databaseBytes);
    return bytes;
  }

  /// Parses a payload, rejecting malformed lengths and unsupported contents.
  factory BackupPayload.fromBytes(Uint8List bytes) {
    const fixedSize = 8 + 32 + 32 + 2 + 1 + 8;
    if (bytes.length < fixedSize) {
      throw const BackupFormatException('Backup payload is truncated');
    }
    for (var index = 0; index < _magic.length; index++) {
      if (bytes[index] != _magic[index]) {
        throw const BackupFormatException('Backup payload magic is invalid');
      }
    }
    final data = ByteData.sublistView(bytes);
    Uint8List? masterKey;
    Uint8List? masterSalt;
    Uint8List? recoverySalt;
    Uint8List? recoveryWrappedMasterKey;
    Uint8List? recoveryVerificationHash;
    Uint8List? databasePayload;
    KeyBackupMaterial? material;
    try {
      var offset = _magic.length;
      masterKey = _readBytes(bytes, offset, 32);
      offset += 32;
      masterSalt = _readBytes(bytes, offset, 32);
      offset += 32;
      final parametersLength = data.getUint16(offset);
      offset += 2;
      final parametersBytes = _readBytes(bytes, offset, parametersLength);
      offset += parametersLength;
      final String parameters;
      try {
        parameters = utf8.decode(parametersBytes);
      } on FormatException {
        throw const BackupFormatException('Backup key metadata is invalid');
      }
      _requireRemaining(bytes, offset, 1 + 8);
      final recoveryFlag = bytes[offset];
      offset++;
      if (recoveryFlag != 0 && recoveryFlag != 1) {
        throw const BackupFormatException(
          'Backup recovery metadata is invalid',
        );
      }

      if (recoveryFlag == 1) {
        recoverySalt = _readBytes(bytes, offset, 32);
        offset += 32;
        _requireRemaining(bytes, offset, 2);
        final wrappedLength = data.getUint16(offset);
        offset += 2;
        if (wrappedLength != 60) {
          throw const BackupFormatException(
            'Backup recovery metadata is invalid',
          );
        }
        recoveryWrappedMasterKey = _readBytes(bytes, offset, wrappedLength);
        offset += wrappedLength;
        recoveryVerificationHash = _readBytes(bytes, offset, 32);
        offset += 32;
      }

      _requireRemaining(bytes, offset, 8);
      final databaseLength = data.getUint64(offset);
      offset += 8;
      if (databaseLength != bytes.length - offset) {
        throw const BackupFormatException(
          'Backup database payload length is invalid',
        );
      }
      databasePayload = Uint8List.fromList(bytes.sublist(offset));
      material = KeyBackupMaterial(
        masterKey: masterKey,
        masterSalt: masterSalt,
        kdfParameters: parameters,
        recoverySalt: recoverySalt,
        recoveryWrappedMasterKey: recoveryWrappedMasterKey,
        recoveryVerificationHash: recoveryVerificationHash,
      );
      _validateMaterial(material);
      final payload = BackupPayload(
        databaseBytes: databasePayload,
        keyMaterial: material,
      );
      databasePayload = null;
      material = null;
      return payload;
    } finally {
      masterKey?.fillRange(0, masterKey.length, 0);
      masterSalt?.fillRange(0, masterSalt.length, 0);
      recoverySalt?.fillRange(0, recoverySalt.length, 0);
      recoveryWrappedMasterKey?.fillRange(
        0,
        recoveryWrappedMasterKey.length,
        0,
      );
      recoveryVerificationHash?.fillRange(
        0,
        recoveryVerificationHash.length,
        0,
      );
      databasePayload?.fillRange(0, databasePayload.length, 0);
      material?.clear();
    }
  }

  /// Clears all mutable key and database buffers held by this payload.
  void clear() {
    keyMaterial.clear();
    databaseBytes.fillRange(0, databaseBytes.length, 0);
  }

  static Uint8List _readBytes(Uint8List bytes, int offset, int length) {
    _requireRemaining(bytes, offset, length);
    return Uint8List.fromList(bytes.sublist(offset, offset + length));
  }

  static void _requireRemaining(Uint8List bytes, int offset, int length) {
    if (length < 0 || offset < 0 || offset > bytes.length - length) {
      throw const BackupFormatException('Backup payload is truncated');
    }
  }

  static void _validateMaterial(KeyBackupMaterial material) {
    if (material.masterKey.length != 32 ||
        material.masterSalt.length != 32 ||
        material.kdfParameters.isEmpty) {
      throw const BackupFormatException('Backup key material is invalid');
    }
    final recoveryFieldCount = <Uint8List?>[
      material.recoverySalt,
      material.recoveryWrappedMasterKey,
      material.recoveryVerificationHash,
    ].where((Uint8List? field) => field != null).length;
    if (recoveryFieldCount != 0 && recoveryFieldCount != 3) {
      throw const BackupFormatException('Backup recovery metadata is invalid');
    }
    if (material.hasRecoveryKey &&
        (material.recoverySalt!.length != 32 ||
            material.recoveryWrappedMasterKey!.length != 60 ||
            material.recoveryVerificationHash!.length != 32)) {
      throw const BackupFormatException('Backup recovery metadata is invalid');
    }
  }
}
