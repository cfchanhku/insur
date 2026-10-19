/// Declares providers for local backup and restore operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/backup_repository.dart';

/// Provides the backup repository.
final Provider<BackupRepository> backupRepositoryProvider =
    Provider<BackupRepository>((ref) {
      throw UnimplementedError('backupRepositoryProvider');
    });
