/// Owns the encrypted database connection lifecycle.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Provides controlled access to the SQLCipher database.
class InsurDatabase {
  /// Opens the encrypted database using [encryptionKey].
  ///
  /// The configured SQLCipher implementation must fail closed if encryption
  /// cannot be enabled or the key is rejected.
  Future<void> open({required Uint8List encryptionKey}) async {
    throw UnimplementedError('InsurDatabase.open');
  }

  /// Executes a write statement with bound [parameters].
  Future<int> execute(
    String sql, {
    List<Object?> parameters = const <Object?>[],
  }) async {
    throw UnimplementedError('InsurDatabase.execute');
  }

  /// Queries rows using bound [parameters].
  Future<List<Map<String, Object?>>> query(
    String sql, {
    List<Object?> parameters = const <Object?>[],
  }) async {
    throw UnimplementedError('InsurDatabase.query');
  }

  /// Closes the database and releases its resources.
  Future<void> close() async {
    throw UnimplementedError('InsurDatabase.close');
  }
}
