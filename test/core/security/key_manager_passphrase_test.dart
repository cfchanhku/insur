import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/kdf.dart';
import 'package:insur/core/security/key_derivation.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> values = <String, String>{};
  String? failWriteKey;

  void configure() {
    when(() => read(key: any(named: 'key'))).thenAnswer((invocation) async {
      return values[invocation.namedArguments[#key] as String];
    });
    when(
      () => write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      if (key == failWriteKey) {
        throw StateError('Synthetic secure-storage write failure');
      }
      values[key] = invocation.namedArguments[#value] as String;
    });
    when(() => delete(key: any(named: 'key'))).thenAnswer((invocation) async {
      values.remove(invocation.namedArguments[#key] as String);
    });
  }
}

void main() {
  const originalPassphrase = 'synthetic original passphrase';
  const replacementPassphrase = 'synthetic replacement passphrase';

  late _MockSecureStorage secureStorage;
  late KeyManager keyManager;

  setUp(() {
    secureStorage = _MockSecureStorage()..configure();
    keyManager = KeyManager(secureStorage: secureStorage);
  });

  test('setup creates a random wrapped master key', () async {
    await keyManager.setup(passphrase: originalPassphrase);

    final material = await keyManager.exportBackupMaterial();
    final credential = material.wrappedPassphraseCredential!;
    final salt = Uint8List.fromList(credential.sublist(0, Kdf.saltLength));
    final derivedPassphraseKey = await Kdf.derivePassphraseKey(
      passphrase: originalPassphrase,
      salt: salt,
    );

    expect(material.masterKey, isNot(equals(derivedPassphraseKey)));
    expect(credential.length, 92);
    expect(secureStorage.values.containsKey('insur.master_key.v1'), isFalse);
    expect(secureStorage.values['insur.wrapped_mk.v2'], isNotNull);

    material.clear();
    salt.fillRange(0, salt.length, 0);
    derivedPassphraseKey.fillRange(0, derivedPassphraseKey.length, 0);
  });

  test(
    'changing passphrase preserves the master-derived database key',
    () async {
      await keyManager.setup(passphrase: originalPassphrase);
      final databaseKey = Uint8List.fromList(keyManager.dbKey);

      await keyManager.changePassphrase(
        currentPassphrase: originalPassphrase,
        newPassphrase: replacementPassphrase,
      );

      expect(keyManager.dbKey, databaseKey);
      expect(
        await keyManager.verifyPassphrase(passphrase: originalPassphrase),
        isFalse,
      );
      expect(
        await keyManager.verifyPassphrase(passphrase: replacementPassphrase),
        isTrue,
      );
      await keyManager.lock();
      expect(
        await keyManager.unlock(passphrase: replacementPassphrase),
        isTrue,
      );
      expect(keyManager.dbKey, databaseKey);

      final material = await keyManager.exportBackupMaterial();
      final restored = KeyManager(
        secureStorage: _MockSecureStorage()..configure(),
      );
      await restored.restoreBackupMaterial(material);
      expect(await restored.unlock(passphrase: replacementPassphrase), isTrue);
      expect(restored.dbKey, databaseKey);
      expect(secureStorage.values.containsKey('insur.master_key.v1'), isFalse);

      material.clear();
      databaseKey.fillRange(0, databaseKey.length, 0);
    },
  );

  test(
    'migrates legacy direct master-key storage after successful login',
    () async {
      final salt = Kdf.generateSalt();
      final legacyMasterKey = await Kdf.deriveMasterKey(
        passphrase: originalPassphrase,
        salt: salt,
      );
      final databaseKey = await SubKeyDeriver.deriveDbKey(legacyMasterKey);
      secureStorage.values
        ..['insur.master_key.v1'] = base64Encode(legacyMasterKey)
        ..['insur.master_salt.v1'] = base64Encode(salt)
        ..['insur.kdf_params.v1'] = Kdf.paramsDescription();

      expect(await keyManager.unlock(passphrase: originalPassphrase), isTrue);
      expect(secureStorage.values.containsKey('insur.wrapped_mk.v2'), isTrue);
      expect(secureStorage.values.containsKey('insur.master_key.v1'), isFalse);
      expect(keyManager.dbKey, databaseKey);

      salt.fillRange(0, salt.length, 0);
      legacyMasterKey.fillRange(0, legacyMasterKey.length, 0);
      databaseKey.fillRange(0, databaseKey.length, 0);
    },
  );

  test('migration preserves a stable legacy master key and verifier', () async {
    final legacyMasterKey = Kdf.generateMasterKey();
    final salt = Kdf.generateSalt();
    final verifier = await Kdf.derivePassphraseKey(
      passphrase: originalPassphrase,
      salt: salt,
    );
    final verifierCredential = Uint8List.fromList(<int>[...salt, ...verifier]);
    final databaseKey = await SubKeyDeriver.deriveDbKey(legacyMasterKey);
    secureStorage.values
      ..['insur.master_key.v1'] = base64Encode(legacyMasterKey)
      ..['insur.master_salt.v1'] = base64Encode(salt)
      ..['insur.passphrase_credential.v1'] = base64Encode(verifierCredential)
      ..['insur.kdf_params.v1'] = Kdf.paramsDescription();

    expect(await keyManager.unlock(passphrase: originalPassphrase), isTrue);
    expect(keyManager.dbKey, databaseKey);
    expect(secureStorage.values.containsKey('insur.wrapped_mk.v2'), isTrue);
    expect(secureStorage.values.containsKey('insur.master_key.v1'), isFalse);

    legacyMasterKey.fillRange(0, legacyMasterKey.length, 0);
    salt.fillRange(0, salt.length, 0);
    verifier.fillRange(0, verifier.length, 0);
    verifierCredential.fillRange(0, verifierCredential.length, 0);
    databaseKey.fillRange(0, databaseKey.length, 0);
  });

  test(
    'preserves legacy key when credential migration cannot be persisted',
    () async {
      final salt = Kdf.generateSalt();
      final legacyMasterKey = await Kdf.deriveMasterKey(
        passphrase: originalPassphrase,
        salt: salt,
      );
      secureStorage.values
        ..['insur.master_key.v1'] = base64Encode(legacyMasterKey)
        ..['insur.master_salt.v1'] = base64Encode(salt)
        ..['insur.kdf_params.v1'] = Kdf.paramsDescription();
      secureStorage.failWriteKey = 'insur.wrapped_mk.v2';

      await expectLater(
        keyManager.unlock(passphrase: originalPassphrase),
        throwsStateError,
      );
      expect(secureStorage.values['insur.master_key.v1'], isNotNull);
      expect(secureStorage.values.containsKey('insur.wrapped_mk.v2'), isFalse);
      expect(keyManager.isUnlocked, isFalse);

      salt.fillRange(0, salt.length, 0);
      legacyMasterKey.fillRange(0, legacyMasterKey.length, 0);
    },
  );

  test(
    'migrates the prior wrapped credential and AAD without changing MK',
    () async {
      await keyManager.setup(passphrase: originalPassphrase);
      final material = await keyManager.exportBackupMaterial();
      final databaseKey = Uint8List.fromList(keyManager.dbKey);
      final currentCredential = material.wrappedPassphraseCredential!;
      final salt = Uint8List.fromList(currentCredential.sublist(0, 32));
      final kek = await Kdf.derivePassphraseKey(
        passphrase: originalPassphrase,
        salt: salt,
      );
      final nonce = List<int>.filled(12, 0x5a);
      final box = await AesGcm.with256bits().encrypt(
        material.masterKey,
        secretKey: SecretKey(kek),
        nonce: nonce,
        aad: utf8.encode('insur/master-key/passphrase/v2'),
      );
      final previousCredential = Uint8List.fromList(<int>[
        ...salt,
        ...box.nonce,
        ...box.cipherText,
        ...box.mac.bytes,
      ]);
      secureStorage.values
        ..remove('insur.wrapped_mk.v2')
        ..['insur.master_key_credential.v2'] = base64Encode(previousCredential)
        ..['insur.kdf_params.v1'] = Kdf.paramsDescription();

      await keyManager.lock();
      expect(await keyManager.unlock(passphrase: originalPassphrase), isTrue);
      expect(secureStorage.values.containsKey('insur.wrapped_mk.v2'), isTrue);
      expect(
        secureStorage.values.containsKey('insur.master_key_credential.v2'),
        isFalse,
      );
      expect(keyManager.dbKey, databaseKey);

      material.clear();
      salt.fillRange(0, salt.length, 0);
      kek.fillRange(0, kek.length, 0);
      previousCredential.fillRange(0, previousCredential.length, 0);
      databaseKey.fillRange(0, databaseKey.length, 0);
    },
  );

  test(
    'biometric enrollment is retained but unlock remains deferred',
    () async {
      await keyManager.setup(passphrase: originalPassphrase);
      expect(await keyManager.isBiometricEnabled(), isFalse);
      await expectLater(
        keyManager.unlockWithBiometric(),
        throwsUnsupportedError,
      );

      await keyManager.setBiometricEnabled(enabled: true);
      expect(await keyManager.isBiometricEnabled(), isTrue);
      await keyManager.setBiometricEnabled(enabled: false);
      expect(await keyManager.isBiometricEnabled(), isFalse);
    },
  );

  test('rejects a tampered wrapped master key', () async {
    await keyManager.setup(passphrase: originalPassphrase);
    final credential = base64Decode(
      secureStorage.values['insur.wrapped_mk.v2']!,
    );
    credential[Kdf.saltLength + 12] ^= 1;
    secureStorage.values['insur.wrapped_mk.v2'] = base64Encode(credential);

    expect(await keyManager.unlock(passphrase: originalPassphrase), isFalse);
    expect(keyManager.isUnlocked, isFalse);
    credential.fillRange(0, credential.length, 0);
  });

  test('recovery requires and accepts a replacement passphrase', () async {
    await keyManager.setup(passphrase: originalPassphrase);
    final databaseKey = Uint8List.fromList(keyManager.dbKey);
    final recoveryKey = await keyManager.setupRecoveryKey(
      passphrase: originalPassphrase,
    );

    await keyManager.lock();
    expect(await keyManager.recoveryKeyLogin(recoveryKey: recoveryKey), isTrue);
    expect(await keyManager.isPassphraseResetRequired(), isTrue);
    expect(keyManager.dbKey, databaseKey);
    await expectLater(
      keyManager.unlock(passphrase: originalPassphrase),
      throwsStateError,
    );
    expect(await keyManager.recoveryKeyLogin(recoveryKey: recoveryKey), isTrue);

    await keyManager.setPassphraseAfterRecovery(
      newPassphrase: replacementPassphrase,
    );

    expect(await keyManager.isPassphraseResetRequired(), isFalse);
    await keyManager.lock();
    expect(await keyManager.unlock(passphrase: replacementPassphrase), isTrue);
    expect(keyManager.dbKey, databaseKey);
    databaseKey.fillRange(0, databaseKey.length, 0);
  });
}
