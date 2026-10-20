import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/key_manager.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  test('setup, lock, and unlock preserve the vault database key', () async {
    final storage = FakeSecureStorage();
    final keyManager = KeyManager(secureStorage: storage);
    await keyManager.setup(passphrase: 'synthetic passphrase 1234');
    final expectedDbKey = Uint8List.fromList(keyManager.dbKey);

    await keyManager.lock();
    expect(keyManager.state, KeyManagerState.locked);
    expect(() => keyManager.dbKey, throwsStateError);

    expect(
      await keyManager.unlock(passphrase: 'synthetic passphrase 1234'),
      isTrue,
    );
    expect(keyManager.state, KeyManagerState.unlocked);
    expect(keyManager.dbKey, expectedDbKey);

    expectedDbKey.fillRange(0, expectedDbKey.length, 0);
  });
}
