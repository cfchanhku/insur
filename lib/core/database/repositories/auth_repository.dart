/// Provides persistence and operations for local vault authentication.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/auth/models/auth_state.dart';

/// Coordinates authentication state and vault credential verification.
class AuthRepository {
  /// Verifies the supplied passphrase without exposing credential material.
  Future<AuthState> authenticate(String passphrase) async {
    throw UnimplementedError('AuthRepository.authenticate');
  }

  /// Locks the current vault session.
  Future<void> lock() async {
    throw UnimplementedError('AuthRepository.lock');
  }
}
