import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/export/pdf/pdf_exporter.dart';
import 'package:insur/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final languageCode in <String>['en', 'zh-Hant']) {
    test(
      'generates a non-empty $languageCode PDF with synthetic data',
      () async {
        const syntheticClientName = 'Synthetic Client';
        final client = Client(
          role: ClientRole.holder,
          name: syntheticClientName,
          gender: Gender.other,
          dob: DateTime.utc(1990),
          phone: null,
          email: null,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          archivedAt: null,
        );
        final locale = languageCode == 'zh-Hant'
            ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
            : const Locale('en');
        final l10n = await AppLocalizations.delegate.load(locale);

        final bytes = await PdfExporter.exportBundles(
          bundles: <ClientExportBundle>[
            ClientExportBundle(
              client: client,
              policies: const <PolicyWithPlans>[],
            ),
          ],
          languageCode: languageCode,
          allowPrint: true,
          password: 'synthetic-passphrase',
          l10n: l10n,
        );

        expect(bytes.length, greaterThan(5));
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      },
    );
  }
}
