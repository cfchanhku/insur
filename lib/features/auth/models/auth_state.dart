/// Represents the current authenticated-vault state.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Immutable authentication state for the current local vault session.
class AuthState {
  /// Creates an authentication state.
  const AuthState({required this.isAuthenticated});

  /// Whether the vault is currently unlocked for this session.
  final bool isAuthenticated;
}
