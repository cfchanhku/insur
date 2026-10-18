/// Declares providers for audit history and verification.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/audit_repository.dart';

/// Provides the audit repository.
final Provider<AuditRepository> auditRepositoryProvider =
    Provider<AuditRepository>((ref) {
  throw UnimplementedError('auditRepositoryProvider');
});
