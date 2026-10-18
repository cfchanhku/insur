/// Generates and validates offline vault recovery keys.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Provides recovery-key lifecycle operations.
class RecoveryKeyService {
  /// Securely generates a new recovery key.
  Future<String> generate() async {
    throw UnimplementedError('RecoveryKeyService.generate');
  }

  /// Verifies whether [candidate] is valid for the configured vault.
  Future<bool> verify(String candidate) async {
    throw UnimplementedError('RecoveryKeyService.verify');
  }

  /// Rotates the current recovery key after validating [currentKey].
  Future<String> rotate({required String currentKey}) async {
    throw UnimplementedError('RecoveryKeyService.rotate');
  }
}
