/// Describes a user-approved local data export request.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Options and scope for generating a PDF export.
class ExportRequest {
  /// Creates an export request.
  const ExportRequest({
    required this.policyId,
    required this.includeSensitiveFields,
  });

  /// UUID of the policy to export.
  final String policyId;

  /// Whether full sensitive identifiers may be included.
  final bool includeSensitiveFields;
}
