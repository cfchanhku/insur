/// Builds a local PDF summary from selected client records.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/security/pdf_encryption_service.dart';
import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../features/plans/models/plan.dart';
import '../../../features/plans/models/plan_category.dart';
import '../../../features/policies/models/policy.dart';
import '../../../features/riders/models/rider.dart';
import '../../../l10n/app_localizations.dart';

/// A client and the related policy, plan, and rider records for export.
class ClientExportBundle {
  /// Creates a bundle for one client.
  const ClientExportBundle({
    required this.client,
    required this.policies,
    this.insuredNamesById = const <String, String>{},
  });

  /// The client shown in the export.
  final Client client;

  /// Policies and their nested plans and riders.
  final List<PolicyWithPlans> policies;

  /// Names for insured clients referenced by the included plans.
  final Map<String, String> insuredNamesById;
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

/// Generates a localized PDF summary without adding client data to metadata.
class PdfExporter {
  const PdfExporter._();

  static const int _policiesPerPage = 5;
  static const PdfColor _sectionColor = PdfColor(0.933, 0.933, 0.933);
  static const PdfColor _labelColor = PdfColor(0.961, 0.961, 0.961);
  static const PdfColor _borderColor = PdfColor(0.4, 0.4, 0.4);

  static const Map<String, Map<String, String>>
  _labels = <String, Map<String, String>>{
    'title': <String, String>{
      'en': 'Premium Client Protection Overview',
      'zh-Hant': '尊貴客戶保障總覽',
    },
    'generatedOn': <String, String>{'en': 'Generated on', 'zh-Hant': '產生時間'},
    'holderName': <String, String>{
      'en': 'Policy Holder Name',
      'zh-Hant': '保單持有人姓名',
    },
    'insuredName': <String, String>{'en': 'Insured Name', 'zh-Hant': '受保人姓名'},
    'gender': <String, String>{'en': 'Gender', 'zh-Hant': '性別'},
    'dob': <String, String>{'en': 'Date of Birth', 'zh-Hant': '出生日期'},
    'reviewDate': <String, String>{'en': 'Review Date', 'zh-Hant': '重溫日期'},
    'policyColumn': <String, String>{'en': 'Policy', 'zh-Hant': '保單'},
    'policyData': <String, String>{'en': 'Policy Data', 'zh-Hant': '保單資料'},
    'insurer': <String, String>{'en': 'Insurer', 'zh-Hant': '承保公司'},
    'policyNo': <String, String>{'en': 'Policy Number', 'zh-Hant': '保單編號'},
    'effectiveDate': <String, String>{
      'en': 'Effective Date',
      'zh-Hant': '生效日期',
    },
    'firstPremiumDate': <String, String>{
      'en': 'First Premium Date',
      'zh-Hant': '首期保費日',
    },
    'life': <String, String>{'en': 'Life Plan', 'zh-Hant': '壽險計劃'},
    'lifePlan': <String, String>{'en': 'Life Plan', 'zh-Hant': '人壽計劃'},
    'lifeCoverage': <String, String>{'en': 'Life Coverage', 'zh-Hant': '人壽保障額'},
    'paymentTerm': <String, String>{'en': 'Payment Term', 'zh-Hant': '供款期'},
    'coveragePeriod': <String, String>{
      'en': 'Coverage Period',
      'zh-Hant': '保障期',
    },
    'ci': <String, String>{'en': 'Critical Illness Plan', 'zh-Hant': '危疾計劃'},
    'ciPlan': <String, String>{
      'en': 'Critical Illness Plan',
      'zh-Hant': '危疾計劃',
    },
    'ciCoverage': <String, String>{
      'en': 'Critical Illness Coverage',
      'zh-Hant': '危疾計劃保障額',
    },
    'ciRider': <String, String>{
      'en': 'Additional CI Rider',
      'zh-Hant': '附加危疾保障',
    },
    'coverageAmount': <String, String>{
      'en': 'Coverage Amount',
      'zh-Hant': '保障額',
    },
    'hospital': <String, String>{
      'en': 'Hospital & Medical Coverage',
      'zh-Hant': '住院醫療保障',
    },
    'hospitalPlan': <String, String>{
      'en': 'Hospital Plan',
      'zh-Hant': '住院醫療計劃',
    },
    'planCoverage': <String, String>{'en': 'Plan Coverage', 'zh-Hant': '計劃保障'},
    'hospitalRider': <String, String>{
      'en': 'Additional Hospital Rider',
      'zh-Hant': '附加住院保障',
    },
    'deductible': <String, String>{'en': 'Deductible', 'zh-Hant': '自負額'},
    'hospitalCashPlan': <String, String>{
      'en': 'Hospital Cash Plan',
      'zh-Hant': '住院現金計劃',
    },
    'otherPlans': <String, String>{'en': 'Other Plans', 'zh-Hant': '其他計劃'},
    'otherPlan1': <String, String>{'en': 'Other Plan 1', 'zh-Hant': '其他計劃 1'},
    'otherPlan2': <String, String>{'en': 'Other Plan 2', 'zh-Hant': '其他計劃 2'},
    'otherPlan3': <String, String>{'en': 'Other Plan 3', 'zh-Hant': '其他計劃 3'},
    'accident': <String, String>{'en': 'Accident Coverage', 'zh-Hant': '意外保障'},
    'accidentPlan': <String, String>{'en': 'Accident Plan', 'zh-Hant': '意外計劃'},
    'accidentalDeath': <String, String>{
      'en': 'Accidental Death & Permanent Disability',
      'zh-Hant': '意外死亡及永久傷殘額',
    },
    'temporaryLoss': <String, String>{
      'en': 'Temporary Loss of Work Capacity',
      'zh-Hant': '暫時喪失工作能力',
    },
    'medicalExpenses': <String, String>{
      'en': 'Medical Expenses',
      'zh-Hant': '醫療費用',
    },
    'savings': <String, String>{'en': 'Savings Plan', 'zh-Hant': '儲蓄計劃'},
    'savingsPlan': <String, String>{'en': 'Savings Plan', 'zh-Hant': '儲蓄計劃'},
    'paymentYears': <String, String>{'en': 'Payment Years', 'zh-Hant': '供款年期'},
    'cashValue': <String, String>{
      'en': 'Policy Cash Value',
      'zh-Hant': '保單現金價值',
    },
    'balance': <String, String>{
      'en': 'Policy/Investment Option Balance',
      'zh-Hant': '保單/投資選項結餘',
    },
    'paymentMethod': <String, String>{
      'en': 'Payment Method',
      'zh-Hant': '供款方法',
    },
    'premiumPerPeriod': <String, String>{
      'en': 'Premium per Period',
      'zh-Hant': '每期保費',
    },
    'footer': <String, String>{
      'en': 'This is a summary; all details are subject to the policy terms',
      'zh-Hant': '以上為重點摘要，一切詳情及細則以各保單條款內容為準',
    },
  };

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

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansTC-Regular.ttf'),
    );
    final fontMedium = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansTC-Medium.ttf'),
    );
    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontMedium,
      italic: fontRegular,
      boldItalic: fontMedium,
      fontFallback: <pw.Font>[fontRegular],
    );
    final generatedAt = DateTime.now();
    final pages = <_ExportPage>[];
    for (final bundle in bundles) {
      final totalPolicyPages = math.max(
        1,
        (bundle.policies.length + _policiesPerPage - 1) ~/ _policiesPerPage,
      );
      for (var pageIndex = 0; pageIndex < totalPolicyPages; pageIndex++) {
        final start = pageIndex * _policiesPerPage;
        final end = math.min(start + _policiesPerPage, bundle.policies.length);
        pages.add(
          _ExportPage(
            bundle: bundle,
            policies: bundle.policies.sublist(start, end),
            policyOffset: start,
          ),
        );
      }
    }

    final document = pw.Document(
      title: 'Insurance Policy Overview',
      author: 'Insurance Policy Manager',
      creator: 'Insurance Policy Manager',
      subject: 'Insurance overview',
      theme: theme,
    );
    final content = <pw.Widget>[];
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      if (index > 0) {
        content.add(pw.NewPage());
      }
      content
        ..add(
          _buildHeaderBlock(
            page.bundle.client,
            page.bundle.policies,
            languageCode,
            index + 1,
            pages.length,
            generatedAt,
            l10n,
            bundles,
          ),
        )
        ..add(pw.SizedBox(height: 5))
        ..add(
          _buildSummaryTable(
            page.policies,
            languageCode,
            page.policyOffset,
            page.bundle.insuredNamesById,
          ),
        );
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: theme,
        header: (pw.Context context) => pw.SizedBox.shrink(),
        footer: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Row(
            children: <pw.Widget>[
              pw.SizedBox(width: 60),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    _label('footer', languageCode),
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontStyle: pw.FontStyle.italic,
                      fontFallback: <pw.Font>[fontRegular],
                    ),
                  ),
                ),
              ),
              pw.SizedBox(
                width: 60,
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    _pageLabel(
                      languageCode,
                      context.pageNumber,
                      context.pagesCount,
                    ),
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              ),
            ],
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

  static pw.Widget _buildHeaderBlock(
    Client client,
    List<PolicyWithPlans> policies,
    String language,
    int pageNum,
    int totalPages,
    DateTime generatedAt,
    AppLocalizations l10n,
    List<ClientExportBundle> allBundles,
  ) {
    final holders = allBundles
        .map((ClientExportBundle item) => item.client)
        .where((Client person) => person.role == ClientRole.holder)
        .toList();
    final holderName = holders.isNotEmpty
        ? holders.map((Client person) => person.name).join(', ')
        : allBundles.length == 1 && client.role == ClientRole.holder
        ? client.name
        : '';
    final holderGender = holders.isNotEmpty
        ? holders
              .map((Client person) => _genderLabel(l10n, person.gender))
              .join(', ')
        : holderName.isEmpty
        ? ''
        : _genderLabel(l10n, client.gender);
    final holderDob = holders.isNotEmpty
        ? holders.map((Client person) => _formatDate(person.dob)).join(', ')
        : holderName.isEmpty
        ? ''
        : _formatDate(client.dob);
    final latestPolicyUpdate = policies
        .map((PolicyWithPlans item) => item.policy.updatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (DateTime? latest, DateTime candidate) {
          if (latest == null || candidate.isAfter(latest)) {
            return candidate;
          }
          return latest;
        });
    final reviewDate = _formatDate(latestPolicyUpdate ?? DateTime.now());

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                _label('title', language),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FlexColumnWidth(1.25),
                  1: const pw.FlexColumnWidth(2.1),
                  2: const pw.FlexColumnWidth(0.65),
                  3: const pw.FlexColumnWidth(0.8),
                  4: const pw.FlexColumnWidth(0.9),
                  5: const pw.FlexColumnWidth(1.3),
                },
                children: <pw.TableRow>[
                  _personalInfoRow(
                    _label('holderName', language),
                    holderName,
                    _label('gender', language),
                    holderGender,
                    _label('dob', language),
                    holderDob,
                  ),
                  _personalInfoRow(
                    _label('reviewDate', language),
                    reviewDate,
                    '',
                    '',
                    '',
                    '',
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                '${_label('generatedOn', language)} ${DateFormat('yyyy-MM-dd HH:mm').format(generatedAt)}',
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _pageLabel(language, pageNum, totalPages),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _personalInfoRow(
    String label1,
    String value1,
    String label2,
    String value2,
    String label3,
    String value3,
  ) {
    return pw.TableRow(
      children: <pw.Widget>[
        _personalCell(label1, isLabel: true),
        _personalCell(value1),
        _personalCell(label2, isLabel: true),
        _personalCell(value2),
        _personalCell(label3, isLabel: true),
        _personalCell(value3),
      ],
    );
  }

  static pw.Widget _personalCell(String value, {bool isLabel = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        color: isLabel ? _labelColor : PdfColors.white,
        child: pw.Text(
          value,
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: isLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _buildSummaryTable(
    List<PolicyWithPlans> bundles,
    String language,
    int policyOffset,
    Map<String, String> insuredNamesById,
  ) {
    final sections = <pw.Widget>[];
    final columns = List<PolicyWithPlans?>.generate(
      _policiesPerPage,
      (int index) => index < bundles.length ? bundles[index] : null,
    );
    final policyColumnNames = List<String?>.generate(
      _policiesPerPage,
      (int index) => _policyColumnLabel(language, policyOffset + index + 1),
    );

    sections.add(
      _buildSection('policyData', <_RowDef>[
        _RowDef(_label('policyColumn', language), policyColumnNames),
        _RowDef(
          _label('insurer', language),
          columns.map((item) => item?.policy.company).toList(),
        ),
        _RowDef(
          _label('policyNo', language),
          columns.map((item) => item?.policy.policyNo).toList(),
        ),
        _RowDef(
          _label('effectiveDate', language),
          columns
              .map(
                (item) => item == null
                    ? null
                    : _formatDate(item.policy.effectiveDate),
              )
              .toList(),
        ),
        _RowDef(
          _label('firstPremiumDate', language),
          columns
              .map(
                (item) => item == null
                    ? null
                    : _formatDate(item.policy.firstPremiumDate),
              )
              .toList(),
        ),
      ], language),
    );

    final lifePlans = columns.map((item) {
      return _findPlan(item, PlanCategory.life);
    }).toList();
    sections.add(
      _buildSection('life', <_RowDef>[
        _planNameRow(_label('lifePlan', language), lifePlans),
        _insuredNameRow(
          _label('insuredName', language),
          lifePlans,
          insuredNamesById,
        ),
        _planMoneyRow(
          _label('lifeCoverage', language),
          lifePlans,
          columns,
          (Plan plan) => plan.coverageAmount,
        ),
        _planValueRow(
          _label('paymentTerm', language),
          lifePlans,
          (Plan plan) => plan.paymentTerm,
        ),
        _planValueRow(
          _label('coveragePeriod', language),
          lifePlans,
          (Plan plan) => plan.coveragePeriod,
        ),
      ], language),
    );

    final ciPlans = columns.map((item) {
      return _findPlan(item, PlanCategory.ci);
    }).toList();
    final ciRiders = ciPlans.map(_firstRider).toList();
    sections.add(
      _buildSection('ci', <_RowDef>[
        _planNameRow(_label('ciPlan', language), ciPlans),
        _insuredNameRow(
          _label('insuredName', language),
          ciPlans,
          insuredNamesById,
        ),
        _planMoneyRow(
          _label('ciCoverage', language),
          ciPlans,
          columns,
          (Plan plan) => plan.coverageAmount,
        ),
        _planValueRow(
          _label('paymentTerm', language),
          ciPlans,
          (Plan plan) => plan.paymentTerm,
        ),
        _riderNameRow(_label('ciRider', language), ciRiders),
        _riderMoneyRow(
          _label('coverageAmount', language),
          ciRiders,
          columns,
          (Rider rider) => rider.coverageAmount,
        ),
        _riderValueRow(
          _label('paymentTerm', language),
          ciRiders,
          (Rider rider) => rider.paymentTerm,
        ),
      ], language),
    );

    final hospitalPlans = columns.map((item) {
      return _findPlan(item, PlanCategory.hospital);
    }).toList();
    final hospitalRiders = hospitalPlans.map(_firstRider).toList();
    sections.add(
      _buildSection('hospital', <_RowDef>[
        _planNameRow(_label('hospitalPlan', language), hospitalPlans),
        _insuredNameRow(
          _label('insuredName', language),
          hospitalPlans,
          insuredNamesById,
        ),
        _planMoneyRow(
          _label('planCoverage', language),
          hospitalPlans,
          columns,
          (Plan plan) => plan.coverageAmount,
        ),
        _planValueRow(
          _label('paymentTerm', language),
          hospitalPlans,
          (Plan plan) => plan.paymentTerm,
        ),
        _planValueRow(
          _label('coveragePeriod', language),
          hospitalPlans,
          (Plan plan) => plan.coveragePeriod,
        ),
        _riderNameRow(_label('hospitalRider', language), hospitalRiders),
        _riderMoneyRow(
          _label('planCoverage', language),
          hospitalRiders,
          columns,
          (Rider rider) => rider.coverageAmount,
        ),
        _riderMoneyRow(
          _label('deductible', language),
          hospitalRiders,
          columns,
          (Rider rider) => rider.deductible,
        ),
        _riderValueRow(
          _label('paymentTerm', language),
          hospitalRiders,
          (Rider rider) => rider.paymentTerm,
        ),
        _riderValueRow(
          _label('coveragePeriod', language),
          hospitalRiders,
          (Rider rider) => rider.waitingPeriod,
        ),
        _RowDef(_label('hospitalCashPlan', language), _emptyValues()),
      ], language),
    );

    final otherPlans = columns
        .map(
          (item) => item?.plans
              .where((plan) => plan.plan.category == PlanCategory.other)
              .take(3)
              .toList(),
        )
        .toList();
    sections.add(
      _buildSection(
        'otherPlans',
        List<_RowDef>.generate(3, (int index) {
          final values = otherPlans.map((plans) {
            if (plans == null || plans.length <= index) {
              return null;
            }
            return plans[index].plan.planName;
          }).toList();
          return _RowDef(_label('otherPlan${index + 1}', language), values);
        }),
        language,
      ),
    );

    final accidentPlans = columns.map((item) {
      return _findPlan(item, PlanCategory.accident);
    }).toList();
    final accidentRiders = accidentPlans.map(_riders).toList();
    sections.add(
      _buildSection('accident', <_RowDef>[
        _planNameRow(_label('accidentPlan', language), accidentPlans),
        _insuredNameRow(
          _label('insuredName', language),
          accidentPlans,
          insuredNamesById,
        ),
        _planMoneyRow(
          _label('accidentalDeath', language),
          accidentPlans,
          columns,
          (Plan plan) => plan.coverageAmount,
        ),
        _riderMoneyRow(
          _label('temporaryLoss', language),
          accidentRiders.map((riders) => _riderAt(riders, 0)).toList(),
          columns,
          (Rider rider) => rider.coverageAmount,
        ),
        _riderMoneyRow(
          _label('medicalExpenses', language),
          accidentRiders.map((riders) => _riderAt(riders, 1)).toList(),
          columns,
          (Rider rider) => rider.coverageAmount,
        ),
      ], language),
    );

    final savingsPlans = columns.map((item) {
      return _findPlan(item, PlanCategory.savings);
    }).toList();
    sections.add(
      _buildSection('savings', <_RowDef>[
        _planNameRow(_label('savingsPlan', language), savingsPlans),
        _insuredNameRow(
          _label('insuredName', language),
          savingsPlans,
          insuredNamesById,
        ),
        _planValueRow(
          _label('paymentYears', language),
          savingsPlans,
          (Plan plan) => plan.paymentTerm,
        ),
        _RowDef(_label('cashValue', language), _emptyValues()),
        _RowDef(_label('balance', language), _emptyValues()),
        _RowDef(_label('paymentMethod', language), _emptyValues()),
        _RowDef(_label('premiumPerPeriod', language), _emptyValues()),
      ], language),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: sections,
    );
  }

  static pw.Widget _buildSection(
    String sectionKey,
    List<_RowDef> rows,
    String language,
  ) {
    const borderSide = pw.BorderSide(color: _borderColor, width: 0.5);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _sectionColor,
            border: pw.Border.all(color: _borderColor, width: 0.5),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
          child: pw.Text(
            _label(sectionKey, language),
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 0,
            ),
          ),
        ),
        pw.Table(
          border: const pw.TableBorder(
            left: borderSide,
            right: borderSide,
            bottom: borderSide,
            horizontalInside: borderSide,
            verticalInside: borderSide,
          ),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(20),
            1: const pw.FlexColumnWidth(16),
            2: const pw.FlexColumnWidth(16),
            3: const pw.FlexColumnWidth(16),
            4: const pw.FlexColumnWidth(16),
            5: const pw.FlexColumnWidth(16),
          },
          children: rows
              .map((_RowDef row) => _buildRow(row.label, row.values, false))
              .toList(),
        ),
      ],
    );
  }

  static pw.TableRow _buildRow(
    String label,
    List<String?> values,
    bool isHeader,
  ) {
    if (isHeader) {
      return pw.TableRow(
        children: <pw.Widget>[
          _sectionHeaderCell(label),
          for (var index = 0; index < _policiesPerPage; index++)
            _sectionHeaderCell(''),
        ],
      );
    }

    return pw.TableRow(
      children: <pw.Widget>[
        _tableCell(label, isLabel: true),
        for (final value in values) _tableCell(_truncate(value)),
      ],
    );
  }

  static pw.Widget _sectionHeaderCell(String value) => pw.Container(
    color: _sectionColor,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    child: pw.Text(
      value,
      maxLines: 1,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        lineSpacing: 0,
      ),
    ),
  );

  static pw.Widget _tableCell(String? value, {bool isLabel = false}) =>
      pw.Container(
        color: isLabel ? _labelColor : PdfColors.white,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        child: value == null || value.isEmpty
            ? pw.SizedBox.shrink()
            : pw.Text(
                value,
                maxLines: 1,
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: isLabel
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  lineSpacing: 0,
                ),
              ),
      );

  static _RowDef _planNameRow(String label, List<PlanWithRiders?> plans) =>
      _RowDef(label, plans.map((item) => item?.plan.planName).toList());

  static _RowDef _insuredNameRow(
    String label,
    List<PlanWithRiders?> plans,
    Map<String, String> insuredNamesById,
  ) => _RowDef(
    label,
    plans.map((item) {
      final insuredId = item?.plan.insuredId;
      return insuredId == null ? null : insuredNamesById[insuredId];
    }).toList(),
  );

  static _RowDef _planValueRow(
    String label,
    List<PlanWithRiders?> plans,
    String? Function(Plan plan) value,
  ) => _RowDef(
    label,
    plans.map((item) => item == null ? null : value(item.plan)).toList(),
  );

  static _RowDef _planMoneyRow(
    String label,
    List<PlanWithRiders?> plans,
    List<PolicyWithPlans?> policies,
    double? Function(Plan plan) value,
  ) => _RowDef(
    label,
    List<String?>.generate(plans.length, (int index) {
      final plan = plans[index]?.plan;
      final policy = policies[index]?.policy;
      if (plan == null || policy == null) {
        return null;
      }
      return _formatMoney(value(plan), policy.currency);
    }),
  );

  static _RowDef _riderNameRow(String label, List<Rider?> riders) =>
      _RowDef(label, riders.map((item) => item?.riderName).toList());

  static _RowDef _riderValueRow(
    String label,
    List<Rider?> riders,
    String? Function(Rider rider) value,
  ) => _RowDef(
    label,
    riders.map((item) => item == null ? null : value(item)).toList(),
  );

  static _RowDef _riderMoneyRow(
    String label,
    List<Rider?> riders,
    List<PolicyWithPlans?> policies,
    double? Function(Rider rider) value,
  ) => _RowDef(
    label,
    List<String?>.generate(riders.length, (int index) {
      final rider = riders[index];
      final policy = policies[index]?.policy;
      if (rider == null || policy == null) {
        return null;
      }
      return _formatMoney(value(rider), policy.currency);
    }),
  );

  static PlanWithRiders? _findPlan(
    PolicyWithPlans? policy,
    PlanCategory category,
  ) {
    if (policy == null) {
      return null;
    }
    for (final plan in policy.plans) {
      if (plan.plan.category == category) {
        return plan;
      }
    }
    return null;
  }

  static List<Rider> _riders(PlanWithRiders? plan) =>
      plan?.riders ?? const <Rider>[];

  static Rider? _firstRider(PlanWithRiders? plan) {
    final riders = plan?.riders;
    return riders == null || riders.isEmpty ? null : riders.first;
  }

  static Rider? _riderAt(List<Rider> riders, int index) =>
      index < riders.length ? riders[index] : null;

  static List<String?> _emptyValues() =>
      List<String?>.filled(_policiesPerPage, null);

  static String _policyColumnLabel(String language, int policyNumber) {
    if (language == 'zh-Hant') {
      const chineseNumbers = <String>['一', '二', '三', '四', '五'];
      if (policyNumber >= 1 && policyNumber <= chineseNumbers.length) {
        return '保單${chineseNumbers[policyNumber - 1]}';
      }
      return '保單 $policyNumber';
    }
    return 'Policy $policyNumber';
  }

  static String _pageLabel(String language, int page, int total) =>
      language == 'zh-Hant' ? '第 $page / $total 頁' : 'Page $page of $total';

  static String _label(String key, String language) => _labels[key]![language]!;

  static String? _formatMoney(double? amount, String currency) {
    if (amount == null) {
      return null;
    }
    return '$currency ${NumberFormat('#,##0.00', 'en').format(amount)}';
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String? _truncate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final runes = value.runes.toList(growable: false);
    if (runes.length <= 40) {
      return value;
    }
    return '${String.fromCharCodes(runes.take(40))}…';
  }

  static String _genderLabel(AppLocalizations l10n, Gender gender) =>
      switch (gender) {
        Gender.male => l10n.gender_male,
        Gender.female => l10n.gender_female,
        Gender.other => l10n.gender_other,
      };
}

class _RowDef {
  const _RowDef(this.label, this.values);

  final String label;
  final List<String?> values;
}

class _ExportPage {
  const _ExportPage({
    required this.bundle,
    required this.policies,
    required this.policyOffset,
  });

  final ClientExportBundle bundle;
  final List<PolicyWithPlans> policies;
  final int policyOffset;
}
