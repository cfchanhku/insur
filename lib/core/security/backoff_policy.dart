/// Defines escalating delays for failed passphrase attempts.
///
/// Exponential backoff slows repeated guesses while allowing occasional user
/// mistakes to recover without an excessive delay.
class BackoffPolicy {
  const BackoffPolicy._();

  /// Returns the delay to apply after [attempts] failed authentications.
  static Duration forAttempts(int attempts) {
    if (attempts < 3) {
      return Duration.zero;
    }
    if (attempts < 5) {
      return const Duration(seconds: 5);
    }
    if (attempts < 7) {
      return const Duration(seconds: 15);
    }
    if (attempts < 10) {
      return const Duration(seconds: 60);
    }
    return const Duration(minutes: 5);
  }

  /// Whether the caller should require an app restart after [attempts].
  static bool shouldRequireRestart(int attempts) => attempts >= 10;
}
