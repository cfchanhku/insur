/// Defines persistence operations for plan riders.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/riders/models/rider.dart';

/// Reads and writes rider records through the encrypted database.
class RiderRepository {
  /// Returns riders associated with [planId].
  Future<List<Rider>> findByPlanId(String planId) async {
    throw UnimplementedError('RiderRepository.findByPlanId');
  }

  /// Persists a new or updated rider.
  Future<void> save(Rider rider) async {
    throw UnimplementedError('RiderRepository.save');
  }

  /// Archives a rider without physically deleting its record.
  Future<void> archive(String id) async {
    throw UnimplementedError('RiderRepository.archive');
  }
}
