/// Encrypts sensitive fields with authenticated encryption in addition to
/// SQLCipher, providing defense in depth if the database key is compromised.
///
/// Additional authenticated data (AAD) binds ciphertext to an entity, field,
/// and record, preventing ciphertext from being moved between those contexts.
/// Callers must provide the same AAD values during decryption. AES-GCM requires
/// a unique nonce for every encryption with a key; nonce reuse can catastrophically
/// compromise confidentiality and integrity. The random 96-bit nonces used here
/// make collisions extremely unlikely, but do not provide an absolute uniqueness
/// guarantee. Dart key buffers can be overwritten on a best-effort basis, but the
/// runtime or cryptographic implementation may retain internal copies.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'field_crypto_exception.dart';

/// Encrypts and decrypts field values using AES-256-GCM.
///
/// The caller owns the key lifecycle and should clear the supplied buffer when
/// it is no longer needed. The instance retains a reference to that buffer.
class FieldCrypto {
  /// Creates a field cryptography helper using a 32-byte [fieldKey].
  FieldCrypto({required Uint8List fieldKey}) : _fieldKey = fieldKey {
    if (fieldKey.length != keyLength) {
      throw ArgumentError.value(
        fieldKey.length,
        'fieldKey.length',
        'Must be exactly $keyLength bytes',
      );
    }
  }

  /// Required AES-256 key length in bytes.
  static const int keyLength = 32;

  /// AES-GCM nonce length in bytes.
  static const int nonceLength = 12;

  /// AES-GCM authentication tag length in bytes.
  static const int tagLength = 16;

  final Uint8List _fieldKey;

  /// Encrypts [plaintext] and returns base64 of nonce, ciphertext, and tag.
  ///
  /// The AAD is UTF-8 of `entityType|fieldName|recordId`; a null [recordId]
  /// is represented by an empty string. The same values must be supplied to
  /// [decrypt] or authentication will fail.
  Future<String> encrypt({
    required String plaintext,
    required String entityType,
    required String fieldName,
    String? recordId,
  }) async {
    final aad = utf8.encode('$entityType|$fieldName|${recordId ?? ''}');
    final nonce = _randomNonce();
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(_fieldKey),
      nonce: nonce,
      aad: aad,
    );

    if (secretBox.mac.bytes.length != tagLength) {
      throw StateError('AES-GCM returned an unexpected authentication tag.');
    }

    final output = Uint8List(
      secretBox.nonce.length +
          secretBox.cipherText.length +
          secretBox.mac.bytes.length,
    );
    var offset = 0;
    output.setRange(offset, offset + secretBox.nonce.length, secretBox.nonce);
    offset += secretBox.nonce.length;
    output.setRange(
      offset,
      offset + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    offset += secretBox.cipherText.length;
    output.setRange(
      offset,
      offset + secretBox.mac.bytes.length,
      secretBox.mac.bytes,
    );

    return base64Encode(output);
  }

  /// Authenticates and decrypts base64 [ciphertext] using the supplied context.
  ///
  /// Throws [FieldCryptoException] for malformed base64, truncated input, or
  /// failed GCM authentication. No plaintext or key material is included in
  /// these errors.
  Future<String> decrypt({
    required String ciphertext,
    required String entityType,
    required String fieldName,
    String? recordId,
  }) async {
    late final Uint8List input;
    try {
      input = base64Decode(ciphertext);
    } on FormatException {
      throw const FieldCryptoException('Invalid base64');
    }

    if (input.length < nonceLength + tagLength) {
      throw const FieldCryptoException('Ciphertext too short');
    }

    final nonce = input.sublist(0, nonceLength);
    final cipherText = input.sublist(nonceLength, input.length - tagLength);
    final macBytes = input.sublist(input.length - tagLength);
    final aad = utf8.encode('$entityType|$fieldName|${recordId ?? ''}');
    final algorithm = AesGcm.with256bits();

    late final List<int> plainTextBytes;
    try {
      plainTextBytes = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: SecretKey(_fieldKey),
        aad: aad,
      );
    } on SecretBoxAuthenticationError {
      throw const FieldCryptoException(
        'Authentication failed — wrong key, wrong AAD, or tampered ciphertext',
      );
    }

    return utf8.decode(plainTextBytes);
  }

  /// Encrypts [plaintext], returning null when it is null.
  Future<String?> encryptNullable({
    required String? plaintext,
    required String entityType,
    required String fieldName,
    String? recordId,
  }) async {
    if (plaintext == null) {
      return null;
    }
    return encrypt(
      plaintext: plaintext,
      entityType: entityType,
      fieldName: fieldName,
      recordId: recordId,
    );
  }

  /// Decrypts [ciphertext], returning null when it is null.
  Future<String?> decryptNullable({
    required String? ciphertext,
    required String entityType,
    required String fieldName,
    String? recordId,
  }) async {
    if (ciphertext == null) {
      return null;
    }
    return decrypt(
      ciphertext: ciphertext,
      entityType: entityType,
      fieldName: fieldName,
      recordId: recordId,
    );
  }

  /// Describes the non-secret AES-GCM parameters used by this class.
  static String paramsDescription() {
    return 'AES-256-GCM(nonce=96bit, tag=128bit, aad=entity|field|record)';
  }

  Uint8List _randomNonce() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(nonceLength, (_) => random.nextInt(256)),
    );
  }
}
