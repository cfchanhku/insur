/// Defines an optional rider attached to an insurance plan.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Additional coverage associated with a plan.
class Rider {
  /// Creates a rider record.
  const Rider({
    required this.id,
    required this.planId,
    required this.name,
  });

  /// UUID identifying this rider.
  final String id;

  /// UUID of the parent plan.
  final String planId;

  /// Display name of the rider.
  final String name;
}
