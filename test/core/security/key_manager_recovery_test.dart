import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/security/key_manager.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  test(
    'sets, confirms, and uses a recovery key to reset the passphrase',
    () async {
      const passphrase = 'synthetic passphrase 1234';
      const replacementPassphrase = 'synthetic replacement 1234';
      final storage = FakeSecureStorage();
      final manager = KeyManager(secureStorage: storage);
      final events = <AuditEventType>[];
      manager.onAudit = (eventType, {metadata}) => events.add(eventType);
      await manager.setup(passphrase: passphrase);
      final expectedDbKey = Uint8List.fromList(manager.dbKey);

      final recoveryKey = await manager.setupRecoveryKey(
        passphrase: passphrase,
      );
      expect(
        recoveryKey,
        matches(
          RegExp(r'^[0-9A-HJKMNPQRSTVWXYZ]{4}(-[0-9A-HJKMNPQRSTVWXYZ]{4}){7}$'),
        ),
      );
      expect(await manager.hasRecoveryKey(), isTrue);
      expect(storage.hasKey('insur.recovery.salt.v1'), isTrue);
      expect(storage.hasKey('insur.recovery.verification_hash.v1'), isTrue);
      expect(storage.hasKey('insur.recovery.wrapped_mk.v1'), isTrue);
      expect(
        await manager.confirmRecoveryKey(recoveryKey: recoveryKey),
        isTrue,
      );
      expect(
        await manager.confirmRecoveryKey(recoveryKey: 'not-a-recovery-key'),
        isFalse,
      );
      expect(
        await manager.confirmRecoveryKey(
          recoveryKey: '1123-4567-89AB-CDEF-GHJK-MNPQ-RSTV-WXYZ',
        ),
        isFalse,
      );

      await manager.lock();
      final recoveryLoginManager = KeyManager(secureStorage: storage)
        ..onAudit = (eventType, {metadata}) {
          events.add(eventType);
        };
      expect(
        await recoveryLoginManager.recoveryKeyLogin(recoveryKey: recoveryKey),
        isTrue,
      );
      expect(recoveryLoginManager.dbKey, expectedDbKey);
      expect(await recoveryLoginManager.isPassphraseResetRequired(), isTrue);
      await expectLater(
        recoveryLoginManager.unlock(passphrase: passphrase),
        throwsStateError,
      );
      expect(
        await recoveryLoginManager.recoveryKeyLogin(recoveryKey: recoveryKey),
        isTrue,
      );
      await recoveryLoginManager.setPassphraseAfterRecovery(
        newPassphrase: replacementPassphrase,
      );
      expect(await recoveryLoginManager.isPassphraseResetRequired(), isFalse);
      await recoveryLoginManager.lock();
      expect(
        await recoveryLoginManager.unlock(passphrase: replacementPassphrase),
        isTrue,
      );
      expect(recoveryLoginManager.dbKey, expectedDbKey);
      expect(events, contains(AuditEventType.recoveryUsed));
      expect(events, contains(AuditEventType.passphraseChanged));
    },
  );

  test('wrong recovery key fails without unlocking the vault', () async {
    final storage = FakeSecureStorage();
    final manager = KeyManager(secureStorage: storage);
    await manager.setup(passphrase: 'synthetic passphrase 1234');
    final recoveryKey = await manager.setupRecoveryKey(
      passphrase: 'synthetic passphrase 1234',
    );
    await manager.lock();
    final wrongKey = recoveryKey.startsWith('0')
        ? '1${recoveryKey.substring(1)}'
        : '0${recoveryKey.substring(1)}';
    final recoveryLoginManager = KeyManager(secureStorage: storage);

    expect(
      await recoveryLoginManager.recoveryKeyLogin(recoveryKey: wrongKey),
      isFalse,
    );
    expect(recoveryLoginManager.isUnlocked, isFalse);
  });

  test('recovery key rotation invalidates the previous key', () async {
    const passphrase = 'synthetic passphrase 1234';
    final storage = FakeSecureStorage();
    final manager = KeyManager(secureStorage: storage);
    final events = <AuditEventType>[];
    manager.onAudit = (eventType, {metadata}) => events.add(eventType);
    await manager.setup(passphrase: passphrase);
    final oldKey = await manager.setupRecoveryKey(passphrase: passphrase);

    final newKey = await manager.regenerateRecoveryKey(passphrase: passphrase);

    expect(newKey, isNot(oldKey));
    expect(await manager.confirmRecoveryKey(recoveryKey: oldKey), isFalse);
    expect(await manager.confirmRecoveryKey(recoveryKey: newKey), isTrue);
    expect(events, contains(AuditEventType.recoveryKeyRotated));
  });

  test('recovery operations require an unlocked vault', () async {
    final manager = KeyManager(secureStorage: FakeSecureStorage());

    await expectLater(
      manager.setupRecoveryKey(passphrase: 'synthetic passphrase 1234'),
      throwsStateError,
    );
    await expectLater(
      manager.regenerateRecoveryKey(passphrase: 'synthetic passphrase 1234'),
      throwsStateError,
    );
    expect(await manager.hasRecoveryKey(), isFalse);
  });
}
