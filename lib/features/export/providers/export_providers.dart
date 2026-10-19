/// Declares providers for local PDF export operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/export_repository.dart';

/// Provides the export repository.
final Provider<ExportRepository> exportRepositoryProvider =
    Provider<ExportRepository>((ref) {
      throw UnimplementedError('exportRepositoryProvider');
    });
