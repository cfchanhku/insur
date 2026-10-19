import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'backup_exception.dart';
import 'backup_format.dart';

/// Cryptographic operations for the encrypted backup envelope.
class BackupCrypto {
  const BackupCrypto._();

  static const String _hmacDomain = 'insur/backup/hmac/v1';

  /// Derives a backup-only key with the fixed Argon2id parameters in the
  /// backup format. The passphrase is independent from the login credential.
  static Future<Uint8List> deriveBackupKey({
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
    if (salt.length != BackupFormat.saltLength) {
      throw ArgumentError.value(
        salt.length,
        'salt.length',
        'Must be exactly ${BackupFormat.saltLength} bytes',
      );
    }

    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    try {
      final argon2id = Argon2id(
        memory: BackupFormat.kdfMemoryKiB,
        iterations: BackupFormat.kdfIterations,
        parallelism: BackupFormat.kdfParallelism,
        hashLength: BackupFormat.keyLength,
      );
      final derived = await argon2id.deriveKey(
        secretKey: SecretKey(passphraseBytes),
        nonce: salt,
      );
      return Uint8List.fromList(await derived.extractBytes());
    } finally {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
    }
  }

  /// Derives an independent HMAC key using the versioned backup domain.
  static Future<Uint8List> deriveHmacKey(Uint8List backupKey) async {
    _validateKey(backupKey, 'backupKey');
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: BackupFormat.keyLength,
    );
    final SecretKey derived = await hkdf.deriveKey(
      secretKey: SecretKey(backupKey),
      info: utf8.encode(_hmacDomain),
    );
    return Uint8List.fromList(await derived.extractBytes());
  }

  /// Encrypts with AES-256-GCM and binds the serialized header as AAD.
  ///
  /// The output is `nonce || ciphertext || tag`; the file format stores the
  /// nonce in the header, so callers remove this prefix before serialization.
  static Future<Uint8List> encrypt({
    required Uint8List backupKey,
    required Uint8List plaintext,
    required Uint8List nonce,
    required Uint8List aadHeader,
  }) async {
    _validateKey(backupKey, 'backupKey');
    if (nonce.length != BackupFormat.nonceLength) {
      throw ArgumentError.value(
        nonce.length,
        'nonce.length',
        'Must be exactly ${BackupFormat.nonceLength} bytes',
      );
    }
    if (aadHeader.length != BackupFormat.headerSize) {
      throw ArgumentError.value(
        aadHeader.length,
        'aadHeader.length',
        'Must be exactly ${BackupFormat.headerSize} bytes',
      );
    }
    final box = await AesGcm.with256bits().encrypt(
      plaintext,
      secretKey: SecretKey(backupKey),
      nonce: nonce,
      aad: aadHeader,
    );
    return Uint8List.fromList(<int>[
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// Decrypts ciphertext and its tag using the nonce and authenticated header.
  ///
  /// The header is GCM AAD, binding its contents to the ciphertext. The
  /// separate HMAC is still required as a fast pre-decryption integrity check
  /// for large backup files.
  static Future<Uint8List> decrypt({
    required Uint8List backupKey,
    required Uint8List ciphertextWithTag,
    required Uint8List nonce,
    required Uint8List aadHeader,
  }) async {
    _validateKey(backupKey, 'backupKey');
    if (nonce.length != BackupFormat.nonceLength ||
        aadHeader.length != BackupFormat.headerSize ||
        ciphertextWithTag.length < BackupFormat.tagLength) {
      throw const BackupFormatException('Backup encrypted payload is invalid');
    }
    final ciphertextLength = ciphertextWithTag.length - BackupFormat.tagLength;
    final box = SecretBox(
      ciphertextWithTag.sublist(0, ciphertextLength),
      nonce: nonce,
      mac: Mac(ciphertextWithTag.sublist(ciphertextLength)),
    );
    try {
      final plaintext = await AesGcm.with256bits().decrypt(
        box,
        secretKey: SecretKey(backupKey),
        aad: aadHeader,
      );
      return Uint8List.fromList(plaintext);
    } on SecretBoxAuthenticationError {
      throw const BackupAuthenticationException('Backup authentication failed');
    }
  }

  /// Computes HMAC-SHA256 over [data].
  static Uint8List computeHmac({
    required Uint8List hmacKey,
    required Uint8List data,
  }) {
    _validateKey(hmacKey, 'hmacKey');
    return Uint8List.fromList(
      crypto.Hmac(crypto.sha256, hmacKey).convert(data).bytes,
    );
  }

  /// Verifies an HMAC using a constant-time byte comparison.
  static bool verifyHmac({
    required Uint8List hmacKey,
    required Uint8List data,
    required Uint8List expected,
  }) {
    if (expected.length != BackupFormat.hmacLength) {
      return false;
    }
    final actual = computeHmac(hmacKey: hmacKey, data: data);
    var difference = actual.length ^ expected.length;
    for (var index = 0; index < actual.length; index++) {
      difference |= actual[index] ^ expected[index];
    }
    actual.fillRange(0, actual.length, 0);
    return difference == 0;
  }

  static void _validateKey(Uint8List key, String name) {
    if (key.length != BackupFormat.keyLength) {
      throw ArgumentError.value(
        key.length,
        '$name.length',
        'Must be exactly ${BackupFormat.keyLength} bytes',
      );
    }
  }
}
