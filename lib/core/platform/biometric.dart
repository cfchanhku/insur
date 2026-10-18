/// Provides a platform-neutral biometric authentication boundary.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Checks biometric availability and requests local authentication.
class BiometricAuthenticator {
  /// Returns whether biometric authentication is available on this device.
  Future<bool> isAvailable() async {
    throw UnimplementedError('BiometricAuthenticator.isAvailable');
  }

  /// Requests biometric authentication with a localized [reason].
  Future<bool> authenticate({required String reason}) async {
    throw UnimplementedError('BiometricAuthenticator.authenticate');
  }
}
