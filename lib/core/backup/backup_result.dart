import 'backup_header.dart';

/// Outcome of writing an encrypted backup file.
class BackupResult {
  /// Creates a backup result.
  const BackupResult({
    this.success = false,
    this.path = '',
    this.sizeBytes = 0,
    this.createdAt,
  });

  /// Whether the backup was written successfully.
  final bool success;

  /// Destination path, empty when no file was written.
  final String path;

  /// Serialized backup size.
  final int sizeBytes;

  /// Creation time from the authenticated header, if successful.
  final DateTime? createdAt;

  @override
  String toString() =>
      'BackupResult(success: $success, sizeBytes: $sizeBytes, '
      'createdAt: $createdAt)';
}

/// Outcome of replacing the local database with a backup payload.
class RestoreResult {
  /// Creates a restore result.
  const RestoreResult({
    this.success = false,
    this.restoredFrom = '',
    this.schemaVersion = 0,
    this.preRestoreBackupPath = '',
  });

  /// Whether the encrypted payload was installed successfully.
  final bool success;

  /// Source backup path.
  final String restoredFrom;

  /// Schema version declared by the restored backup.
  final int schemaVersion;

  /// Path of the recovery backup made before replacement.
  final String preRestoreBackupPath;

  @override
  String toString() =>
      'RestoreResult(success: $success, schemaVersion: $schemaVersion)';
}

/// Result of checking a backup without modifying local files.
class VerificationResult {
  /// Creates a verification result.
  const VerificationResult({required this.isValid, this.header, this.reason});

  /// Whether format, HMAC, and authenticated decryption checks succeeded.
  final bool isValid;

  /// Parsed backup metadata when parsing succeeded.
  final BackupHeader? header;

  /// Safe reason for failure, without credentials or file contents.
  final String? reason;
}
