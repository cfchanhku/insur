import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/recovery_key.dart';
import 'package:insur/core/security/recovery_key_exception.dart';

const String _recoveryKey = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const String _differentRecoveryKey = '1123456789ABCDEFGHJKMNPQRSTVWXYZ';
const int _testByte = 0x37;

void main() {
  late Uint8List salt;
  late Uint8List differentSalt;
  late Uint8List masterKey;
  late Uint8List recoveryKek;
  late Uint8List sameRecoveryKek;
  late Uint8List differentKeyKek;
  late Uint8List differentSaltKek;

  setUpAll(() async {
    salt =
        Uint8List.fromList(List<int>.filled(RecoveryKey.saltLength, _testByte));
    differentSalt = Uint8List.fromList(salt)..[0] ^= 0x01;
    masterKey = Uint8List.fromList(List<int>.filled(32, 0x42));
    recoveryKek = await RecoveryKey.deriveRecoveryKek(
      recoveryKey: _recoveryKey,
      salt: salt,
    );
    sameRecoveryKek = await RecoveryKey.deriveRecoveryKek(
      recoveryKey: _recoveryKey,
      salt: salt,
    );
    differentKeyKek = await RecoveryKey.deriveRecoveryKek(
      recoveryKey: _differentRecoveryKey,
      salt: salt,
    );
    differentSaltKek = await RecoveryKey.deriveRecoveryKek(
      recoveryKey: _recoveryKey,
      salt: differentSalt,
    );
  });

  group('RecoveryKey.generate', () {
    test('returns a grouped recovery key', () {
      expect(RecoveryKey.generate(), isA<String>());
    });

    test('returns eight groups of four characters', () {
      expect(
        RecoveryKey.generate(),
        matches(
          RegExp(r'^[0-9A-HJKMNPQRSTVWXYZ]{4}(-[0-9A-HJKMNPQRSTVWXYZ]{4}){7}$'),
        ),
      );
    });

    test('returns 32 normalized Crockford characters', () {
      expect(
        RecoveryKey.normalize(RecoveryKey.generate()),
        hasLength(32),
      );
    });

    test('generates different keys on consecutive calls', () {
      expect(RecoveryKey.generate(), isNot(RecoveryKey.generate()));
    });
  });

  group('RecoveryKey.normalize', () {
    test('strips separators and uppercases', () {
      expect(
        RecoveryKey.normalize('0123-4567 89ab-cdef-ghjk-mnpq-rstv-wxyz'),
        '0123456789ABCDEFGHJKMNPQRSTVWXYZ',
      );
    });

    test('maps O, I, L, and U aliases', () {
      expect(
        RecoveryKey.normalize('O123-4567-89AB-CDEF-GHJK-MNPQ-RSTV-WXYU'),
        '0123456789ABCDEFGHJKMNPQRSTVWXYV',
      );
    });

    test('rejects a key that is too short', () {
      expect(() => RecoveryKey.normalize('ABC'), throwsFormatException);
    });

    test('rejects a key that is too long', () {
      expect(
        () => RecoveryKey.normalize(List<String>.filled(33, '0').join()),
        throwsFormatException,
      );
    });

    test('rejects invalid characters', () {
      expect(
        () => RecoveryKey.normalize('0123456789ABCDEFGHJKMNPQRSTVWXY!'),
        throwsFormatException,
      );
    });
  });

  group('RecoveryKey.verifyFormat', () {
    test('accepts a valid grouped key', () {
      expect(
          RecoveryKey.verifyFormat('0123-4567-89AB-CDEF-GHJK-MNPQ-RSTV-WXYZ'),
          isTrue);
    });

    test('rejects invalid input without throwing', () {
      expect(RecoveryKey.verifyFormat('not a recovery key'), isFalse);
    });
  });

  group('RecoveryKey.generateSalt', () {
    test('returns 32 random bytes', () {
      expect(RecoveryKey.generateSalt(), hasLength(RecoveryKey.saltLength));
    });

    test('returns different salts', () {
      expect(RecoveryKey.generateSalt(), isNot(RecoveryKey.generateSalt()));
    });
  });

  group('RecoveryKey.computeVerificationHash', () {
    test('is deterministic for the same key and salt', () {
      expect(
        RecoveryKey.computeVerificationHash(
          recoveryKey: _recoveryKey,
          salt: salt,
        ),
        RecoveryKey.computeVerificationHash(
          recoveryKey: _recoveryKey,
          salt: salt,
        ),
      );
    });

    test('changes when the recovery key changes', () {
      expect(
        RecoveryKey.computeVerificationHash(
          recoveryKey: _recoveryKey,
          salt: salt,
        ),
        isNot(
          RecoveryKey.computeVerificationHash(
            recoveryKey: _differentRecoveryKey,
            salt: salt,
          ),
        ),
      );
    });

    test('changes when the salt changes', () {
      expect(
        RecoveryKey.computeVerificationHash(
          recoveryKey: _recoveryKey,
          salt: salt,
        ),
        isNot(
          RecoveryKey.computeVerificationHash(
            recoveryKey: _recoveryKey,
            salt: differentSalt,
          ),
        ),
      );
    });

    test('returns a 32-byte SHA-256 hash', () {
      expect(
        RecoveryKey.computeVerificationHash(
          recoveryKey: _recoveryKey,
          salt: salt,
        ),
        hasLength(32),
      );
    });
  });

  group('RecoveryKey.wrapMasterKey / unwrapMasterKey', () {
    test('round-trips the master key', () async {
      final wrapped = await RecoveryKey.wrapMasterKey(
        masterKey: masterKey,
        recoveryKek: recoveryKek,
      );

      expect(wrapped, hasLength(12 + 32 + 16));
      expect(
        await RecoveryKey.unwrapMasterKey(
          wrappedMasterKey: wrapped,
          recoveryKek: recoveryKek,
        ),
        masterKey,
      );
    });

    test('rejects a wrong KEK', () async {
      final wrapped = await RecoveryKey.wrapMasterKey(
        masterKey: masterKey,
        recoveryKek: recoveryKek,
      );

      await expectLater(
        RecoveryKey.unwrapMasterKey(
          wrappedMasterKey: wrapped,
          recoveryKek: differentKeyKek,
        ),
        throwsA(isA<RecoveryKeyException>()),
      );
    });

    test('rejects a tampered wrapped master key', () async {
      final wrapped = await RecoveryKey.wrapMasterKey(
        masterKey: masterKey,
        recoveryKek: recoveryKek,
      );
      wrapped[20] ^= 0x01;

      await expectLater(
        RecoveryKey.unwrapMasterKey(
          wrappedMasterKey: wrapped,
          recoveryKek: recoveryKek,
        ),
        throwsA(isA<RecoveryKeyException>()),
      );
    });

    test('rejects truncated wrapped data', () async {
      await expectLater(
        RecoveryKey.unwrapMasterKey(
          wrappedMasterKey: Uint8List(27),
          recoveryKek: recoveryKek,
        ),
        throwsA(isA<RecoveryKeyException>()),
      );
    });

    test('rejects keys with the wrong length', () async {
      await expectLater(
        RecoveryKey.wrapMasterKey(
          masterKey: Uint8List(16),
          recoveryKek: recoveryKek,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RecoveryKey.deriveRecoveryKek', () {
    test('is deterministic for a key and salt', () {
      expect(recoveryKek, sameRecoveryKek);
    });

    test('derives different KEKs for different recovery keys', () {
      expect(recoveryKek, isNot(differentKeyKek));
    });

    test('derives different KEKs for different salts', () {
      expect(recoveryKek, isNot(differentSaltKek));
    });

    test('returns a 32-byte KEK', () {
      expect(recoveryKek, hasLength(RecoveryKey.recoveryKekLength));
    });

    test('rejects a salt with the wrong length', () async {
      await expectLater(
        RecoveryKey.deriveRecoveryKek(
          recoveryKey: _recoveryKey,
          salt: Uint8List(16),
        ),
        throwsArgumentError,
      );
    });
  });

  group('RecoveryKey security hygiene', () {
    test('verification hash is not the raw recovery key', () {
      final hash = RecoveryKey.computeVerificationHash(
        recoveryKey: _recoveryKey,
        salt: salt,
      );

      expect(base64Encode(hash), isNot(contains(_recoveryKey)));
    });

    test('exception text does not contain the recovery key', () {
      const error = RecoveryKeyException(
        'Recovery key authentication failed',
      );

      expect(error.toString(), isNot(contains(_recoveryKey)));
    });
  });
}
