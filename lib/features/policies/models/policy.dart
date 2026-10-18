/// Defines a locally stored insurance policy record.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Insurance policy associated with a client.
class Policy {
  /// Creates a policy record.
  const Policy({
    required this.id,
    required this.clientId,
    required this.policyNumber,
  });

  /// UUID identifying this policy.
  final String id;

  /// UUID of the associated client.
  final String clientId;

  /// Sensitive policy identifier; never log this value.
  final String policyNumber;
}
