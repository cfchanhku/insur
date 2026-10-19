import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/plans/models/plan_category.dart';
import 'package:insur/features/plans/screens/plan_form_screen.dart';
import 'package:insur/l10n/app_localizations.dart';

Widget _app() => const ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PlanFormScreen(policyId: '123e4567-e89b-42d3-a456-426614174001'),
  ),
);

Future<void> _selectCategory(WidgetTester tester, String category) async {
  await tester.tap(find.byType(DropdownButtonFormField<PlanCategory>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(category).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('life displays coverage, term, and period but not deductible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('Coverage amount'), findsOneWidget);
    expect(find.text('Payment term'), findsOneWidget);
    expect(find.text('Coverage period'), findsOneWidget);
    expect(find.text('Deductible'), findsNothing);
  });

  testWidgets('hospital displays name, deductible, and riders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    await _selectCategory(tester, 'Hospital');

    expect(find.text('Plan name'), findsOneWidget);
    expect(find.text('Deductible'), findsOneWidget);
    expect(find.text('Riders'), findsOneWidget);
  });

  testWidgets('savings displays payment term but hides coverage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    await _selectCategory(tester, 'Savings');

    expect(find.text('Payment term'), findsOneWidget);
    expect(find.text('Coverage amount'), findsNothing);
  });

  testWidgets('accident allows adding and removing rider cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    await _selectCategory(tester, 'Accident');

    expect(find.text('Riders'), findsOneWidget);
    await tester.tap(find.text('Add rider'));
    await tester.pumpAndSettle();
    expect(find.text('Rider name'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Rider name'), findsNothing);
  });
}
