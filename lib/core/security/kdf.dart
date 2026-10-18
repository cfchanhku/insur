/// Derives cryptographic keys from user authentication material.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Provides the approved Argon2id key-derivation operation.
class Argon2idKdf {
  /// Derives a key using the reviewed Argon2id parameters.
  Future<Uint8List> deriveKey({
    required String passphrase,
    required Uint8List salt,
  }) async {
    throw UnimplementedError();
  }
}
