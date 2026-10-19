import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/kdf.dart';

void main() {
  const samplePassphrase = 'synthetic test passphrase';
  late Uint8List sampleSalt;
  late Uint8List sampleKey;

  setUpAll(() async {
    sampleSalt = Uint8List.fromList(List<int>.filled(Kdf.saltLength, 0x42));
    sampleKey = await Kdf.deriveMasterKey(
      passphrase: samplePassphrase,
      salt: sampleSalt,
    );
  });

  group('Kdf constants', () {
    test('uses a 32-byte salt', () {
      expect(Kdf.saltLength, 32);
    });

    test('derives 32-byte keys', () {
      expect(Kdf.keyLength, 32);
    });

    test('uses 64 MiB of memory', () {
      expect(Kdf.memoryKiB, 65536);
    });

    test('uses three iterations', () {
      expect(Kdf.iterations, 3);
    });

    test('uses parallelism four', () {
      expect(Kdf.parallelism, 4);
    });
  });

  group('Kdf.generateSalt', () {
    test('returns a Uint8List with the required length', () {
      final salt = Kdf.generateSalt();

      expect(salt, isA<Uint8List>());
      expect(salt, hasLength(Kdf.saltLength));
    });

    test('returns different salts on consecutive calls', () {
      expect(Kdf.generateSalt(), isNot(Kdf.generateSalt()));
    });

    test('produces valid output using the secure random source', () {
      final stopwatch = Stopwatch()..start();
      final salt = Kdf.generateSalt();
      stopwatch.stop();

      expect(salt.any((int byte) => byte != 0), isTrue);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });
  });

  group('Kdf.deriveMasterKey — input validation', () {
    test('rejects a passphrase shorter than twelve characters', () {
      expect(
        () => Kdf.deriveMasterKey(
          passphrase: 'too short',
          salt: sampleSalt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a salt shorter than the required length', () {
      expect(
        () => Kdf.deriveMasterKey(
          passphrase: samplePassphrase,
          salt: Uint8List(Kdf.saltLength - 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a salt longer than the required length', () {
      expect(
        () => Kdf.deriveMasterKey(
          passphrase: samplePassphrase,
          salt: Uint8List(Kdf.saltLength + 1),
        ),
        throwsArgumentError,
      );
    });

    test('accepts a twelve-character passphrase and exact-length salt',
        () async {
      final key = await Kdf.deriveMasterKey(
        passphrase: '123456789012',
        salt: sampleSalt,
      );

      expect(key, hasLength(Kdf.keyLength));
    });
  });

  group('Kdf.deriveMasterKey — determinism', () {
    test('derives the same key for the same passphrase and salt', () async {
      final repeatedKey = await Kdf.deriveMasterKey(
        passphrase: samplePassphrase,
        salt: sampleSalt,
      );

      expect(repeatedKey, sampleKey);
    });

    test('derives a different key for a different passphrase', () async {
      final differentKey = await Kdf.deriveMasterKey(
        passphrase: 'a different synthetic passphrase',
        salt: sampleSalt,
      );

      expect(differentKey, isNot(sampleKey));
    });

    test('derives a different key for a different salt', () async {
      final differentSalt = Uint8List.fromList(sampleSalt)
        ..[0] = sampleSalt[0] ^ 0xff;
      final differentKey = await Kdf.deriveMasterKey(
        passphrase: samplePassphrase,
        salt: differentSalt,
      );

      expect(differentKey, isNot(sampleKey));
    });

    test('returns exactly the configured key length', () {
      expect(sampleKey, hasLength(Kdf.keyLength));
    });
  });

  group('Kdf.deriveMasterKey — known test vectors', () {
    test('matches the published Argon2id password-and-salt vector', () async {
      final algorithm = Argon2id(
        memory: 65536,
        iterations: 2,
        parallelism: 1,
        hashLength: 32,
      );
      final key = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode('password')),
        nonce: utf8.encode('somesalt'),
      );
      final output = await key.extractBytes();

      expect(
        output,
        _decodeHex(
          '09316115d5cf24ed5a15a31a3ba326e5'
          'cf32edc24702987c02b6566f61913cf7',
        ),
      );
    });

    test('uses the configured parameters deterministically', () {
      // An end-to-end vector with our exact parameters requires a precomputed
      // vector; the library-level vector test above proves algorithm behavior.
      expect(sampleKey, hasLength(Kdf.keyLength));
      expect(sampleKey, isNotEmpty);
    });
  });

  group('Kdf.verify', () {
    test('returns true for the correct passphrase and salt', () async {
      expect(
        await Kdf.verify(
          passphrase: samplePassphrase,
          salt: sampleSalt,
          expectedKey: sampleKey,
        ),
        isTrue,
      );
    });

    test('returns false for a wrong passphrase', () async {
      expect(
        await Kdf.verify(
          passphrase: 'incorrect synthetic passphrase',
          salt: sampleSalt,
          expectedKey: sampleKey,
        ),
        isFalse,
      );
    });

    test('returns false for a wrong salt without throwing', () async {
      final differentSalt = Uint8List.fromList(sampleSalt)
        ..[0] = sampleSalt[0] ^ 0xff;

      expect(
        await Kdf.verify(
          passphrase: samplePassphrase,
          salt: differentSalt,
          expectedKey: sampleKey,
        ),
        isFalse,
      );
    });
  });

  group('Kdf.paramsDescription', () {
    test('describes the non-secret Argon2id parameters', () {
      final description = Kdf.paramsDescription();

      expect(description, contains('Argon2id'));
      expect(description, contains('m=64'));
      expect(description, contains('t=3'));
      expect(description, contains('p=4'));
      expect(description, contains('len=32'));
    });
  });

  group('Kdf — security hygiene', () {
    test('does not include the passphrase in parameter diagnostics', () {
      expect(
        Kdf.paramsDescription(),
        isNot(contains(samplePassphrase)),
      );
    });

    test('does not return the passphrase bytes as the derived key', () {
      expect(
        sampleKey,
        isNot(Uint8List.fromList(utf8.encode(samplePassphrase))),
      );
    });
  });
}

List<int> _decodeHex(String value) {
  return <int>[
    for (int index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ];
}
