import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/key_manager.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  test(
    'biometric enrollment is stored while biometric unlock remains deferred',
    () async {
      final storage = FakeSecureStorage();
      final keyManager = KeyManager(secureStorage: storage);
      await keyManager.setup(passphrase: 'synthetic passphrase 1234');

      expect(await keyManager.isBiometricEnabled(), isFalse);
      await keyManager.setBiometricEnabled(enabled: true);
      expect(await keyManager.isBiometricEnabled(), isTrue);

      await expectLater(
        keyManager.unlockWithBiometric(),
        throwsUnsupportedError,
      );
      expect(keyManager.state, KeyManagerState.locked);

      await keyManager.setBiometricEnabled(enabled: false);
      expect(await keyManager.isBiometricEnabled(), isFalse);
    },
  );
}
