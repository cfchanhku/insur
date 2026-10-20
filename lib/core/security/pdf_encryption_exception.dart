/// Indicates that an exported PDF could not be encrypted safely.
class PdfEncryptionException implements Exception {
  /// Creates a safe, non-sensitive encryption failure.
  const PdfEncryptionException(this.message);

  /// User-safe failure description; never contains document or password data.
  final String message;

  @override
  String toString() => 'PdfEncryptionException: $message';
}
