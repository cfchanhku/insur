import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/backup/backup_crypto.dart';
import 'package:insur/core/backup/backup_exception.dart';
import 'package:insur/core/backup/backup_format.dart';

void main() {
  group('BackupCrypto — deriveBackupKey', () {
    late Uint8List salt;
    late Uint8List key;

    setUpAll(() async {
      salt = Uint8List.fromList(List<int>.filled(BackupFormat.saltLength, 4));
      key = await BackupCrypto.deriveBackupKey(
        passphrase: 'synthetic backup passphrase',
        salt: salt,
      );
    });

    test('returns a 32-byte key deterministically', () async {
      final repeated = await BackupCrypto.deriveBackupKey(
        passphrase: 'synthetic backup passphrase',
        salt: salt,
      );

      expect(key, hasLength(BackupFormat.keyLength));
      expect(repeated, key);
    });

    test('different passphrase derives a different key', () async {
      final result = await BackupCrypto.deriveBackupKey(
        passphrase: 'another synthetic passphrase',
        salt: salt,
      );

      expect(result, isNot(key));
    });

    test('different salt derives a different key', () async {
      final result = await BackupCrypto.deriveBackupKey(
        passphrase: 'synthetic backup passphrase',
        salt: Uint8List.fromList(List<int>.filled(BackupFormat.saltLength, 5)),
      );

      expect(result, isNot(key));
    });

    test('rejects a short passphrase', () {
      expect(
        () => BackupCrypto.deriveBackupKey(passphrase: 'too short', salt: salt),
        throwsArgumentError,
      );
    });

    test('rejects an invalid salt length', () {
      expect(
        () => BackupCrypto.deriveBackupKey(
          passphrase: 'synthetic backup passphrase',
          salt: Uint8List(16),
        ),
        throwsArgumentError,
      );
    });
  });

  group('BackupCrypto — encrypt/decrypt', () {
    late Uint8List key;
    late Uint8List nonce;
    late Uint8List aad;
    late Uint8List plaintext;

    setUpAll(() async {
      key = await BackupCrypto.deriveBackupKey(
        passphrase: 'synthetic backup passphrase',
        salt: Uint8List.fromList(List<int>.filled(BackupFormat.saltLength, 4)),
      );
      nonce = Uint8List.fromList(
        List<int>.generate(BackupFormat.nonceLength, (int index) => index),
      );
      aad = Uint8List(BackupFormat.headerSize);
      plaintext = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
    });

    test('round trips plaintext and prefixes the nonce', () async {
      final encrypted = await BackupCrypto.encrypt(
        backupKey: key,
        plaintext: plaintext,
        nonce: nonce,
        aadHeader: aad,
      );

      expect(encrypted.sublist(0, nonce.length), nonce);
      final decrypted = await BackupCrypto.decrypt(
        backupKey: key,
        ciphertextWithTag: encrypted.sublist(nonce.length),
        nonce: nonce,
        aadHeader: aad,
      );
      expect(decrypted, plaintext);
    });

    test('rejects a wrong decryption key', () async {
      final encrypted = await BackupCrypto.encrypt(
        backupKey: key,
        plaintext: plaintext,
        nonce: nonce,
        aadHeader: aad,
      );

      expect(
        () => BackupCrypto.decrypt(
          backupKey: Uint8List.fromList(List<int>.filled(32, 1)),
          ciphertextWithTag: encrypted.sublist(nonce.length),
          nonce: nonce,
          aadHeader: aad,
        ),
        throwsA(isA<BackupAuthenticationException>()),
      );
    });

    test('rejects tampered additional authenticated data', () async {
      final encrypted = await BackupCrypto.encrypt(
        backupKey: key,
        plaintext: plaintext,
        nonce: nonce,
        aadHeader: aad,
      );
      final tamperedAad = Uint8List.fromList(aad)..[0] = 1;

      expect(
        () => BackupCrypto.decrypt(
          backupKey: key,
          ciphertextWithTag: encrypted.sublist(nonce.length),
          nonce: nonce,
          aadHeader: tamperedAad,
        ),
        throwsA(isA<BackupAuthenticationException>()),
      );
    });
  });

  group('BackupCrypto — HMAC', () {
    final hmacKey = Uint8List.fromList(List<int>.filled(32, 3));
    final data = Uint8List.fromList(<int>[10, 20, 30]);

    test('verifies the correct HMAC', () {
      final hmac = BackupCrypto.computeHmac(hmacKey: hmacKey, data: data);

      expect(hmac, hasLength(BackupFormat.hmacLength));
      expect(
        BackupCrypto.verifyHmac(hmacKey: hmacKey, data: data, expected: hmac),
        isTrue,
      );
    });

    test('rejects modified data', () {
      final hmac = BackupCrypto.computeHmac(hmacKey: hmacKey, data: data);

      expect(
        BackupCrypto.verifyHmac(
          hmacKey: hmacKey,
          data: Uint8List.fromList(data)..[0] = 11,
          expected: hmac,
        ),
        isFalse,
      );
    });

    test('rejects a different key and malformed HMAC length', () {
      final hmac = BackupCrypto.computeHmac(hmacKey: hmacKey, data: data);

      expect(
        BackupCrypto.verifyHmac(
          hmacKey: Uint8List.fromList(List<int>.filled(32, 4)),
          data: data,
          expected: hmac,
        ),
        isFalse,
      );
      expect(
        BackupCrypto.verifyHmac(
          hmacKey: hmacKey,
          data: data,
          expected: Uint8List(16),
        ),
        isFalse,
      );
    });
  });
}
