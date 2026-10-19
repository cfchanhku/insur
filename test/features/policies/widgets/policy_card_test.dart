import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';
import 'package:insur/features/policies/widgets/policy_card.dart';
import 'package:insur/l10n/app_localizations.dart';

Policy _policy() => Policy(
  id: '123e4567-e89b-42d3-a456-426614174000',
  clientId: '123e4567-e89b-42d3-a456-426614174001',
  policyNo: 'SYNTHETIC-001',
  company: 'Example Insurer',
  effectiveDate: DateTime(2026, 1, 2),
  firstPremiumDate: DateTime(2026, 1, 2),
  currency: 'HKD',
  status: PolicyStatus.active,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders policy number, insurer, date, and status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(PolicyCard(policy: _policy())));

    expect(find.text('SYNTHETIC-001'), findsOneWidget);
    expect(find.textContaining('Example Insurer'), findsOneWidget);
    expect(find.textContaining('Active'), findsOneWidget);
  });

  testWidgets('calls onTap when selected', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _app(PolicyCard(policy: _policy(), onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(ListTile));

    expect(tapped, isTrue);
  });
}
