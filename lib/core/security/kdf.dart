/// Provides memory-hard passphrase derivation for protecting the local vault.
///
/// Argon2id raises the cost of offline passphrase guessing. Its parameters are
/// fixed here so callers cannot accidentally weaken the application's master
/// key derivation.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derives master keys using the application's fixed Argon2id parameters.
class Kdf {
  const Kdf._();

  /// Required salt size in bytes.
  static const int saltLength = 32;

  /// Derived master key size in bytes.
  static const int keyLength = 32;

  /// Argon2 memory cost in KiB (64 MiB).
  static const int memoryKiB = 65536;

  /// Argon2 iteration count.
  static const int iterations = 3;

  /// Argon2 parallelism degree.
  static const int parallelism = 4;

  /// Derives a 32-byte master key from [passphrase] and a 32-byte [salt].
  ///
  /// The temporary UTF-8 passphrase buffer is overwritten after derivation.
  /// Dart and native implementations may make internal copies that the
  /// garbage collector does not let this method explicitly erase.
  static Future<Uint8List> deriveMasterKey({
    required String passphrase,
    required Uint8List salt,
  }) async {
    final passphraseLength = passphrase.runes.length;
    if (passphraseLength < 12) {
      throw ArgumentError.value(
        passphraseLength,
        'passphrase.length',
        'Must be at least 12 characters',
      );
    }
    if (salt.length != saltLength) {
      throw ArgumentError.value(
        salt.length,
        'salt.length',
        'Must be exactly $saltLength bytes',
      );
    }

    final passphraseBytes = Uint8List.fromList(
      utf8.encode(passphrase),
    );
    try {
      final algorithm = Argon2id(
        memory: memoryKiB,
        iterations: iterations,
        parallelism: parallelism,
        hashLength: keyLength,
      );
      final secretKey = await algorithm.deriveKey(
        secretKey: SecretKey(passphraseBytes),
        nonce: salt,
      );
      final bytes = await secretKey.extractBytes();
      return Uint8List.fromList(bytes);
    } finally {
      // Best effort only: Dart or the crypto implementation may retain copies.
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
    }
  }

  /// Generates a fresh cryptographically secure salt for key derivation.
  ///
  /// [Random.secure] uses the platform's secure random source; [Random] alone
  /// is not suitable for cryptographic salts.
  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Returns whether [passphrase] derives [expectedKey] for [salt].
  ///
  /// The comparison processes every byte instead of returning at the first
  /// mismatch, avoiding content-dependent timing that could leak key bytes.
  static Future<bool> verify({
    required String passphrase,
    required Uint8List salt,
    required Uint8List expectedKey,
  }) async {
    final actualKey = await deriveMasterKey(
      passphrase: passphrase,
      salt: salt,
    );
    try {
      return _constantTimeEquals(actualKey, expectedKey);
    } finally {
      actualKey.fillRange(0, actualKey.length, 0);
    }
  }

  /// Describes the non-secret Argon2id parameters for diagnostics.
  static String paramsDescription() {
    return 'Argon2id(m=64MiB, t=$iterations, p=$parallelism, '
        'len=$keyLength, salt=$saltLength)';
  }

  static bool _constantTimeEquals(Uint8List left, Uint8List right) {
    final length = max(left.length, right.length);
    var difference = left.length ^ right.length;
    for (var index = 0; index < length; index++) {
      final leftByte = index < left.length ? left[index] : 0;
      final rightByte = index < right.length ? right[index] : 0;
      difference |= leftByte ^ rightByte;
    }
    return difference == 0;
  }
}
