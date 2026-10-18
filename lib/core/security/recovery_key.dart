/// Generates and validates offline vault recovery keys.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Provides recovery-key lifecycle operations.
class RecoveryKeyService {
  /// Securely generates a new recovery key.
  Future<String> generate() async {
    throw UnimplementedError();
  }

  /// Verifies whether [candidate] is valid for the configured vault.
  Future<bool> verify(String candidate) async {
    throw UnimplementedError();
  }
}
