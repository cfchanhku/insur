/// Creates authenticated encrypted backups of local application data.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Creates an encrypted backup from database bytes.
class BackupService {
  /// Encrypts [databaseBytes] with AES-256-GCM using [encryptionKey].
  Future<Uint8List> createBackup({
    required Uint8List databaseBytes,
    required Uint8List encryptionKey,
  }) async {
    throw UnimplementedError();
  }
}
