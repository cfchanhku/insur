import 'dart:typed_data';

import 'backup_exception.dart';
import 'backup_format.dart';

/// Plaintext, authenticated metadata preceding an encrypted database payload.
class BackupHeader {
  /// Creates a backup header.
  const BackupHeader({
    required this.formatVersion,
    required this.appVersionMajor,
    required this.appVersionMinor,
    required this.appVersionPatch,
    required this.schemaVersion,
    required this.createdAt,
    required this.kdfIterations,
    required this.kdfMemoryKiB,
    required this.kdfParallelism,
    required this.salt,
    required this.nonce,
  }) : assert(salt.length == BackupFormat.saltLength, 'Salt must be 32 bytes'),
       assert(
         nonce.length == BackupFormat.nonceLength,
         'Nonce must be 12 bytes',
       ),
       assert(formatVersion >= 1, 'Format version must be positive'),
       assert(schemaVersion >= 1, 'Schema version must be positive');

  /// Serialization version for the backup envelope.
  final int formatVersion;

  /// Major component of the application version.
  final int appVersionMajor;

  /// Minor component of the application version.
  final int appVersionMinor;

  /// Patch component of the application version.
  final int appVersionPatch;

  /// Database schema version represented by the encrypted payload.
  final int schemaVersion;

  /// UTC time at which the backup was created.
  final DateTime createdAt;

  /// Argon2id iteration count.
  final int kdfIterations;

  /// Argon2id memory cost in KiB.
  final int kdfMemoryKiB;

  /// Argon2id parallelism.
  final int kdfParallelism;

  /// Public random salt for backup-passphrase derivation.
  final Uint8List salt;

  /// Public random AES-GCM nonce.
  final Uint8List nonce;

  /// App version in `major.minor.patch` form.
  String get appVersionString =>
      '$appVersionMajor.$appVersionMinor.$appVersionPatch';

  /// Serializes this header using the fixed big-endian format.
  Uint8List toBytes() {
    _validateUint32(formatVersion, 'formatVersion');
    _validateUint32(appVersionMajor, 'appVersionMajor');
    _validateUint32(appVersionMinor, 'appVersionMinor');
    _validateUint32(appVersionPatch, 'appVersionPatch');
    _validateUint32(schemaVersion, 'schemaVersion');
    _validateUint32(kdfIterations, 'kdfIterations');
    _validateUint32(kdfMemoryKiB, 'kdfMemoryKiB');
    _validateUint32(kdfParallelism, 'kdfParallelism');
    if (salt.length != BackupFormat.saltLength ||
        nonce.length != BackupFormat.nonceLength) {
      throw const BackupFormatException('Backup header has invalid fields');
    }
    if (!createdAt.isUtc) {
      throw ArgumentError.value(createdAt, 'createdAt', 'Must be UTC');
    }

    final bytes = Uint8List(BackupFormat.headerSize)
      ..setRange(0, BackupFormat.magic.length, BackupFormat.magic)
      ..setRange(48, 80, salt)
      ..setRange(80, 92, nonce);
    ByteData.sublistView(bytes)
      ..setUint32(8, formatVersion)
      ..setUint32(12, appVersionMajor)
      ..setUint32(16, appVersionMinor)
      ..setUint32(20, appVersionPatch)
      ..setUint32(24, schemaVersion)
      ..setInt64(28, createdAt.millisecondsSinceEpoch)
      ..setUint32(36, kdfIterations)
      ..setUint32(40, kdfMemoryKiB)
      ..setUint32(44, kdfParallelism);
    return bytes;
  }

  /// Parses and validates the fixed-size header.
  factory BackupHeader.fromBytes(Uint8List bytes) {
    if (bytes.length != BackupFormat.headerSize) {
      throw const BackupFormatException('Backup header length is invalid');
    }
    for (var index = 0; index < BackupFormat.magic.length; index++) {
      if (bytes[index] != BackupFormat.magic[index]) {
        throw const BackupFormatException('Backup file magic is invalid');
      }
    }
    final data = ByteData.sublistView(bytes);
    final version = data.getUint32(8);
    if (version != BackupFormat.formatVersion) {
      throw const BackupFormatException('Backup format version is unsupported');
    }
    final schemaVersion = data.getUint32(24);
    if (schemaVersion < 1) {
      throw const BackupFormatException('Backup schema version is invalid');
    }
    return BackupHeader(
      formatVersion: version,
      appVersionMajor: data.getUint32(12),
      appVersionMinor: data.getUint32(16),
      appVersionPatch: data.getUint32(20),
      schemaVersion: schemaVersion,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data.getInt64(28),
        isUtc: true,
      ),
      kdfIterations: data.getUint32(36),
      kdfMemoryKiB: data.getUint32(40),
      kdfParallelism: data.getUint32(44),
      salt: Uint8List.fromList(bytes.sublist(48, 80)),
      nonce: Uint8List.fromList(bytes.sublist(80, 92)),
    );
  }

  @override
  String toString() =>
      'BackupHeader(format: $formatVersion, app: $appVersionString, '
      'schema: $schemaVersion, createdAt: $createdAt)';

  static void _validateUint32(int value, String name) {
    if (value < 0 || value > 0xffffffff) {
      throw ArgumentError.value(value, name, 'Must fit an unsigned 32-bit int');
    }
  }
}
