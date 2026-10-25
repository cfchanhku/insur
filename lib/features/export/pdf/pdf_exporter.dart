/// Builds a local PDF summary from selected client records.
library;

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/security/pdf_encryption_service.dart';
import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../features/plans/models/plan.dart';
import '../../../features/plans/models/plan_category.dart';
import '../../../features/policies/models/policy.dart';
import '../../../features/policies/models/policy_status.dart';
import '../../../features/riders/models/rider.dart';
import '../../../l10n/app_localizations.dart';

/// A client and the related policy, plan, and rider records for export.
class ClientExportBundle {
  /// Creates a bundle for one client.
  const ClientExportBundle({required this.client, required this.policies});

  /// The client shown in the export.
  final Client client;

  /// Policies and their nested plans and riders.
  final List<PolicyWithPlans> policies;
}

/// A policy and its nested plans.
class PolicyWithPlans {
  /// Creates a policy bundle.
  const PolicyWithPlans({required this.policy, required this.plans});

  /// The policy shown in the export.
  final Policy policy;

  /// Plans attached to this policy.
  final List<PlanWithRiders> plans;
}

/// A plan and its nested riders.
class PlanWithRiders {
  /// Creates a plan bundle.
  const PlanWithRiders({required this.plan, required this.riders});

  /// The plan shown in the export.
  final Plan plan;

  /// Riders attached to this plan.
  final List<Rider> riders;
}

/// Generates a bilingual PDF summary without adding client data to metadata.
class PdfExporter {
  const PdfExporter._();

  /// Generates an in-memory PDF for [bundles].
  ///
  /// The resulting PDF is AES-256 encrypted. The password is required to open
  /// it; copying and editing are disabled, while accessibility extraction
  /// remains enabled.
  static Future<Uint8List> exportBundles({
    required List<ClientExportBundle> bundles,
    required String languageCode,
    required bool allowPrint,
    required String password,
    required AppLocalizations l10n,
  }) async {
    if (bundles.isEmpty) {
      throw ArgumentError.value(bundles, 'bundles', 'Must not be empty');
    }
    if (languageCode != 'en' && languageCode != 'zh-Hant') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    if (password.runes.length < 8) {
      throw ArgumentError.value(
        password.runes.length,
        'password.length',
        'Must be at least 8 characters',
      );
    }

    await initializeDateFormatting(languageCode);
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansTC-Regular.ttf'),
    );
    final fontMedium = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansTC-Medium.ttf'),
    );
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontMedium);
    final generatedAt = DateTime.now();
    final dateFormat = DateFormat.yMMMd(languageCode).add_jm();
    final content = <pw.Widget>[];
    pw.Widget detail(String label, String? value) =>
        _detail(label, value, l10n.pdf_not_available);
    void optionalDetail(String label, String? value) {
      if (value != null && value.isNotEmpty) {
        content.add(detail(label, value));
      }
    }

    final document = pw.Document(
      title: l10n.pdf_doc_title,
      author: 'Insurance Policy Manager',
      creator: 'Insurance Policy Manager',
      subject: 'Insurance overview',
      theme: theme,
    );

    for (var index = 0; index < bundles.length; index++) {
      if (index > 0) {
        content.add(pw.NewPage());
      }
      final bundle = bundles[index];
      content
        ..add(
          pw.Text(
            l10n.pdf_doc_title,
            style: const pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        )
        ..add(pw.SizedBox(height: 14))
        ..add(_sectionTitle(l10n.pdf_section_client))
        ..add(detail(l10n.client_name, bundle.client.name))
        ..add(detail(l10n.client_role, _roleLabel(l10n, bundle.client.role)))
        ..add(
          detail(l10n.client_gender, _genderLabel(l10n, bundle.client.gender)),
        )
        ..add(
          detail(
            l10n.client_dob,
            DateFormat.yMMMd(languageCode).format(bundle.client.dob),
          ),
        )
        ..add(detail(l10n.client_phone, bundle.client.phone))
        ..add(detail(l10n.client_email, bundle.client.email));
      optionalDetail(l10n.client_notes, bundle.client.notes);

      content
        ..add(pw.SizedBox(height: 12))
        ..add(_sectionTitle(l10n.pdf_section_policies));
      if (bundle.policies.isEmpty) {
        content.add(detail(l10n.pdf_section_policies, null));
      }
      for (final policyBundle in bundle.policies) {
        final policy = policyBundle.policy;
        content
          ..add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
              child: pw.Text(
                l10n.pdf_policy_title(policy.policyNo),
                style: const pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          ..add(detail(l10n.policy_company, policy.company))
          ..add(detail(l10n.policy_no, policy.policyNo))
          ..add(
            detail(
              l10n.policy_effective_date,
              DateFormat.yMMMd(languageCode).format(policy.effectiveDate),
            ),
          )
          ..add(
            detail(
              l10n.policy_first_premium_date,
              DateFormat.yMMMd(languageCode).format(policy.firstPremiumDate),
            ),
          )
          ..add(detail(l10n.policy_currency, policy.currency))
          ..add(detail(l10n.policy_status, _statusLabel(l10n, policy.status)));
        optionalDetail(l10n.policy_notes, policy.notes);
        if (policyBundle.plans.isNotEmpty) {
          content
            ..add(pw.SizedBox(height: 8))
            ..add(_sectionTitle(l10n.pdf_section_plans));
        }
        for (final planBundle in policyBundle.plans) {
          final plan = planBundle.plan;
          content
            ..add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 7, bottom: 3),
                child: pw.Text(
                  l10n.pdf_plan_title(plan.planName),
                  style: const pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            )
            ..add(
              detail(l10n.plan_category, _categoryLabel(l10n, plan.category)),
            )
            ..add(
              detail(
                l10n.plan_coverage_amount,
                _money(plan.coverageAmount, policy.currency, languageCode),
              ),
            )
            ..add(detail(l10n.plan_payment_term, plan.paymentTerm))
            ..add(detail(l10n.plan_coverage_period, plan.coveragePeriod))
            ..add(
              detail(
                l10n.plan_deductible,
                _money(plan.deductible, policy.currency, languageCode),
              ),
            );
          optionalDetail(l10n.plan_notes, plan.notes);
          if (planBundle.riders.isNotEmpty) {
            content
              ..add(pw.SizedBox(height: 5))
              ..add(_sectionTitle(l10n.pdf_section_riders));
          }
          for (final rider in planBundle.riders) {
            content
              ..add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text(
                    l10n.pdf_rider_title(rider.riderName),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              )
              ..add(
                detail(
                  l10n.rider_coverage_amount,
                  _money(rider.coverageAmount, policy.currency, languageCode),
                ),
              )
              ..add(detail(l10n.rider_payment_term, rider.paymentTerm))
              ..add(
                detail(
                  l10n.rider_deductible,
                  _money(rider.deductible, policy.currency, languageCode),
                ),
              )
              ..add(detail(l10n.rider_waiting_period, rider.waitingPeriod));
          }
        }
        content.add(pw.SizedBox(height: 10));
      }
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        footer: (pw.Context context) => pw.Align(
          child: pw.Text(
            l10n.pdf_footer(
              dateFormat.format(generatedAt),
              context.pageNumber,
              context.pagesCount,
            ),
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (pw.Context context) => content,
      ),
    );

    final rawPdfBytes = await document.save();
    try {
      return await PdfEncryptionService.encrypt(
        rawPdfBytes: rawPdfBytes,
        userPassword: password,
        allowPrint: allowPrint,
      );
    } finally {
      rawPdfBytes.fillRange(0, rawPdfBytes.length, 0);
    }
  }

  static pw.Widget _sectionTitle(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 5, bottom: 3),
    child: pw.Text(
      value,
      style: const pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _detail(String label, String? value, String notAvailable) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          '$label: ${value?.isNotEmpty ?? false ? value : notAvailable}',
        ),
      );

  static String _roleLabel(AppLocalizations l10n, ClientRole role) =>
      switch (role) {
        ClientRole.holder => l10n.client_role_holder,
        ClientRole.insured => l10n.client_role_insured,
      };

  static String _genderLabel(AppLocalizations l10n, Gender gender) =>
      switch (gender) {
        Gender.male => l10n.gender_male,
        Gender.female => l10n.gender_female,
        Gender.other => l10n.gender_other,
      };

  static String _statusLabel(AppLocalizations l10n, PolicyStatus status) =>
      switch (status) {
        PolicyStatus.active => l10n.policy_status_active,
        PolicyStatus.lapsed => l10n.policy_status_lapsed,
        PolicyStatus.surrendered => l10n.policy_status_surrendered,
      };

  static String _categoryLabel(AppLocalizations l10n, PlanCategory category) =>
      switch (category) {
        PlanCategory.life => l10n.plan_category_life,
        PlanCategory.ci => l10n.plan_category_ci,
        PlanCategory.hospital => l10n.plan_category_hospital,
        PlanCategory.accident => l10n.plan_category_accident,
        PlanCategory.savings => l10n.plan_category_savings,
        PlanCategory.other => l10n.plan_category_other,
      };

  static String? _money(double? amount, String currency, String languageCode) {
    if (amount == null) {
      return null;
    }
    return '$currency ${NumberFormat.decimalPattern(languageCode).format(amount)}';
  }
}
