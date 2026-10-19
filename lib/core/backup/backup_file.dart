import 'dart:typed_data';

import 'backup_exception.dart';
import 'backup_format.dart';
import 'backup_header.dart';

/// A serialized backup header, AES-GCM ciphertext/tag, and HMAC.
class BackupFile {
  /// Creates a backup envelope.
  const BackupFile({
    required this.header,
    required this.ciphertext,
    required this.hmac,
  }) : assert(
         ciphertext.length >= BackupFormat.tagLength,
         'Ciphertext must include the GCM tag',
       ),
       assert(hmac.length == BackupFormat.hmacLength, 'HMAC must be 32 bytes');

  /// Plaintext metadata authenticated by GCM AAD and HMAC.
  final BackupHeader header;

  /// AES-GCM ciphertext followed by its 16-byte tag.
  final Uint8List ciphertext;

  /// HMAC-SHA256 over the serialized header and [ciphertext].
  final Uint8List hmac;

  /// Total serialized size in bytes.
  int get totalSize =>
      BackupFormat.headerSize + ciphertext.length + BackupFormat.hmacLength;

  /// Concatenates header, ciphertext/tag, and HMAC.
  Uint8List toBytes() {
    if (ciphertext.length < BackupFormat.tagLength ||
        hmac.length != BackupFormat.hmacLength) {
      throw const BackupFormatException('Backup payload length is invalid');
    }
    final bytes = Uint8List(totalSize)
      ..setRange(0, BackupFormat.headerSize, header.toBytes())
      ..setRange(
        BackupFormat.headerSize,
        BackupFormat.headerSize + ciphertext.length,
        ciphertext,
      )
      ..setRange(BackupFormat.headerSize + ciphertext.length, totalSize, hmac);
    return bytes;
  }

  /// Parses a backup envelope, rejecting truncated payloads.
  factory BackupFile.fromBytes(Uint8List bytes) {
    const minimumSize =
        BackupFormat.headerSize +
        BackupFormat.tagLength +
        BackupFormat.hmacLength;
    if (bytes.length < minimumSize) {
      throw const BackupFormatException('Backup file is truncated');
    }
    final header = BackupHeader.fromBytes(
      Uint8List.sublistView(bytes, 0, BackupFormat.headerSize),
    );
    final ciphertextEnd = bytes.length - BackupFormat.hmacLength;
    if (ciphertextEnd < BackupFormat.headerSize + BackupFormat.tagLength) {
      throw const BackupFormatException('Backup ciphertext is truncated');
    }
    return BackupFile(
      header: header,
      ciphertext: Uint8List.fromList(
        bytes.sublist(BackupFormat.headerSize, ciphertextEnd),
      ),
      hmac: Uint8List.fromList(bytes.sublist(ciphertextEnd)),
    );
  }
}
