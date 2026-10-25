import 'dart:typed_data';

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
  const password = 'synthetic-passphrase';

  for (final languageCode in <String>['en', 'zh-Hant']) {
    test('exports an encrypted $languageCode summary table', () async {
      final locale = await _localizations(languageCode);
      final bytes = await _export(
        <ClientExportBundle>[_bundle('Synthetic Client')],
        languageCode,
        locale,
      );

      expect(bytes.length, greaterThan(5));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(
        () => PdfDocument(inputBytes: bytes),
        throwsA(anything),
        reason: 'The PDF must require a password to open.',
      );
      expect(
        () => PdfDocument(inputBytes: bytes, password: 'wrong-passphrase'),
        throwsA(anything),
        reason: 'The PDF must reject an incorrect password.',
      );

      final document = PdfDocument(inputBytes: bytes, password: password);
      try {
        expect(document.security.algorithm, PdfEncryptionAlgorithm.aesx256Bit);
        final permissions = <PdfPermissionsFlags>[];
        document.security.permissions.forEach(permissions.add);
        expect(
          permissions,
          contains(PdfPermissionsFlags.accessibilityCopyContent),
        );
        expect(permissions, contains(PdfPermissionsFlags.print));
        expect(permissions, isNot(contains(PdfPermissionsFlags.copyContent)));
        expect(permissions, isNot(contains(PdfPermissionsFlags.editContent)));
        expect(
          permissions,
          isNot(contains(PdfPermissionsFlags.editAnnotations)),
        );
        final text = _normalizeText(PdfTextExtractor(document).extractText());
        expect(text, contains(languageCode == 'en' ? 'Policy Data' : '保單資料'));
        expect(text, contains('Synthetic Client'));
        expect(text, contains('Synthetic life plan'));
        expect(text, contains('HKD 100,000.00'));
        expect(document.pages.count, 1);
        expect(
          document.pages[0].size.width,
          greaterThan(document.pages[0].size.height),
        );
      } finally {
        document.dispose();
      }
    });
  }

  test(
    'renders three policy columns and leaves the remaining columns empty',
    () async {
      final locale = await _localizations('en');
      final bundle = _bundle('Three Policy Client', policyCount: 3);
      final bytes = await _export(<ClientExportBundle>[bundle], 'en', locale);
      final result = _readPdf(bytes);

      expect(result.text, contains('Synthetic Policy 1'));
      expect(result.text, contains('Synthetic Policy 2'));
      expect(result.text, contains('Synthetic Policy 3'));
      expect(result.text, isNot(contains('Synthetic Policy 4')));
      expect(result.text, isNot(contains('Synthetic Policy 5')));
      for (var column = 1; column <= 5; column++) {
        expect(result.text, contains('Policy $column'));
      }
      expect(result.pageCount, 1);
    },
  );

  test('paginates six policies into two summary pages', () async {
    final locale = await _localizations('en');
    final bundle = _bundle('Six Policy Client', policyCount: 6);
    final bytes = await _export(<ClientExportBundle>[bundle], 'en', locale);
    final result = _readPdf(bytes);

    expect(result.text, contains('Synthetic Policy 1'));
    expect(result.text, contains('Synthetic Policy 6'));
    expect(result.text, contains('Page 1 of 2'));
    expect(result.text, contains('Page 2 of 2'));
    expect(result.pageCount, 2);
  });

  test('exports one summary page for each selected client', () async {
    final locale = await _localizations('en');
    final bytes = await _export(
      <ClientExportBundle>[
        _bundle('First Synthetic Client'),
        _bundle('Second Synthetic Client'),
      ],
      'en',
      locale,
    );
    final result = _readPdf(bytes);

    expect(result.text, contains('First Synthetic Client'));
    expect(result.text, contains('Second Synthetic Client'));
    expect(result.pageCount, 2);
  });

  test(
    'renders every section and blank policy cells for a client with none',
    () async {
      final locale = await _localizations('en');
      final bytes = await _export(
        <ClientExportBundle>[_bundle('No Policy Client', policyCount: 0)],
        'en',
        locale,
      );
      final result = _readPdf(bytes);

      for (final section in <String>[
        'Policy Data',
        'Life Plan',
        'Critical Illness Plan',
        'Hospital & Medical Coverage',
        'Other Plans',
        'Accident Coverage',
        'Savings Plan',
      ]) {
        expect(result.text, contains(section));
      }
      expect(result.text, isNot(contains('N/A')));
      expect(result.pageCount, 1);
    },
  );

  test('does not grant print permission when disabled', () async {
    final locale = await _localizations('en');
    final bytes = await _export(
      <ClientExportBundle>[_bundle('Synthetic Client')],
      'en',
      locale,
      allowPrint: false,
    );
    final document = PdfDocument(inputBytes: bytes, password: password);
    try {
      final permissions = <PdfPermissionsFlags>[];
      document.security.permissions.forEach(permissions.add);
      expect(permissions, isNot(contains(PdfPermissionsFlags.print)));
      expect(
        permissions,
        contains(PdfPermissionsFlags.accessibilityCopyContent),
      );
    } finally {
      document.dispose();
    }
  });
}

Future<AppLocalizations> _localizations(String languageCode) {
  final locale = languageCode == 'zh-Hant'
      ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
      : const Locale('en');
  return AppLocalizations.delegate.load(locale);
}

Future<Uint8List> _export(
  List<ClientExportBundle> bundles,
  String languageCode,
  AppLocalizations l10n, {
  bool allowPrint = true,
}) {
  return PdfExporter.exportBundles(
    bundles: bundles,
    languageCode: languageCode,
    allowPrint: allowPrint,
    password: 'synthetic-passphrase',
    l10n: l10n,
  );
}

({String text, int pageCount}) _readPdf(Uint8List bytes) {
  final document = PdfDocument(
    inputBytes: bytes,
    password: 'synthetic-passphrase',
  );
  try {
    return (
      text: _normalizeText(PdfTextExtractor(document).extractText()),
      pageCount: document.pages.count,
    );
  } finally {
    document.dispose();
  }
}

String _normalizeText(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

ClientExportBundle _bundle(String clientName, {int policyCount = 1}) {
  final clientId = 'synthetic-client-${clientName.hashCode}';
  final client = Client(
    role: ClientRole.holder,
    name: clientName,
    gender: Gender.other,
    dob: DateTime.utc(1990, 4, 12),
    phone: null,
    email: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    archivedAt: null,
  );
  final policies = List<PolicyWithPlans>.generate(policyCount, (int index) {
    final policyId = 'synthetic-policy-$index';
    final policy = Policy(
      clientId: clientId,
      policyNo: 'Synthetic Policy ${index + 1}',
      company: 'Synthetic Insurer ${index + 1}',
      effectiveDate: DateTime.utc(2020),
      firstPremiumDate: DateTime.utc(2020, 2),
      currency: 'HKD',
      status: PolicyStatus.active,
      createdAt: DateTime.utc(2020),
      updatedAt: DateTime.utc(2026, 2, 3 + index),
    );
    return PolicyWithPlans(
      policy: policy,
      plans: policyCount == 1
          ? _syntheticPlans(policyId)
          : const <PlanWithRiders>[],
    );
  });

  return ClientExportBundle(client: client, policies: policies);
}

List<PlanWithRiders> _syntheticPlans(String policyId) {
  return PlanCategory.values.map((PlanCategory category) {
    final planId = 'synthetic-plan-${category.name}';
    final plan = Plan(
      policyId: policyId,
      category: category,
      planName: 'Synthetic ${category.name} plan',
      coverageAmount: 100000,
      deductible: 500,
      paymentTerm: '20 years',
      coveragePeriod: 'Until age 100',
    );
    final riders = category == PlanCategory.other
        ? const <Rider>[]
        : <Rider>[
            Rider(
              planId: planId,
              riderName: 'Synthetic ${category.name} rider',
              coverageAmount: 25000,
              paymentTerm: '10 years',
              deductible: 100,
              waitingPeriod: '30 days',
            ),
          ];
    return PlanWithRiders(plan: plan, riders: riders);
  }).toList();
}
