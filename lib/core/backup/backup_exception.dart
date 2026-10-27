/// Base exception for backup operations.
///
/// Messages must never include passphrases or key material.
class BackupException implements Exception {
  /// Creates a backup error with a safe, non-secret [message].
  const BackupException(this.message);

  /// A safe description that does not contain credentials or key material.
  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// Thrown when a backup file is malformed or has an unsupported encoding.
class BackupFormatException extends BackupException {
  /// Creates a malformed-file error with a safe [message].
  const BackupFormatException(super.message);
}

/// Thrown when a backup passphrase is incorrect or authentication fails.
class BackupAuthenticationException extends BackupException {
  /// Creates an authentication error with a safe [message].
  const BackupAuthenticationException(super.message);
}

/// Thrown when a backup requires an unsupported application or schema version.
class BackupVersionException extends BackupException {
  /// Creates a version compatibility error with a safe [message].
  const BackupVersionException(super.message);
}

/// Thrown when a backup file operation fails.
class BackupIoException extends BackupException {
  /// Creates a file I/O error with a safe [message].
  const BackupIoException(super.message, {this.platformCode});

  /// A stable platform error code, when the failure came from a platform API.
  final String? platformCode;
}
