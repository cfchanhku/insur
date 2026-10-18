/// Manages purpose-separated application encryption keys.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Loads, creates, and retires keys using the secure-storage boundary.
class KeyManager {
  /// Loads the existing data-encryption key or securely creates one.
  Future<Uint8List> loadOrCreateDataKey() async {
    throw UnimplementedError();
  }

  /// Removes the stored data-encryption key after an approved lifecycle action.
  Future<void> deleteDataKey() async {
    throw UnimplementedError();
  }
}
