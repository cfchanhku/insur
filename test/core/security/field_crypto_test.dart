import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/field_crypto.dart';
import 'package:insur/core/security/field_crypto_exception.dart';

void main() {
  const recordId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
  const entityType = 'client';
  const fieldName = 'name';
  const keyByte = 0x42;
  late Uint8List fieldKey;
  late FieldCrypto fieldCrypto;

  setUp(() {
    fieldKey = Uint8List.fromList(List<int>.filled(32, keyByte));
    fieldCrypto = FieldCrypto(fieldKey: fieldKey);
  });

  group('FieldCrypto constants', () {
    test('uses a 32-byte key', () {
      expect(FieldCrypto.keyLength, 32);
    });

    test('uses a 12-byte nonce', () {
      expect(FieldCrypto.nonceLength, 12);
    });

    test('uses a 16-byte authentication tag', () {
      expect(FieldCrypto.tagLength, 16);
    });
  });

  group('FieldCrypto constructor — validation', () {
    test('rejects a 16-byte key', () {
      expect(
        () => FieldCrypto(fieldKey: Uint8List(16)),
        throwsArgumentError,
      );
    });

    test('rejects a 64-byte key', () {
      expect(
        () => FieldCrypto(fieldKey: Uint8List(64)),
        throwsArgumentError,
      );
    });

    test('accepts a 32-byte key', () {
      expect(() => FieldCrypto(fieldKey: fieldKey), returnsNormally);
    });
  });

  group('FieldCrypto.encrypt — output format', () {
    test('returns valid base64', () async {
      final ciphertext = await fieldCrypto.encrypt(
        plaintext: 'synthetic value',
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );

      expect(base64Decode(ciphertext), isA<Uint8List>());
    });

    test('includes at least the nonce and authentication tag', () async {
      final ciphertext = await fieldCrypto.encrypt(
        plaintext: '',
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );

      expect(
        base64Decode(ciphertext),
        hasLength(FieldCrypto.nonceLength + FieldCrypto.tagLength),
      );
    });

    test('uses a new nonce and output for each encryption', () async {
      final first = await fieldCrypto.encrypt(
        plaintext: 'same value',
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );
      final second = await fieldCrypto.encrypt(
        plaintext: 'same value',
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );

      expect(first, isNot(second));
      expect(
        base64Decode(first).sublist(0, FieldCrypto.nonceLength),
        isNot(base64Decode(second).sublist(0, FieldCrypto.nonceLength)),
      );
    });

    test('stores nonce first and tag last', () async {
      const plaintext = 'layout check';
      final ciphertext = await fieldCrypto.encrypt(
        plaintext: plaintext,
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );
      final bytes = base64Decode(ciphertext);

      expect(
          bytes,
          hasLength(FieldCrypto.nonceLength +
              utf8.encode(plaintext).length +
              FieldCrypto.tagLength));
      expect(
        bytes.sublist(0, FieldCrypto.nonceLength),
        hasLength(FieldCrypto.nonceLength),
      );
      expect(
        bytes.sublist(bytes.length - FieldCrypto.tagLength),
        hasLength(FieldCrypto.tagLength),
      );
    });
  });

  group('FieldCrypto.encrypt/decrypt — round trip', () {
    test('round-trips a name', () async {
      await _expectRoundTrip(fieldCrypto, plaintext: 'John Doe');
    });

    test('round-trips an empty string', () async {
      await _expectRoundTrip(fieldCrypto, plaintext: '');
    });

    test('round-trips Traditional Chinese', () async {
      await _expectRoundTrip(fieldCrypto, plaintext: '陳大文');
    });

    test('round-trips emoji', () async {
      await _expectRoundTrip(fieldCrypto, plaintext: '🔒 secure');
    });

    test('round-trips a 10,000-character string', () async {
      await _expectRoundTrip(
        fieldCrypto,
        plaintext: List<String>.filled(10000, 'x').join(),
      );
    });

    test('round-trips fields with underscores', () async {
      for (final field in <String>['policy_no', 'coverage_amount']) {
        final encrypted = await fieldCrypto.encrypt(
          plaintext: 'synthetic value',
          entityType: entityType,
          fieldName: field,
          recordId: recordId,
        );

        expect(
          await fieldCrypto.decrypt(
            ciphertext: encrypted,
            entityType: entityType,
            fieldName: field,
            recordId: recordId,
          ),
          'synthetic value',
        );
      }
    });
  });

  group('FieldCrypto — AAD binding (critical)', () {
    test('rejects a different entity type', () async {
      await _expectAadFailure(
        fieldCrypto,
        decryptEntityType: 'policy',
      );
    });

    test('rejects a different field name', () async {
      await _expectAadFailure(
        fieldCrypto,
        decryptFieldName: 'email',
      );
    });

    test('rejects a different record ID', () async {
      await _expectAadFailure(
        fieldCrypto,
        encryptRecordId: 'abc',
        decryptRecordId: 'def',
      );
    });

    test('rejects null record ID decrypted with a record ID', () async {
      await _expectAadFailure(
        fieldCrypto,
        encryptRecordId: null,
        decryptRecordId: 'abc',
      );
    });

    test('rejects a record ID decrypted with null record ID', () async {
      await _expectAadFailure(
        fieldCrypto,
        encryptRecordId: 'abc',
        decryptRecordId: null,
      );
    });
  });

  group('FieldCrypto.decrypt — tampering detection', () {
    test('rejects a changed ciphertext byte', () async {
      final bytes = await _encryptedBytes(fieldCrypto);
      bytes[FieldCrypto.nonceLength] ^= 0x01;
      await _expectTamperedInputRejected(fieldCrypto, bytes);
    });

    test('rejects a changed nonce byte', () async {
      final bytes = await _encryptedBytes(fieldCrypto);
      bytes[0] ^= 0x01;
      await _expectTamperedInputRejected(fieldCrypto, bytes);
    });

    test('rejects a changed authentication tag byte', () async {
      final bytes = await _encryptedBytes(fieldCrypto);
      bytes[bytes.length - 1] ^= 0x01;
      await _expectTamperedInputRejected(fieldCrypto, bytes);
    });

    test('rejects truncated input', () async {
      final bytes = await _encryptedBytes(fieldCrypto);
      bytes.removeLast();
      await _expectTamperedInputRejected(fieldCrypto, bytes);
    });

    test('rejects appended bytes', () async {
      final bytes = await _encryptedBytes(fieldCrypto);
      bytes.add(0x01);
      await _expectTamperedInputRejected(fieldCrypto, bytes);
    });

    test('rejects invalid base64', () async {
      await expectLater(
        fieldCrypto.decrypt(
          ciphertext: 'not valid base64!',
          entityType: entityType,
          fieldName: fieldName,
          recordId: recordId,
        ),
        throwsA(isA<FieldCryptoException>()),
      );
    });
  });

  group('FieldCrypto — wrong key', () {
    test('rejects ciphertext encrypted with another key', () async {
      final ciphertext = await fieldCrypto.encrypt(
        plaintext: 'synthetic value',
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );
      final otherKey = Uint8List.fromList(List<int>.filled(32, 0x43));
      final otherCrypto = FieldCrypto(fieldKey: otherKey);

      await expectLater(
        otherCrypto.decrypt(
          ciphertext: ciphertext,
          entityType: entityType,
          fieldName: fieldName,
          recordId: recordId,
        ),
        throwsA(isA<FieldCryptoException>()),
      );
    });
  });

  group('FieldCrypto — null handling', () {
    test('encryptNullable returns null for null input', () async {
      expect(
        await fieldCrypto.encryptNullable(
          plaintext: null,
          entityType: entityType,
          fieldName: fieldName,
        ),
        isNull,
      );
    });

    test('decryptNullable returns null for null input', () async {
      expect(
        await fieldCrypto.decryptNullable(
          ciphertext: null,
          entityType: entityType,
          fieldName: fieldName,
        ),
        isNull,
      );
    });

    test('encryptNullable encrypts a non-null value', () async {
      expect(
        await fieldCrypto.encryptNullable(
          plaintext: 'value',
          entityType: entityType,
          fieldName: fieldName,
          recordId: recordId,
        ),
        isNotNull,
      );
    });

    test('decryptNullable decrypts a non-null value', () async {
      final encrypted = await fieldCrypto.encryptNullable(
        plaintext: 'value',
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );

      expect(
        await fieldCrypto.decryptNullable(
          ciphertext: encrypted,
          entityType: entityType,
          fieldName: fieldName,
          recordId: recordId,
        ),
        'value',
      );
    });
  });

  group('FieldCrypto — security hygiene', () {
    test('parameter description contains no key bytes', () {
      expect(
        FieldCrypto.paramsDescription(),
        isNot(contains(base64Encode(fieldKey))),
      );
    });

    test('exception string contains no sensitive supplied values', () {
      const plaintext = 'private synthetic plaintext';
      const ciphertext = 'private synthetic ciphertext';
      const error = FieldCryptoException('Authentication failed');

      expect(error.toString(), isNot(contains(plaintext)));
      expect(error.toString(), isNot(contains(ciphertext)));
      expect(error.toString(), isNot(contains(base64Encode(fieldKey))));
    });

    test('encrypted output does not contain the plaintext bytes', () async {
      const plaintext = 'John Doe';
      final ciphertext = await fieldCrypto.encrypt(
        plaintext: plaintext,
        entityType: entityType,
        fieldName: fieldName,
        recordId: recordId,
      );
      final bytes = base64Decode(ciphertext);
      final plaintextBytes = utf8.encode(plaintext);

      expect(_containsSequence(bytes, plaintextBytes), isFalse);
    });
  });
}

Future<void> _expectRoundTrip(
  FieldCrypto fieldCrypto, {
  required String plaintext,
}) async {
  final ciphertext = await fieldCrypto.encrypt(
    plaintext: plaintext,
    entityType: 'client',
    fieldName: 'name',
    recordId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
  );

  expect(
    await fieldCrypto.decrypt(
      ciphertext: ciphertext,
      entityType: 'client',
      fieldName: 'name',
      recordId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    ),
    plaintext,
  );
}

Future<void> _expectAadFailure(
  FieldCrypto fieldCrypto, {
  String encryptEntityType = 'client',
  String decryptEntityType = 'client',
  String encryptFieldName = 'name',
  String decryptFieldName = 'name',
  String? encryptRecordId = 'record',
  String? decryptRecordId = 'record',
}) async {
  final ciphertext = await fieldCrypto.encrypt(
    plaintext: 'synthetic value',
    entityType: encryptEntityType,
    fieldName: encryptFieldName,
    recordId: encryptRecordId,
  );

  await expectLater(
    fieldCrypto.decrypt(
      ciphertext: ciphertext,
      entityType: decryptEntityType,
      fieldName: decryptFieldName,
      recordId: decryptRecordId,
    ),
    throwsA(isA<FieldCryptoException>()),
  );
}

Future<List<int>> _encryptedBytes(FieldCrypto fieldCrypto) async {
  final encrypted = await fieldCrypto.encrypt(
    plaintext: 'synthetic value',
    entityType: 'client',
    fieldName: 'name',
    recordId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
  );
  return base64Decode(encrypted).toList();
}

Future<void> _expectTamperedInputRejected(
  FieldCrypto fieldCrypto,
  List<int> bytes,
) async {
  await expectLater(
    fieldCrypto.decrypt(
      ciphertext: base64Encode(bytes),
      entityType: 'client',
      fieldName: 'name',
      recordId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    ),
    throwsA(isA<FieldCryptoException>()),
  );
}

bool _containsSequence(List<int> bytes, List<int> sequence) {
  for (var start = 0; start <= bytes.length - sequence.length; start++) {
    var matches = true;
    for (var offset = 0; offset < sequence.length; offset++) {
      if (bytes[start + offset] != sequence[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}
