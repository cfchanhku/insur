import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/export/pdf/pdf_exporter.dart';
import 'package:insur/features/plans/models/plan.dart';
import 'package:insur/features/plans/models/plan_category.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';
import 'package:insur/features/riders/models/rider.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const password = 'synthetic-search-passphrase';

  for (final languageCode in <String>['en', 'zh-Hant']) {
    test('keeps $languageCode plan and insured text searchable', () async {
      final locale = await _localizations(languageCode);
      final insuredName = languageCode == 'en'
          ? 'Synthetic Searchable Insured'
          : '測試受保人';
      final planName = languageCode == 'en'
          ? 'Synthetic Searchable Plan'
          : '測試人壽計劃';
      const insuredId = 'synthetic-insured-id';
      final client = Client(
        role: ClientRole.holder,
        name: 'Synthetic Policy Holder',
        gender: Gender.other,
        dob: DateTime.utc(1980),
        phone: null,
        email: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        archivedAt: null,
      );
      final policy = Policy(
        clientId: 'synthetic-holder-id',
        policyNo: 'SYNTHETIC-SEARCH-POLICY',
        company: 'Synthetic Insurer',
        effectiveDate: DateTime.utc(2020),
        firstPremiumDate: DateTime.utc(2020, 2),
        currency: 'HKD',
        status: PolicyStatus.active,
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2026),
      );
      final plan = Plan(
        policyId: 'synthetic-policy-id',
        insuredId: insuredId,
        category: PlanCategory.life,
        planName: planName,
        coverageAmount: 100000,
      );
      final bundle = ClientExportBundle(
        client: client,
        policies: <PolicyWithPlans>[
          PolicyWithPlans(
            policy: policy,
            plans: <PlanWithRiders>[
              PlanWithRiders(plan: plan, riders: const <Rider>[]),
            ],
          ),
        ],
        insuredNamesById: <String, String>{insuredId: insuredName},
      );

      final bytes = await PdfExporter.exportBundles(
        bundles: <ClientExportBundle>[bundle],
        languageCode: languageCode,
        allowPrint: true,
        password: password,
        l10n: locale,
      );
      final document = PdfDocument(inputBytes: bytes, password: password);
      try {
        final text = PdfTextExtractor(
          document,
        ).extractText().replaceAll(RegExp(r'\s+'), ' ');
        expect(text, contains(planName));
        expect(text, contains(insuredName));
        final insuredLabel = languageCode == 'en' ? 'Insured Name' : '受保人姓名';
        expect(
          RegExp(RegExp.escape(insuredLabel)).allMatches(text).length,
          5,
          reason:
              'The insured label belongs to the five plan sections, not '
              'the personal-information header.',
        );
      } finally {
        document.dispose();
      }
    });
  }
}

Future<AppLocalizations> _localizations(String languageCode) {
  final locale = languageCode == 'zh-Hant'
      ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
      : const Locale('en');
  return AppLocalizations.delegate.load(locale);
}
