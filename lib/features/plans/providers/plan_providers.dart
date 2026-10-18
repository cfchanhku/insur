/// Declares providers for plan data and operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/plan_repository.dart';

/// Provides the plan repository.
final Provider<PlanRepository> planRepositoryProvider =
    Provider<PlanRepository>((ref) {
  throw UnimplementedError('planRepositoryProvider');
});
