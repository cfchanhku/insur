import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/security/key_manager.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  test('emits lifecycle audit events without passphrase data', () async {
    const passphrase = 'synthetic passphrase 1234';
    final storage = FakeSecureStorage();
    final keyManager = KeyManager(secureStorage: storage);
    final events = <(AuditEventType, Map<String, Object?>?)>[];
    keyManager.onAudit = (eventType, {metadata}) {
      events.add((eventType, metadata));
    };

    await keyManager.setup(passphrase: passphrase);
    await keyManager.lock();
    expect(
      await keyManager.unlock(passphrase: 'synthetic incorrect 123'),
      isFalse,
    );
    expect(await keyManager.unlock(passphrase: passphrase), isTrue);
    await keyManager.lock();
    await keyManager.logout();

    expect(events.map((event) => event.$1), <AuditEventType>[
      AuditEventType.appSetup,
      AuditEventType.autoLock,
      AuditEventType.loginFail,
      AuditEventType.loginSuccess,
      AuditEventType.autoLock,
      AuditEventType.logout,
    ]);
    expect(events[2].$2, <String, Object?>{'attempts': 1});
    expect(events[2].$2.toString(), isNot(contains(passphrase)));
  });

  test(
    'passphrase change emits its event only after a successful change',
    () async {
      final storage = FakeSecureStorage();
      final keyManager = KeyManager(secureStorage: storage);
      final events = <AuditEventType>[];
      keyManager.onAudit = (eventType, {metadata}) => events.add(eventType);
      await keyManager.setup(passphrase: 'synthetic passphrase 1234');
      events.clear();

      await expectLater(
        keyManager.changePassphrase(
          currentPassphrase: 'synthetic incorrect 123',
          newPassphrase: 'synthetic replacement 1234',
        ),
        throwsStateError,
      );
      expect(events, isEmpty);

      await keyManager.changePassphrase(
        currentPassphrase: 'synthetic passphrase 1234',
        newPassphrase: 'synthetic replacement 1234',
      );
      expect(events, <AuditEventType>[AuditEventType.passphraseChanged]);
    },
  );
}
