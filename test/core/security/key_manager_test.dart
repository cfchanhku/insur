import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/kdf.dart';
import 'package:insur/core/security/key_manager.dart';

import '../../helpers/fake_secure_storage.dart';

const _passphrase = 'synthetic passphrase 1234';
const _replacementPassphrase = 'synthetic replacement 1234';

void main() {
  late FakeSecureStorage storage;
  late KeyManager keyManager;

  setUp(() {
    storage = FakeSecureStorage();
    keyManager = KeyManager(secureStorage: storage);
  });

  group('KeyManager state', () {
    test('defines the expected lifecycle states', () {
      expect(KeyManagerState.values, <KeyManagerState>[
        KeyManagerState.uninitialized,
        KeyManagerState.locked,
        KeyManagerState.unlocked,
      ]);
    });

    test('isInitialized is false with fresh storage', () async {
      expect(await keyManager.isInitialized(), isFalse);
      expect(keyManager.state, KeyManagerState.uninitialized);
    });

    test('isInitialized is true after setup', () async {
      await keyManager.setup(passphrase: _passphrase);

      expect(await keyManager.isInitialized(), isTrue);
      expect(keyManager.state, KeyManagerState.unlocked);
    });

    test('detects legacy master-key storage', () async {
      storage.seed(<String, String>{'insur.master_key.v1': 'synthetic-key'});

      expect(await keyManager.isInitialized(), isTrue);
      expect(keyManager.state, KeyManagerState.locked);
    });
  });

  group('KeyManager setup', () {
    test('rejects a passphrase shorter than twelve characters', () async {
      await expectLater(
        keyManager.setup(passphrase: 'too-short'),
        throwsArgumentError,
      );
      expect(storage.rawData, isEmpty);
    });

    test('creates wrapped master-key storage and derives subkeys', () async {
      await keyManager.setup(passphrase: _passphrase);

      final wrapped = base64Decode(storage.rawData['insur.wrapped_mk.v2']!);
      expect(keyManager.state, KeyManagerState.unlocked);
      expect(keyManager.isUnlocked, isTrue);
      expect(wrapped, hasLength(32 + 12 + 32 + 16));
      expect(storage.hasKey('insur.kdf_params.v2'), isTrue);
      expect(storage.hasKey('insur.biometric_enabled.v1'), isTrue);
      expect(storage.hasKey('insur.master_key.v1'), isFalse);
      expect(storage.hasKey('insur.master_salt.v1'), isFalse);
      expect(keyManager.dbKey, hasLength(Kdf.keyLength));
      expect(keyManager.fieldKey, hasLength(Kdf.keyLength));
      expect(keyManager.auditKey, hasLength(Kdf.keyLength));
      wrapped.fillRange(0, wrapped.length, 0);
    });

    test('rejects setup when the vault is already initialized', () async {
      await keyManager.setup(passphrase: _passphrase);

      await expectLater(
        keyManager.setup(passphrase: _replacementPassphrase),
        throwsStateError,
      );
    });
  });

  group('KeyManager unlock and lock', () {
    test('cannot unlock a vault that is not initialized', () async {
      await expectLater(
        keyManager.unlock(passphrase: _passphrase),
        throwsStateError,
      );
    });

    test(
      'accepts the correct passphrase and rejects an incorrect one',
      () async {
        await keyManager.setup(passphrase: _passphrase);
        final originalDbKey = Uint8List.fromList(keyManager.dbKey);

        await keyManager.lock();
        expect(
          await keyManager.unlock(passphrase: 'synthetic incorrect 123'),
          isFalse,
        );
        expect(keyManager.state, KeyManagerState.locked);
        expect(keyManager.failedAttempts, 1);

        expect(await keyManager.unlock(passphrase: _passphrase), isTrue);
        expect(keyManager.state, KeyManagerState.unlocked);
        expect(keyManager.failedAttempts, 0);
        expect(keyManager.currentBackoff, Duration.zero);
        expect(keyManager.dbKey, originalDbKey);
        originalDbKey.fillRange(0, originalDbKey.length, 0);
      },
    );

    test(
      'starts an authentication backoff after three incorrect attempts',
      () async {
        await keyManager.setup(passphrase: _passphrase);

        for (var attempt = 0; attempt < 3; attempt++) {
          expect(
            await keyManager.unlock(passphrase: 'synthetic incorrect 123'),
            isFalse,
          );
        }

        expect(keyManager.failedAttempts, 3);
        expect(keyManager.currentBackoff, const Duration(seconds: 5));
      },
    );

    test(
      'clears in-memory keys but preserves secure storage when locked',
      () async {
        await keyManager.setup(passphrase: _passphrase);
        final storedCredential = storage.rawData['insur.wrapped_mk.v2'];

        await keyManager.lock();

        expect(keyManager.state, KeyManagerState.locked);
        expect(() => keyManager.dbKey, throwsStateError);
        expect(storage.rawData['insur.wrapped_mk.v2'], storedCredential);
      },
    );

    test('logout with wipe removes wrapped and recovery key data', () async {
      await keyManager.setup(passphrase: _passphrase);
      storage.seed(<String, String>{
        'insur.recovery.wrapped_mk.v1': 'synthetic-wrapped-key',
        'insur.recovery.salt.v1': 'synthetic-salt',
        'insur.recovery.verification_hash.v1': 'synthetic-hash',
      });

      await keyManager.logout(wipe: true);

      expect(keyManager.state, KeyManagerState.uninitialized);
      expect(keyManager.isUnlocked, isFalse);
      expect(storage.rawData, isEmpty);
    });

    test('verifyPassphrase does not change session state', () async {
      await keyManager.setup(passphrase: _passphrase);
      final initialState = keyManager.state;
      final attempts = keyManager.failedAttempts;

      expect(
        await keyManager.verifyPassphrase(passphrase: _passphrase),
        isTrue,
      );
      expect(
        await keyManager.verifyPassphrase(
          passphrase: 'synthetic incorrect 123',
        ),
        isFalse,
      );
      expect(keyManager.state, initialState);
      expect(keyManager.failedAttempts, attempts);
    });
  });

  test('subkeys remain stable after passphrase change', () async {
    await keyManager.setup(passphrase: _passphrase);
    final dbKey = keyManager.dbKey;
    final fieldKey = keyManager.fieldKey;
    final auditKey = keyManager.auditKey;

    await keyManager.changePassphrase(
      currentPassphrase: _passphrase,
      newPassphrase: _replacementPassphrase,
    );

    expect(keyManager.dbKey, dbKey);
    expect(keyManager.fieldKey, fieldKey);
    expect(keyManager.auditKey, auditKey);
    expect(
      await keyManager.verifyPassphrase(passphrase: _replacementPassphrase),
      isTrue,
    );
  });

  test(
    'changePassphrase validates state, passphrase, and current credential',
    () async {
      await expectLater(
        keyManager.changePassphrase(
          currentPassphrase: _passphrase,
          newPassphrase: _replacementPassphrase,
        ),
        throwsStateError,
      );

      await keyManager.setup(passphrase: _passphrase);
      await expectLater(
        keyManager.changePassphrase(
          currentPassphrase: _passphrase,
          newPassphrase: 'too-short',
        ),
        throwsArgumentError,
      );
      await expectLater(
        keyManager.changePassphrase(
          currentPassphrase: 'synthetic incorrect 123',
          newPassphrase: _replacementPassphrase,
        ),
        throwsStateError,
      );
    },
  );

  test('keys are unavailable before unlock and after logout', () async {
    await keyManager.setup(passphrase: _passphrase);
    await keyManager.logout();

    expect(keyManager.state, KeyManagerState.uninitialized);
    expect(() => keyManager.dbKey, throwsStateError);
    expect(() => keyManager.fieldKey, throwsStateError);
    expect(() => keyManager.auditKey, throwsStateError);
  });

  test(
    'legacy storage reports initialization without exposing key material',
    () async {
      final salt = Kdf.generateSalt();
      final legacyMasterKey = Kdf.generateMasterKey();
      storage.seed(<String, String>{
        'insur.master_key.v1': base64Encode(legacyMasterKey),
        'insur.master_salt.v1': base64Encode(salt),
      });

      expect(await keyManager.isInitialized(), isTrue);
      expect(keyManager.state, KeyManagerState.locked);

      salt.fillRange(0, salt.length, 0);
      legacyMasterKey.fillRange(0, legacyMasterKey.length, 0);
    },
  );
}
