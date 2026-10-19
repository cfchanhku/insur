/// An error during recovery-key derivation or master-key unwrapping.
///
/// This exception must never include the recovery key or other key material in
/// its message.
class RecoveryKeyException implements Exception {
  /// Creates an exception with a safe [message].
  const RecoveryKeyException(this.message);

  /// A PII-free description of the recovery failure.
  final String message;

  @override
  String toString() => 'RecoveryKeyException: $message';
}
