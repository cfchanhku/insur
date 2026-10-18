/// Derives a 32-byte master key from a user passphrase using Argon2id.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derives encryption keys using the configured Argon2id work factors.
class Kdf {
  const Kdf._();

  static const int _memoryKiB = 64 * 1024;
  static const int _iterations = 3;
  static const int _parallelism = 4;
  static const int _saltLengthBytes = 32;
  static const int _outputLengthBytes = 32;

  /// Derives a master key from [passphrase] and a cryptographically random
  /// 32-byte [salt].
  ///
  /// The salt must be generated for each vault and stored alongside its
  /// parameters; it is not secret. Do not reuse it for unrelated keys.
  static Future<Uint8List> deriveMasterKey({
    required String passphrase,
    required Uint8List salt,
  }) async {
    if (passphrase.isEmpty) {
      throw ArgumentError.value(passphrase, 'passphrase', 'Must not be empty');
    }
    if (salt.length != _saltLengthBytes) {
      throw ArgumentError.value(
        salt.length,
        'salt',
        'Must be $_saltLengthBytes bytes',
      );
    }

    final passwordBytes = Uint8List.fromList(utf8.encode(passphrase));

    try {
      final derivedKey = await Argon2id(
        memory: _memoryKiB,
        iterations: _iterations,
        parallelism: _parallelism,
        hashLength: _outputLengthBytes,
      ).deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: salt,
      );
      return Uint8List.fromList(await derivedKey.extractBytes());
    } finally {
      passwordBytes.fillRange(0, passwordBytes.length, 0);
    }
  }
}
