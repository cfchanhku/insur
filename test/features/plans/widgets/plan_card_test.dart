import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/plans/models/plan.dart';
import 'package:insur/features/plans/models/plan_category.dart';
import 'package:insur/features/plans/widgets/plan_card.dart';
import 'package:insur/l10n/app_localizations.dart';

Plan _plan() => Plan(
  id: '123e4567-e89b-42d3-a456-426614174000',
  policyId: '123e4567-e89b-42d3-a456-426614174001',
  category: PlanCategory.life,
  planName: 'Synthetic life plan',
  coverageAmount: 120000,
);

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders plan name, localized category, and coverage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(PlanCard(plan: _plan())));

    expect(find.text('Synthetic life plan'), findsOneWidget);
    expect(find.textContaining('Life'), findsOneWidget);
    expect(find.textContaining('120,000'), findsOneWidget);
  });

  testWidgets('uses the category label when plan name is empty', (
    WidgetTester tester,
  ) async {
    final plan = _plan().copyWith(planName: 'Life');
    await tester.pumpWidget(_app(PlanCard(plan: plan)));

    expect(find.text('Life'), findsOneWidget);
  });

  testWidgets('shows the assigned insured client', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(PlanCard(plan: _plan(), insuredName: 'Synthetic insured')),
    );

    expect(find.text('Insured: Synthetic insured'), findsOneWidget);
  });

  testWidgets('calls onTap when selected', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _app(PlanCard(plan: _plan(), onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(ListTile));

    expect(tapped, isTrue);
  });
}
