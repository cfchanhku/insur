/// Manages purpose-separated application encryption keys.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

import '../platform/secure_storage.dart';

/// Loads, creates, and retires keys using the secure-storage boundary.
class KeyManager {
  /// Creates a key manager backed by platform secure storage.
  const KeyManager({required this.secureStorage});

  /// Platform storage used for wrapped key material.
  final PlatformSecureStorage secureStorage;

  /// Loads the existing data-encryption key or securely creates one.
  Future<Uint8List> loadOrCreateDataKey() async {
    throw UnimplementedError('KeyManager.loadOrCreateDataKey');
  }

  /// Wraps [keyToWrap] using [wrappingKey] and [nonce].
  Future<Uint8List> wrapKey({
    required Uint8List keyToWrap,
    required Uint8List wrappingKey,
    required Uint8List nonce,
  }) async {
    throw UnimplementedError('KeyManager.wrapKey');
  }

  /// Authenticates and unwraps [wrappedKey] using [wrappingKey] and [nonce].
  Future<Uint8List> unwrapKey({
    required Uint8List wrappedKey,
    required Uint8List wrappingKey,
    required Uint8List nonce,
  }) async {
    throw UnimplementedError('KeyManager.unwrapKey');
  }

  /// Removes the stored data-encryption key after an approved lifecycle action.
  Future<void> deleteDataKey() async {
    throw UnimplementedError('KeyManager.deleteDataKey');
  }
}
