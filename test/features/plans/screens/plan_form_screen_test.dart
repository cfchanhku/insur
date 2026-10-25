import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/plans/models/plan_category.dart';
import 'package:insur/features/plans/screens/plan_form_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:insur/shared/widgets/async_button.dart';

final Client _insured = Client(
  id: '123e4567-e89b-42d3-a456-426614174002',
  role: ClientRole.insured,
  name: 'Synthetic insured',
  gender: Gender.other,
  dob: DateTime.utc(1990),
  phone: null,
  email: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: null,
);

Widget _app() => ProviderScope(
  overrides: <Override>[
    clientListProvider.overrideWith((Ref ref) async => <Client>[_insured]),
  ],
  child: const MaterialApp(
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

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps the form save action in its persistent footer', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byType(AsyncButton), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('life displays coverage, term, and period but not deductible', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Coverage amount'), findsOneWidget);
    expect(find.text('Payment term'), findsOneWidget);
    expect(find.text('Coverage period'), findsOneWidget);
    expect(find.text('Deductible'), findsNothing);
    expect(find.text('Insured person'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic insured'), findsOneWidget);
  });

  testWidgets('requires an insured client for life plans', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byType(AsyncButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Select an insured person for this plan category'),
      findsOneWidget,
    );
  });

  testWidgets('hospital displays name, deductible, and riders', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _selectCategory(tester, 'Hospital');

    expect(find.text('Plan name'), findsOneWidget);
    expect(find.text('Deductible'), findsOneWidget);
    expect(find.text('Riders'), findsOneWidget);
  });

  testWidgets('savings displays payment term but hides coverage', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _selectCategory(tester, 'Savings');

    expect(find.text('Payment term'), findsOneWidget);
    expect(find.text('Coverage amount'), findsNothing);
  });

  testWidgets('accident allows adding and removing rider cards', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
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
