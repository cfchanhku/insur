/// Describes whether persisted audit entries form a valid hash chain.
class VerificationResult {
  /// Creates a verification result.
  const VerificationResult({
    required this.isValid,
    this.brokenAt,
    this.reason,
    this.entryCount,
  });

  /// Creates a successful verification result.
  const VerificationResult.valid({int? entryCount})
    : this(isValid: true, entryCount: entryCount);

  /// Creates a failed verification result.
  const VerificationResult.broken({
    required int brokenAt,
    required String reason,
  }) : this(isValid: false, brokenAt: brokenAt, reason: reason);

  /// Whether all verified entries have valid hashes and links.
  final bool isValid;

  /// Zero-based position of the first detected invalid entry.
  final int? brokenAt;

  /// Safe explanation of the verification failure, without entry contents.
  final String? reason;

  /// Number of entries verified when verification succeeds.
  final int? entryCount;

  @override
  String toString() {
    if (isValid) {
      return 'VerificationResult(valid, entryCount: $entryCount)';
    }
    return 'VerificationResult(invalid, brokenAt: $brokenAt, reason: $reason)';
  }
}
