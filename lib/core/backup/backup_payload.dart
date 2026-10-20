import 'dart:convert';
import 'dart:typed_data';

import '../security/key_backup_material.dart';
import 'backup_exception.dart';

/// Authenticated inner payload containing the SQLCipher file and vault state.
///
/// The inner state is encrypted by the outer backup envelope. It contains no
/// login passphrase or plaintext recovery key. Version 3 stores the wrapped
/// master-key credential; versions 1 and 2 remain readable as legacy state.
class BackupPayload {
  /// Creates a payload from owned database bytes and key material.
  BackupPayload({required this.databaseBytes, required this.keyMaterial});

  static const List<int> _legacyMagic = <int>[
    0x53,
    0x49,
    0x50,
    0x4d,
    0x2d,
    0x50,
    0x59,
    0x31,
  ];
  static const List<int> _v2Magic = <int>[
    0x53,
    0x49,
    0x50,
    0x4d,
    0x2d,
    0x50,
    0x59,
    0x32,
  ];
  static const List<int> _v3Magic = <int>[
    0x53,
    0x49,
    0x50,
    0x4d,
    0x2d,
    0x50,
    0x59,
    0x33,
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
    final isWrappedCredential = keyMaterial.hasWrappedPassphraseCredential;
    final credentialLength = isWrappedCredential
        ? 2 + keyMaterial.wrappedPassphraseCredential!.length
        : keyMaterial.passphraseVerifier!.length;
    final magic = isWrappedCredential ? _v3Magic : _v2Magic;
    final totalLength =
        magic.length +
        32 +
        32 +
        credentialLength +
        2 +
        parameters.length +
        1 +
        recoveryLength +
        8 +
        databaseBytes.length;
    final bytes = Uint8List(totalLength);
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    bytes.setRange(offset, offset + magic.length, magic);
    offset += magic.length;
    bytes.setRange(offset, offset + 32, keyMaterial.masterKey);
    offset += 32;
    bytes.setRange(offset, offset + 32, keyMaterial.masterSalt);
    offset += 32;
    if (isWrappedCredential) {
      final wrappedCredential = keyMaterial.wrappedPassphraseCredential!;
      data.setUint16(offset, wrappedCredential.length);
      offset += 2;
      bytes.setRange(
        offset,
        offset + wrappedCredential.length,
        wrappedCredential,
      );
      offset += wrappedCredential.length;
    } else {
      bytes.setRange(
        offset,
        offset + keyMaterial.passphraseVerifier!.length,
        keyMaterial.passphraseVerifier!,
      );
      offset += keyMaterial.passphraseVerifier!.length;
    }
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
    final isLegacy = _matchesMagic(bytes, _legacyMagic);
    final isV2 = _matchesMagic(bytes, _v2Magic);
    final isV3 = _matchesMagic(bytes, _v3Magic);
    if (!isLegacy && !isV2 && !isV3) {
      throw const BackupFormatException('Backup payload magic is invalid');
    }
    final data = ByteData.sublistView(bytes);
    Uint8List? masterKey;
    Uint8List? masterSalt;
    Uint8List? passphraseVerifier;
    Uint8List? wrappedPassphraseCredential;
    Uint8List? recoverySalt;
    Uint8List? recoveryWrappedMasterKey;
    Uint8List? recoveryVerificationHash;
    Uint8List? databasePayload;
    KeyBackupMaterial? material;
    try {
      var offset = _legacyMagic.length;
      masterKey = _readBytes(bytes, offset, 32);
      offset += 32;
      masterSalt = _readBytes(bytes, offset, 32);
      offset += 32;
      if (isV3) {
        _requireRemaining(bytes, offset, 2);
        final credentialLength = data.getUint16(offset);
        offset += 2;
        if (credentialLength != 92) {
          throw const BackupFormatException(
            'Backup passphrase credential is invalid',
          );
        }
        wrappedPassphraseCredential = _readBytes(
          bytes,
          offset,
          credentialLength,
        );
        offset += credentialLength;
      } else if (isV2) {
        _requireRemaining(bytes, offset, 32);
        passphraseVerifier = _readBytes(bytes, offset, 32);
        offset += 32;
      } else {
        passphraseVerifier = Uint8List.fromList(masterKey);
      }
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
        passphraseVerifier: passphraseVerifier,
        wrappedPassphraseCredential: wrappedPassphraseCredential,
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
      passphraseVerifier?.fillRange(0, passphraseVerifier.length, 0);
      wrappedPassphraseCredential?.fillRange(
        0,
        wrappedPassphraseCredential.length,
        0,
      );
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

  static bool _matchesMagic(Uint8List bytes, List<int> magic) {
    if (bytes.length < magic.length) {
      return false;
    }
    for (var index = 0; index < magic.length; index++) {
      if (bytes[index] != magic[index]) {
        return false;
      }
    }
    return true;
  }

  static void _requireRemaining(Uint8List bytes, int offset, int length) {
    if (length < 0 || offset < 0 || offset > bytes.length - length) {
      throw const BackupFormatException('Backup payload is truncated');
    }
  }

  static void _validateMaterial(KeyBackupMaterial material) {
    final validPassphraseCredential = material.hasWrappedPassphraseCredential
        ? material.masterSalt.length == 32 &&
              material.wrappedPassphraseCredential!.length == 92
        : material.passphraseVerifier?.length == 32;
    if (material.masterKey.length != 32 ||
        material.masterSalt.length != 32 ||
        !validPassphraseCredential ||
        material.kdfParameters.isEmpty) {
      throw const BackupFormatException('Backup key material is invalid');
    }
    if (material.hasWrappedPassphraseCredential) {
      for (var index = 0; index < material.masterSalt.length; index++) {
        if (material.masterSalt[index] !=
            material.wrappedPassphraseCredential![index]) {
          throw const BackupFormatException(
            'Backup passphrase credential is invalid',
          );
        }
      }
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
