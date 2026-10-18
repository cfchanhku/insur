/// Validates and restores encrypted application backups.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Restores a backup only after integrity and compatibility checks succeed.
class RestoreService {
  /// Validates and restores [backupBytes] with [encryptionKey].
  Future<void> restoreBackup({
    required Uint8List backupBytes,
    required Uint8List encryptionKey,
  }) async {
    throw UnimplementedError();
  }
}
