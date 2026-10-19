import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/clients/screens/client_detail_screen.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';

Client _client() => Client(
  id: '00000000-0000-4000-8000-000000000001',
  role: ClientRole.insured,
  name: 'Detail Example',
  gender: Gender.female,
  dob: DateTime(1988, 6, 12),
  phone: '555-0100',
  email: 'sample@example.invalid',
  notes: 'Synthetic note',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: null,
);

Policy _policy() => Policy(
  id: '00000000-0000-4000-8000-000000000003',
  clientId: '00000000-0000-4000-8000-000000000001',
  policyNo: 'SYNTHETIC-001',
  company: 'Example Insurer',
  effectiveDate: DateTime(2026),
  firstPremiumDate: DateTime(2026),
  currency: 'HKD',
  status: PolicyStatus.active,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  testWidgets('shows the client profile and policy section', (
    WidgetTester tester,
  ) async {
    final client = _client();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clientByIdProvider(
            client.id!,
          ).overrideWith((Ref ref) async => client),
          policiesByClientProvider(
            client.id!,
          ).overrideWith((Ref ref) async => <Policy>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ClientDetailScreen(id: client.id!),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Example'), findsNWidgets(2));
    expect(find.text('Insured'), findsOneWidget);
    expect(find.text('555-0100'), findsOneWidget);
    expect(find.text('sample@example.invalid'), findsOneWidget);
    expect(find.text('Policies'), findsOneWidget);
    expect(find.text('No policies yet'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('renders policy cards and opens the selected policy', (
    WidgetTester tester,
  ) async {
    final client = _client();
    final policy = _policy();
    final router = GoRouter(
      initialLocation: '/clients/${client.id}',
      routes: <RouteBase>[
        GoRoute(
          path: '/clients/:id',
          builder: (context, state) =>
              ClientDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/policies/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Policy route opened')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clientByIdProvider(
            client.id!,
          ).overrideWith((Ref ref) async => client),
          policiesByClientProvider(
            client.id!,
          ).overrideWith((Ref ref) async => <Policy>[policy]),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SYNTHETIC-001'), findsOneWidget);
    await tester.tap(find.text('SYNTHETIC-001'));
    await tester.pumpAndSettle();

    expect(find.text('Policy route opened'), findsOneWidget);
  });

  testWidgets('shows a safe not-found state for missing clients', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clientByIdProvider(
            '00000000-0000-4000-8000-000000000002',
          ).overrideWith((Ref ref) async => null),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ClientDetailScreen(id: '00000000-0000-4000-8000-000000000002'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Client not found'), findsOneWidget);
  });
}
