import 'dart:convert';

/// Constants and filename helpers for the authenticated backup format.
///
/// The 92-byte plaintext header uses big-endian integers so it has an
/// unambiguous byte representation across platforms. It is authenticated by
/// both the GCM additional data and the trailing HMAC.
class BackupFormat {
  const BackupFormat._();

  /// ASCII magic bytes identifying an Insur backup.
  static const List<int> magic = <int>[
    0x53,
    0x49,
    0x50,
    0x4d,
    0x2d,
    0x42,
    0x4b,
    0x31,
  ];

  /// Current on-disk backup format version.
  static const int formatVersion = 1;

  /// Number of salt bytes used by Argon2id.
  static const int saltLength = 32;

  /// Number of nonce bytes used by AES-256-GCM.
  static const int nonceLength = 12;

  /// Number of authentication-tag bytes appended by AES-256-GCM.
  static const int tagLength = 16;

  /// Number of trailing HMAC-SHA256 bytes.
  static const int hmacLength = 32;

  /// Argon2id iteration count recorded in each header.
  static const int kdfIterations = 3;

  /// Argon2id memory cost in KiB recorded in each header.
  static const int kdfMemoryKiB = 65536;

  /// Argon2id parallelism recorded in each header.
  static const int kdfParallelism = 4;

  /// AES key length in bytes.
  static const int keyLength = 32;

  /// Backup file extension, including the dot.
  static const String fileExtension = '.enc';

  /// Prefix used for generated backup filenames.
  static const String filePrefix = 'backup_';

  /// Exact size of the fixed-format binary header.
  ///
  /// Offsets: magic 0-7; format version 8-11; app version 12-23; schema
  /// version 24-27; creation time 28-35; Argon2id parameters 36-47; salt
  /// 48-79; nonce 80-91.
  static const int headerSize = 92;

  /// Returns a timestamped backup filename using UTC calendar fields.
  static String generateFileName({
    required DateTime timestamp,
    required int schemaVersion,
    required String appVersion,
  }) {
    if (schemaVersion < 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    final utc = timestamp.toUtc();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final date =
        '${utc.year.toString().padLeft(4, '0')}'
        '${twoDigits(utc.month)}${twoDigits(utc.day)}_'
        '${twoDigits(utc.hour)}${twoDigits(utc.minute)}'
        '${twoDigits(utc.second)}';
    return '$filePrefix${date}_v${appVersion}_s$schemaVersion$fileExtension';
  }

  /// Decodes the fixed ASCII magic bytes as a convenience for diagnostics.
  static String get magicText => ascii.decode(magic);
}
