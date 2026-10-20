import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> values = <String, String>{};

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
      values[invocation.namedArguments[#key] as String] =
          invocation.namedArguments[#value] as String;
    });
    when(() => delete(key: any(named: 'key'))).thenAnswer((invocation) async {
      values.remove(invocation.namedArguments[#key] as String);
    });
  }
}

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  const originalPassphrase = 'synthetic original passphrase';
  const replacementPassphrase = 'synthetic replacement passphrase';

  late _MockSecureStorage secureStorage;
  late KeyManager keyManager;

  setUp(() {
    secureStorage = _MockSecureStorage()..configure();
    keyManager = KeyManager(
      secureStorage: secureStorage,
      localAuth: _MockLocalAuthentication(),
    );
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
        localAuth: _MockLocalAuthentication(),
      );
      await restored.restoreBackupMaterial(material);
      expect(await restored.unlock(passphrase: replacementPassphrase), isTrue);
      expect(restored.dbKey, databaseKey);

      material.clear();
      databaseKey.fillRange(0, databaseKey.length, 0);
    },
  );

  test(
    'migrates a legacy verifier after successful passphrase login',
    () async {
      await keyManager.setup(passphrase: originalPassphrase);
      secureStorage.values.remove('insur.passphrase_credential.v1');

      await keyManager.lock();
      expect(await keyManager.unlock(passphrase: originalPassphrase), isTrue);
      expect(
        secureStorage.values.containsKey('insur.passphrase_credential.v1'),
        isTrue,
      );
    },
  );

  test('biometric unlock requires explicit enrollment on the device', () async {
    await keyManager.setup(passphrase: originalPassphrase);
    expect(await keyManager.isBiometricEnabled(), isFalse);
    expect(await keyManager.unlockWithBiometric(), isFalse);

    await keyManager.setBiometricEnabled(enabled: true);
    expect(await keyManager.isBiometricEnabled(), isTrue);
    await keyManager.setBiometricEnabled(enabled: false);
    expect(await keyManager.isBiometricEnabled(), isFalse);
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
