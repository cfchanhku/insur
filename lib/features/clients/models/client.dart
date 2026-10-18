/// Defines a locally stored client record.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Client who is a policy holder or insured person.
class Client {
  /// Creates a client record.
  const Client({required this.id, required this.displayName});

  /// UUID identifying this client.
  final String id;

  /// Name shown in the user interface.
  final String displayName;
}
