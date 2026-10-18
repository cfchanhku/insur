/// Defines operations for encrypted local backup and restore workflows.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

import '../../../features/backup/models/backup_record.dart';

/// Coordinates access to backup metadata and encrypted backup bytes.
class BackupRepository {
  /// Returns metadata for available backups.
  Future<List<BackupRecord>> findAll() async {
    throw UnimplementedError('BackupRepository.findAll');
  }

  /// Creates an encrypted backup and returns its metadata.
  Future<BackupRecord> create(Uint8List encryptionKey) async {
    throw UnimplementedError('BackupRepository.create');
  }

  /// Restores the backup identified by [id] after integrity verification.
  Future<void> restore({
    required String id,
    required Uint8List encryptionKey,
  }) async {
    throw UnimplementedError('BackupRepository.restore');
  }
}
