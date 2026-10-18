import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/kdf.dart';

void main() {
  group('Kdf.deriveMasterKey', () {
    test('returns a 32-byte key for a valid passphrase and salt', () async {
      final salt = Uint8List.fromList(
        List<int>.generate(32, (int index) => index),
      );

      final key = await Kdf.deriveMasterKey(
        passphrase: 'synthetic test passphrase',
        salt: salt,
      );

      expect(key, hasLength(32));
    });

    test('rejects an empty passphrase', () {
      expect(
        () => Kdf.deriveMasterKey(
          passphrase: '',
          salt: Uint8List(32),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a salt that is not 32 bytes', () {
      expect(
        () => Kdf.deriveMasterKey(
          passphrase: 'synthetic test passphrase',
          salt: Uint8List(31),
        ),
        throwsArgumentError,
      );
    });
  });
}
