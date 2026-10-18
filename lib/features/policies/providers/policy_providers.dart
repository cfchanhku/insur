/// Declares providers for policy data and operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/policy_repository.dart';

/// Provides the policy repository.
final Provider<PolicyRepository> policyRepositoryProvider =
    Provider<PolicyRepository>((ref) {
  throw UnimplementedError('policyRepositoryProvider');
});
