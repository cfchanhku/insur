import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/crockford_base32.dart';

void main() {
  group('CrockfordBase32 encode/decode round trip', () {
    test('round-trips arbitrary bytes', () {
      final bytes = Uint8List.fromList(
        List<int>.generate(20, (int index) => (index * 13) & 0xff),
      );

      expect(CrockfordBase32.decode(CrockfordBase32.encode(bytes)), bytes);
    });

    test('encodes empty input as an empty string', () {
      expect(CrockfordBase32.encode(Uint8List(0)), isEmpty);
    });

    test('decodes an empty string as empty bytes', () {
      expect(CrockfordBase32.decode(''), isEmpty);
    });

    test('encodes zero byte using the published bit ordering', () {
      expect(CrockfordBase32.encode(Uint8List.fromList(<int>[0x00])), '00');
    });

    test('encodes 0xFF as ZW with zero-padded trailing bits', () {
      expect(CrockfordBase32.encode(Uint8List.fromList(<int>[0xff])), 'ZW');
    });
  });

  group('CrockfordBase32 decode — normalization', () {
    test('accepts lowercase input', () {
      expect(CrockfordBase32.decode('000g'), CrockfordBase32.decode('000G'));
    });

    test('ignores hyphens', () {
      expect(CrockfordBase32.decode('00-0G'), CrockfordBase32.decode('000G'));
    });

    test('ignores spaces', () {
      expect(CrockfordBase32.decode('00 0G'), CrockfordBase32.decode('000G'));
    });

    test('maps O to zero', () {
      expect(CrockfordBase32.decode('O0'), CrockfordBase32.decode('00'));
    });

    test('maps I to one', () {
      expect(CrockfordBase32.decode('I0'), CrockfordBase32.decode('10'));
    });

    test('maps L to one', () {
      expect(CrockfordBase32.decode('L0'), CrockfordBase32.decode('10'));
    });

    test('maps U to V', () {
      expect(CrockfordBase32.decode('U0'), CrockfordBase32.decode('V0'));
    });
  });

  group('CrockfordBase32 decode — invalid input', () {
    test('rejects characters outside the alphabet and aliases', () {
      expect(() => CrockfordBase32.decode('!'), throwsFormatException);
    });

    test('rejects non-zero trailing padding bits', () {
      expect(() => CrockfordBase32.decode('01'), throwsFormatException);
    });

    test('isValid returns false for invalid characters', () {
      expect(CrockfordBase32.isValid('bad!'), isFalse);
    });
  });

  group('CrockfordBase32 groupWithHyphens / stripHyphens', () {
    test('groups text every four characters', () {
      expect(CrockfordBase32.groupWithHyphens('ABCDEFGH'), 'ABCD-EFGH');
    });

    test('round-trips grouping and stripping', () {
      const ungrouped = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      expect(
        CrockfordBase32.stripHyphens(
          CrockfordBase32.groupWithHyphens(ungrouped),
        ),
        ungrouped,
      );
    });

    test('rejects a non-positive group size', () {
      expect(
        () => CrockfordBase32.groupWithHyphens('AB', groupSize: 0),
        throwsArgumentError,
      );
    });
  });
}
