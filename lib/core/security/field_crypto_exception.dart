/// An error from field encryption or decryption.
///
/// This exception must never include plaintext, ciphertext, or key material in
/// its message.
class FieldCryptoException implements Exception {
  /// Creates an exception with a PII-free [message].
  const FieldCryptoException(this.message);

  /// A safe description of the field cryptography failure.
  final String message;

  @override
  String toString() => 'FieldCryptoException: $message';
}
