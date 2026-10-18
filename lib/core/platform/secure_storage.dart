/// Defines secure platform storage for protected cryptographic key material.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Stores and retrieves sensitive bytes through an operating-system facility.
class PlatformSecureStorage {
  /// Reads the value associated with [key], or returns null when absent.
  Future<Uint8List?> read({required String key}) async {
    throw UnimplementedError();
  }

  /// Securely stores [value] under [key].
  Future<void> write({
    required String key,
    required Uint8List value,
  }) async {
    throw UnimplementedError();
  }

  /// Deletes the value associated with [key].
  Future<void> delete({required String key}) async {
    throw UnimplementedError();
  }
}
