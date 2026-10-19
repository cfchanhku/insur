/// Generates and validates offline recovery keys.
///
/// A recovery key grants access to the master key only when combined with the
/// stored salt and authenticated-encrypted wrapped master key. The raw recovery
/// key is never stored by this class: the user must print it and keep it
/// offline. Secure storage holds only the wrapped master key, salt, and a
/// SHA-256 verification hash.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'crockford_base32.dart';
import 'kdf.dart';
import 'recovery_key_exception.dart';

/// Recovery-key encoding and cryptographic operations.
class RecoveryKey {
  const RecoveryKey._();

  /// Number of random bytes in a generated recovery key (160 bits).
  ///
  /// The project specification had conflicting group counts; the selected MVP
  /// format is 8 groups of 4 characters (32 Base32 characters), yielding 160
  /// bits of entropy while remaining printable.
  static const int keyBytes = 20;

  /// Recovery salt length in bytes.
  static const int saltLength = 32;

  /// Recovery key-encryption key length in bytes.
  static const int recoveryKekLength = 32;

  static const int _nonceLength = 12;
  static const int _tagLength = 16;
  static const String _wrappingAad = 'insur/mk/recovery/v1';

  /// Generates and returns a newly generated offline recovery key.
  ///
  /// This is the only time the raw key should be displayed. The caller must
  /// show it once for the user to record offline, then discard it.
  static String generate() {
    final random = Random.secure();
    final randomBytes = Uint8List.fromList(
      List<int>.generate(keyBytes, (_) => random.nextInt(256)),
    );
    try {
      final encoded = CrockfordBase32.encode(randomBytes);
      return CrockfordBase32.groupWithHyphens(encoded);
    } finally {
      randomBytes.fillRange(0, randomBytes.length, 0);
    }
  }

  /// Normalizes [input] to 32 canonical Crockford characters.
  ///
  /// Hyphens and spaces are removed, case is normalized, and ambiguous
  /// Crockford aliases are mapped to their canonical characters.
  static String normalize(String input) {
    final stripped = CrockfordBase32.stripHyphens(input);
    final normalized = StringBuffer();
    for (final codeUnit in stripped.codeUnits) {
      var character = String.fromCharCode(codeUnit);
      if (character == 'O') {
        character = '0';
      } else if (character == 'I' || character == 'L') {
        character = '1';
      } else if (character == 'U') {
        character = 'V';
      }
      if (!CrockfordBase32.alphabet.contains(character)) {
        throw const FormatException('Invalid recovery key character');
      }
      normalized.write(character);
    }

    final value = normalized.toString();
    if (value.length != keyBytes * 8 ~/ 5) {
      throw const FormatException('Invalid recovery key length');
    }
    final decoded = CrockfordBase32.decode(value);
    try {
      if (decoded.length != keyBytes) {
        throw const FormatException('Invalid recovery key encoding');
      }
    } finally {
      decoded.fillRange(0, decoded.length, 0);
    }
    return value;
  }

  /// Generates a cryptographically secure recovery salt.
  static Uint8List generateSalt() => Kdf.generateSalt();

  /// Derives a 32-byte KEK from [recoveryKey] and [salt] using Argon2id.
  ///
  /// The normalized Base32 key is decoded and re-encoded as base64 for the KDF
  /// String API. This is a lossless ASCII representation of all key bytes. The
  /// temporary String is immutable and cannot be explicitly zeroed in Dart.
  static Future<Uint8List> deriveRecoveryKek({
    required String recoveryKey,
    required Uint8List salt,
  }) async {
    if (salt.length != saltLength) {
      throw ArgumentError.value(
        salt.length,
        'salt.length',
        'Must be exactly $saltLength bytes',
      );
    }
    final normalized = normalize(recoveryKey);
    final keyBytes = CrockfordBase32.decode(normalized);
    try {
      if (keyBytes.length != RecoveryKey.keyBytes) {
        throw const RecoveryKeyException('Invalid recovery key encoding');
      }
      final passphrase = base64Encode(keyBytes);
      return await Kdf.deriveMasterKey(passphrase: passphrase, salt: salt);
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
    }
  }

  /// Wraps a 32-byte [masterKey] with [recoveryKek] using AES-256-GCM.
  ///
  /// The returned bytes are nonce, ciphertext, and authentication tag, ready
  /// for base64 storage in the platform secure storage.
  static Future<Uint8List> wrapMasterKey({
    required Uint8List masterKey,
    required Uint8List recoveryKek,
  }) async {
    _validateKeyLength(masterKey, 'masterKey');
    _validateKeyLength(recoveryKek, 'recoveryKek');

    final nonce = _randomBytes(_nonceLength);
    try {
      final algorithm = AesGcm.with256bits();
      final secretBox = await algorithm.encrypt(
        masterKey,
        secretKey: SecretKey(recoveryKek),
        nonce: nonce,
        aad: utf8.encode(_wrappingAad),
      );
      if (secretBox.mac.bytes.length != _tagLength ||
          secretBox.nonce.length != _nonceLength) {
        throw const RecoveryKeyException('Unexpected AES-GCM output');
      }

      final wrapped = Uint8List(
        secretBox.nonce.length +
            secretBox.cipherText.length +
            secretBox.mac.bytes.length,
      );
      var offset = 0;
      wrapped.setRange(
        offset,
        offset + secretBox.nonce.length,
        secretBox.nonce,
      );
      offset += secretBox.nonce.length;
      wrapped.setRange(
        offset,
        offset + secretBox.cipherText.length,
        secretBox.cipherText,
      );
      offset += secretBox.cipherText.length;
      wrapped.setRange(
        offset,
        offset + secretBox.mac.bytes.length,
        secretBox.mac.bytes,
      );
      return wrapped;
    } finally {
      nonce.fillRange(0, nonce.length, 0);
    }
  }

  /// Authenticates and unwraps [wrappedMasterKey] using [recoveryKek].
  ///
  /// Throws [RecoveryKeyException] when the data is truncated, authentication
  /// fails, or the unwrapped key has an unexpected length.
  static Future<Uint8List> unwrapMasterKey({
    required Uint8List wrappedMasterKey,
    required Uint8List recoveryKek,
  }) async {
    _validateKeyLength(recoveryKek, 'recoveryKek');
    if (wrappedMasterKey.length < _nonceLength + _tagLength) {
      throw const RecoveryKeyException('Wrapped master key is too short');
    }

    final nonce = wrappedMasterKey.sublist(0, _nonceLength);
    final cipherText = wrappedMasterKey.sublist(
      _nonceLength,
      wrappedMasterKey.length - _tagLength,
    );
    final tag = wrappedMasterKey.sublist(wrappedMasterKey.length - _tagLength);
    final algorithm = AesGcm.with256bits();
    late final List<int> plainText;
    try {
      plainText = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
        secretKey: SecretKey(recoveryKek),
        aad: utf8.encode(_wrappingAad),
      );
    } on SecretBoxAuthenticationError {
      throw const RecoveryKeyException('Recovery key authentication failed');
    }

    if (plainText.length != Kdf.keyLength) {
      throw const RecoveryKeyException('Unwrapped master key is invalid');
    }
    return Uint8List.fromList(plainText);
  }

  /// Computes a fast SHA-256 check value for [recoveryKey] and [salt].
  ///
  /// This is only a format/key pre-check before the authoritative Argon2id
  /// derivation and authenticated unwrap.
  static Uint8List computeVerificationHash({
    required String recoveryKey,
    required Uint8List salt,
  }) {
    final normalized = normalize(recoveryKey);
    final input = Uint8List.fromList(<int>[
      ...utf8.encode(normalized),
      ...salt,
    ]);
    try {
      return Uint8List.fromList(crypto.sha256.convert(input).bytes);
    } finally {
      input.fillRange(0, input.length, 0);
    }
  }

  /// Returns whether [input] has the expected recovery-key format.
  static bool verifyFormat(String input) {
    try {
      normalize(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  static void _validateKeyLength(Uint8List key, String name) {
    if (key.length != recoveryKekLength) {
      throw ArgumentError.value(
        key.length,
        '$name.length',
        'Must be exactly $recoveryKekLength bytes',
      );
    }
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
