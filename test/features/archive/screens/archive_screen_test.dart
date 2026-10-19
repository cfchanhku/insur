import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/repositories/plan_repository.dart';
import 'package:insur/core/database/repositories/policy_repository.dart';
import 'package:insur/features/archive/screens/archive_screen.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/plans/models/plan.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_client_repository.dart';

class _MockPolicyRepository extends Mock implements PolicyRepository {}

class _MockPlanRepository extends Mock implements PlanRepository {}

Client _archivedClient() => Client(
  id: '00000000-0000-4000-8000-000000000001',
  role: ClientRole.holder,
  name: 'Synthetic Archived Client',
  gender: Gender.other,
  dob: DateTime.utc(1980),
  phone: null,
  email: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: DateTime.utc(2026, 2),
);

Widget _app(FakeClientRepository repository) {
  final policyRepository = _MockPolicyRepository();
  final planRepository = _MockPlanRepository();
  // Mocktail needs closures to capture these invocations for stubbing.
  when(
    // ignore: unnecessary_lambdas
    () => policyRepository.findAllArchived(),
  ).thenAnswer((_) async => <Policy>[]);
  when(
    // ignore: unnecessary_lambdas
    () => planRepository.findAllArchived(),
  ).thenAnswer((_) async => <Plan>[]);

  return ProviderScope(
    overrides: <Override>[
      clientRepositoryProvider.overrideWith((Ref ref) async => repository),
      policyRepositoryProvider.overrideWith(
        (Ref ref) async => policyRepository,
      ),
      planRepositoryProvider.overrideWith((Ref ref) async => planRepository),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ArchiveScreen(),
    ),
  );
}

void main() {
  testWidgets('renders the three archive tabs', (WidgetTester tester) async {
    await tester.pumpWidget(_app(FakeClientRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Policies'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);
  });

  testWidgets('shows the empty state for each record category', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(FakeClientRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No archived clients'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text('Policies')),
    );
    await tester.pumpAndSettle();
    expect(find.text('No archived policies'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text('Plans')),
    );
    await tester.pumpAndSettle();
    expect(find.text('No archived plans'), findsOneWidget);
  });

  testWidgets('shows archived client information', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(FakeClientRepository(<Client>[_archivedClient()])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Archived Client'), findsOneWidget);
    expect(find.text('Policy holder'), findsOneWidget);
    expect(find.textContaining('Archived on'), findsOneWidget);
  });

  testWidgets('restores a record after confirmation', (
    WidgetTester tester,
  ) async {
    final repository = FakeClientRepository(<Client>[_archivedClient()]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Restore record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(find.text('No archived clients'), findsOneWidget);
    expect(await repository.findAll(), hasLength(1));
  });

  testWidgets('permanently deletes after two confirmations', (
    WidgetTester tester,
  ) async {
    final repository = FakeClientRepository(<Client>[_archivedClient()]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This will permanently delete the record and all related data. This cannot be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you absolutely sure? This is your last chance to cancel.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No archived clients'), findsOneWidget);
    expect(await repository.findAll(includeArchived: true), isEmpty);
  });

  testWidgets('cancelling the first delete confirmation does nothing', (
    WidgetTester tester,
  ) async {
    final repository = FakeClientRepository(<Client>[_archivedClient()]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Archived Client'), findsOneWidget);
    expect(await repository.findAll(includeArchived: true), hasLength(1));
  });

  testWidgets('cancelling the second delete confirmation does nothing', (
    WidgetTester tester,
  ) async {
    final repository = FakeClientRepository(<Client>[_archivedClient()]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Archived Client'), findsOneWidget);
    expect(await repository.findAll(includeArchived: true), hasLength(1));
  });
}
