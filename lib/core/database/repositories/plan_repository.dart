/// Defines persistence operations for policy plans.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/plans/models/plan.dart';

/// Reads and writes plan records through the encrypted database.
class PlanRepository {
  /// Returns plans associated with [policyId].
  Future<List<Plan>> findByPolicyId(String policyId) async {
    throw UnimplementedError('PlanRepository.findByPolicyId');
  }

  /// Persists a new or updated plan.
  Future<void> save(Plan plan) async {
    throw UnimplementedError('PlanRepository.save');
  }

  /// Archives a plan without physically deleting its record.
  Future<void> archive(String id) async {
    throw UnimplementedError('PlanRepository.archive');
  }
}
