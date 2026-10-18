/// Defines a plan attached to an insurance policy.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Supported plan categories.
enum PlanCategory { life, criticalIllness, hospital, accident, savings, other }

/// Insurance plan belonging to a policy.
class Plan {
  /// Creates a plan record.
  const Plan({
    required this.id,
    required this.policyId,
    required this.category,
    required this.name,
  });

  /// UUID identifying this plan.
  final String id;

  /// UUID of the parent policy.
  final String policyId;

  /// Category used to determine plan-specific fields.
  final PlanCategory category;

  /// Display name of the plan.
  final String name;
}
