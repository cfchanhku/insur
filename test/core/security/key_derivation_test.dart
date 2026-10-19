import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/key_derivation.dart';

void main() {
  late Uint8List masterKey;

  setUp(() {
    masterKey = Uint8List.fromList(List<int>.filled(32, 0x01));
  });

  group('SubKeyDeriver constants', () {
    test('uses a versioned database domain', () {
      expect(SubKeyDeriver.domainDb, 'insur/db/v1');
    });

    test('uses a versioned field domain', () {
      expect(SubKeyDeriver.domainField, 'insur/field/v1');
    });

    test('uses a versioned audit domain', () {
      expect(SubKeyDeriver.domainAudit, 'insur/audit/v1');
    });

    test('derives 32-byte subkeys', () {
      expect(SubKeyDeriver.subKeyLength, 32);
    });
  });

  group('SubKeyDeriver — input validation', () {
    test('rejects a 16-byte master key', () {
      expect(
        () => SubKeyDeriver.deriveSubKey(
          masterKey: Uint8List(16),
          domain: 'test/v1',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a 64-byte master key', () {
      expect(
        () => SubKeyDeriver.deriveSubKey(
          masterKey: Uint8List(64),
          domain: 'test/v1',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty master key', () {
      expect(
        () => SubKeyDeriver.deriveSubKey(
          masterKey: Uint8List(0),
          domain: 'test/v1',
        ),
        throwsArgumentError,
      );
    });

    test('accepts a 32-byte master key', () async {
      final key = await SubKeyDeriver.deriveSubKey(
        masterKey: masterKey,
        domain: 'test/v1',
      );

      expect(key, hasLength(SubKeyDeriver.subKeyLength));
    });
  });

  group('SubKeyDeriver — determinism', () {
    test('derives the same subkey for the same key and domain', () async {
      final first = await SubKeyDeriver.deriveSubKey(
        masterKey: masterKey,
        domain: 'test/v1',
      );
      final second = await SubKeyDeriver.deriveSubKey(
        masterKey: masterKey,
        domain: 'test/v1',
      );

      expect(_sameBytes(second, first), isTrue);
    });

    test('derives different subkeys for different domains', () async {
      final dbKey = await SubKeyDeriver.deriveDbKey(masterKey);
      final fieldKey = await SubKeyDeriver.deriveFieldKey(masterKey);
      final auditKey = await SubKeyDeriver.deriveAuditKey(masterKey);

      expect(_sameBytes(dbKey, fieldKey), isFalse);
      expect(_sameBytes(dbKey, auditKey), isFalse);
      expect(_sameBytes(fieldKey, auditKey), isFalse);
    });

    test('derives a different subkey for a different master key', () async {
      final otherMasterKey = Uint8List.fromList(masterKey)..[0] = 0x02;
      final first = await SubKeyDeriver.deriveSubKey(
        masterKey: masterKey,
        domain: 'test/v1',
      );
      final second = await SubKeyDeriver.deriveSubKey(
        masterKey: otherMasterKey,
        domain: 'test/v1',
      );

      expect(_sameBytes(second, first), isFalse);
    });
  });

  group('SubKeyDeriver — output length', () {
    test('database key has the configured length', () async {
      expect(
        await SubKeyDeriver.deriveDbKey(masterKey),
        hasLength(SubKeyDeriver.subKeyLength),
      );
    });

    test('field key has the configured length', () async {
      expect(
        await SubKeyDeriver.deriveFieldKey(masterKey),
        hasLength(SubKeyDeriver.subKeyLength),
      );
    });

    test('audit key has the configured length', () async {
      expect(
        await SubKeyDeriver.deriveAuditKey(masterKey),
        hasLength(SubKeyDeriver.subKeyLength),
      );
    });

    test('custom domain key has the configured length', () async {
      expect(
        await SubKeyDeriver.deriveSubKey(
          masterKey: masterKey,
          domain: 'custom/v1',
        ),
        hasLength(SubKeyDeriver.subKeyLength),
      );
    });
  });

  group('SubKeyDeriver — domain separation (critical)', () {
    test('database and field keys are distinct', () async {
      expect(
        _sameBytes(
          await SubKeyDeriver.deriveDbKey(masterKey),
          await SubKeyDeriver.deriveFieldKey(masterKey),
        ),
        isFalse,
      );
    });

    test('database and audit keys are distinct', () async {
      expect(
        _sameBytes(
          await SubKeyDeriver.deriveDbKey(masterKey),
          await SubKeyDeriver.deriveAuditKey(masterKey),
        ),
        isFalse,
      );
    });

    test('field and audit keys are distinct', () async {
      expect(
        _sameBytes(
          await SubKeyDeriver.deriveFieldKey(masterKey),
          await SubKeyDeriver.deriveAuditKey(masterKey),
        ),
        isFalse,
      );
    });
  });

  group('SubKeyDeriver — known test vector (RFC 5869)', () {
    test('matches RFC 5869 test case 1 using the library directly', () async {
      // Test the underlying library directly because the wrapper deliberately
      // uses an empty salt and a fixed 32-byte output length.
      final ikm = Uint8List.fromList(List<int>.filled(22, 0x0b));
      final salt = Uint8List.fromList(
        List<int>.generate(13, (int index) => index),
      );
      final info = Uint8List.fromList(
        List<int>.generate(10, (int index) => 0xf0 + index),
      );
      final hkdf = Hkdf(
        hmac: Hmac.sha256(),
        outputLength: 42,
      );
      final derived = await hkdf.deriveKey(
        secretKey: SecretKey(ikm),
        nonce: salt,
        info: info,
      );

      expect(
        await derived.extractBytes(),
        _decodeHex(
          '3cb25f25faacd57a90434f64d0362f2a'
          '2d2d0a90cf1a5a4c5db02d56ecc4c5bf'
          '34007208d5b887185865',
        ),
      );
    });

    test('custom domain derivation is 32 bytes and deterministic', () async {
      final first = await SubKeyDeriver.deriveSubKey(
        masterKey: masterKey,
        domain: 'test/v1',
      );
      final second = await SubKeyDeriver.deriveSubKey(
        masterKey: masterKey,
        domain: 'test/v1',
      );

      expect(first, hasLength(32));
      expect(_sameBytes(second, first), isTrue);
    });
  });

  group('SubKeyDeriver — security hygiene', () {
    test('derived keys do not equal the master key', () async {
      final dbKey = await SubKeyDeriver.deriveDbKey(masterKey);
      final fieldKey = await SubKeyDeriver.deriveFieldKey(masterKey);
      final auditKey = await SubKeyDeriver.deriveAuditKey(masterKey);

      expect(_sameBytes(dbKey, masterKey), isFalse);
      expect(_sameBytes(fieldKey, masterKey), isFalse);
      expect(_sameBytes(auditKey, masterKey), isFalse);
    });

    test('domain-derived keys are mutually distinct', () async {
      final dbKey = await SubKeyDeriver.deriveDbKey(masterKey);
      final fieldKey = await SubKeyDeriver.deriveFieldKey(masterKey);
      final auditKey = await SubKeyDeriver.deriveAuditKey(masterKey);

      expect(_sameBytes(dbKey, fieldKey), isFalse);
      expect(_sameBytes(dbKey, auditKey), isFalse);
      expect(_sameBytes(fieldKey, auditKey), isFalse);
    });
  });
}

bool _sameBytes(Uint8List left, Uint8List right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

List<int> _decodeHex(String value) {
  return <int>[
    for (int index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ];
}
