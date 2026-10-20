import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/kdf.dart';
import 'package:insur/core/security/key_derivation.dart';
import 'package:insur/core/security/key_manager.dart';

import '../../helpers/fake_secure_storage.dart';

const _legacyPassphrase = 'synthetic legacy passphrase';

void main() {
  test('detects a vault initialized with only legacy keys', () async {
    final storage = FakeSecureStorage()
      ..seed(<String, String>{
        'insur.master_key.v1': base64Encode(Kdf.generateMasterKey()),
        'insur.master_salt.v1': base64Encode(Kdf.generateSalt()),
      });
    final keyManager = KeyManager(secureStorage: storage);

    expect(await keyManager.isInitialized(), isTrue);
    expect(keyManager.state, KeyManagerState.locked);
  });

  test(
    'successful legacy unlock migrates to wrapped MK without changing DB key',
    () async {
      final storage = FakeSecureStorage();
      final salt = Kdf.generateSalt();
      final legacyMasterKey = await Kdf.deriveMasterKey(
        passphrase: _legacyPassphrase,
        salt: salt,
      );
      final expectedDbKey = await SubKeyDeriver.deriveDbKey(legacyMasterKey);
      storage.seed(<String, String>{
        'insur.master_key.v1': base64Encode(legacyMasterKey),
        'insur.master_salt.v1': base64Encode(salt),
        'insur.kdf_params.v1': Kdf.paramsDescription(),
      });
      final keyManager = KeyManager(secureStorage: storage);

      expect(await keyManager.unlock(passphrase: _legacyPassphrase), isTrue);
      expect(storage.hasKey('insur.wrapped_mk.v2'), isTrue);
      expect(storage.hasKey('insur.master_key.v1'), isFalse);
      expect(storage.hasKey('insur.master_salt.v1'), isFalse);
      expect(keyManager.dbKey, expectedDbKey);
      expect(await keyManager.hasRecoveryKey(), isFalse);

      salt.fillRange(0, salt.length, 0);
      legacyMasterKey.fillRange(0, legacyMasterKey.length, 0);
      expectedDbKey.fillRange(0, expectedDbKey.length, 0);
    },
  );

  test(
    'wrong legacy passphrase does not migrate or delete legacy material',
    () async {
      final storage = FakeSecureStorage();
      final salt = Kdf.generateSalt();
      final legacyMasterKey = await Kdf.deriveMasterKey(
        passphrase: _legacyPassphrase,
        salt: salt,
      );
      storage.seed(<String, String>{
        'insur.master_key.v1': base64Encode(legacyMasterKey),
        'insur.master_salt.v1': base64Encode(salt),
        'insur.kdf_params.v1': Kdf.paramsDescription(),
      });
      final keyManager = KeyManager(secureStorage: storage);

      expect(
        await keyManager.unlock(passphrase: 'synthetic wrong passphrase'),
        isFalse,
      );
      expect(storage.hasKey('insur.wrapped_mk.v2'), isFalse);
      expect(storage.hasKey('insur.master_key.v1'), isTrue);
      expect(keyManager.isUnlocked, isFalse);

      salt.fillRange(0, salt.length, 0);
      legacyMasterKey.fillRange(0, legacyMasterKey.length, 0);
    },
  );

  test('setup is rejected while legacy credentials are present', () async {
    final storage = FakeSecureStorage()
      ..seed(<String, String>{'insur.master_key.v1': 'synthetic-legacy-value'});
    final keyManager = KeyManager(secureStorage: storage);

    await expectLater(
      keyManager.setup(passphrase: _legacyPassphrase),
      throwsStateError,
    );
  });
}
