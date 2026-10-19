import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/key_manager.dart';

void main() {
  group('KeyManagerState', () {
    test('defines the expected lifecycle states', () {
      expect(
        KeyManagerState.values,
        <KeyManagerState>[
          KeyManagerState.uninitialized,
          KeyManagerState.locked,
          KeyManagerState.unlocked,
        ],
      );
    });
  });
}
