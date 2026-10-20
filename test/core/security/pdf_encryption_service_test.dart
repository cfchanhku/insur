import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/pdf_encryption_exception.dart';
import 'package:insur/core/security/pdf_encryption_service.dart';

void main() {
  group('PdfEncryptionService', () {
    test('rejects a password shorter than eight characters', () async {
      await expectLater(
        PdfEncryptionService.encrypt(
          rawPdfBytes: Uint8List.fromList(<int>[1]),
          userPassword: 'short',
        ),
        throwsA(isA<PdfEncryptionException>()),
      );
    });

    test('rejects empty PDF data', () async {
      await expectLater(
        PdfEncryptionService.encrypt(
          rawPdfBytes: Uint8List(0),
          userPassword: 'synthetic-passphrase',
        ),
        throwsA(isA<PdfEncryptionException>()),
      );
    });

    test('returns a typed failure for invalid PDF data', () async {
      await expectLater(
        PdfEncryptionService.encrypt(
          rawPdfBytes: Uint8List.fromList(<int>[1, 2, 3]),
          userPassword: 'synthetic-passphrase',
        ),
        throwsA(isA<PdfEncryptionException>()),
      );
    });
  });
}
