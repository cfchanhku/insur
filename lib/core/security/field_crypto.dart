/// Encrypts and decrypts sensitive field data with authenticated encryption.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Defines the AES-256-GCM field encryption boundary.
class FieldCrypto {
  /// Encrypts [plaintext] using the supplied key, nonce, and associated data.
  Future<Uint8List> encrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    required Uint8List associatedData,
  }) async {
    throw UnimplementedError('FieldCrypto.encrypt');
  }

  /// Authenticates and decrypts [ciphertext].
  Future<Uint8List> decrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertext,
    required Uint8List associatedData,
  }) async {
    throw UnimplementedError('FieldCrypto.decrypt');
  }
}
