/// Owns the encrypted database connection lifecycle.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Provides controlled access to the SQLCipher database.
class InsurDatabase {
  /// Opens the encrypted database using [encryptionKey].
  Future<void> open({required Uint8List encryptionKey}) async {
    throw UnimplementedError();
  }

  /// Closes the database and releases its resources.
  Future<void> close() async {
    throw UnimplementedError();
  }
}
