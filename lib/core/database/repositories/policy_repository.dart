/// Defines persistence operations for insurance policies.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/policies/models/policy.dart';

/// Reads and writes policy records through the encrypted database.
class PolicyRepository {
  /// Returns active policies associated with [clientId].
  Future<List<Policy>> findByClientId(String clientId) async {
    throw UnimplementedError('PolicyRepository.findByClientId');
  }

  /// Finds a policy by UUID.
  Future<Policy?> findById(String id) async {
    throw UnimplementedError('PolicyRepository.findById');
  }

  /// Persists a new or updated policy.
  Future<void> save(Policy policy) async {
    throw UnimplementedError('PolicyRepository.save');
  }

  /// Archives a policy without physically deleting its record.
  Future<void> archive(String id) async {
    throw UnimplementedError('PolicyRepository.archive');
  }
}
