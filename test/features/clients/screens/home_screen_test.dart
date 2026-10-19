import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/home/screens/home_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';

import '../../../helpers/fake_client_repository.dart';

Client _client({
  required String id,
  required String name,
  required ClientRole role,
  String? phone,
}) => Client(
  id: id,
  role: role,
  name: name,
  gender: Gender.other,
  dob: DateTime(1990, 1, 2),
  phone: phone,
  email: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: null,
);

Widget _testApp(List<Client> clients) {
  final repository = FakeClientRepository(clients);
  final counts = <String, int>{for (final client in clients) client.id!: 0};
  return ProviderScope(
    overrides: <Override>[
      clientRepositoryProvider.overrideWith((Ref ref) async => repository),
      clientPolicyCountsProvider.overrideWith((Ref ref) async => counts),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(),
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no clients', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(<Client>[]));
    await tester.pumpAndSettle();

    expect(find.text('No clients yet'), findsOneWidget);
    expect(find.text('Add client'), findsNWidgets(2));
  });

  testWidgets('renders active clients from the repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Alice Example',
          role: ClientRole.holder,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice Example'), findsOneWidget);
    expect(find.textContaining('Policy holder'), findsNWidgets(2));
  });

  testWidgets('filters clients by role', (WidgetTester tester) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Holder Example',
          role: ClientRole.holder,
        ),
        _client(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Insured Example',
          role: ClientRole.insured,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Insured').last);
    await tester.pumpAndSettle();

    expect(find.text('Insured Example'), findsOneWidget);
    expect(find.text('Holder Example'), findsNothing);
  });

  testWidgets('searches decrypted client names in memory', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Alice Example',
          role: ClientRole.holder,
        ),
        _client(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Bob Example',
          role: ClientRole.insured,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'alice');
    await tester.pumpAndSettle();

    expect(find.text('Alice Example'), findsOneWidget);
    expect(find.text('Bob Example'), findsNothing);
  });

  testWidgets('reports when search or filters match no clients', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Alice Example',
          role: ClientRole.holder,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'not found');
    await tester.pumpAndSettle();

    expect(find.text('No matching clients'), findsOneWidget);
  });

  testWidgets('uses a master-detail layout on desktop', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Desktop Example',
          role: ClientRole.holder,
          phone: '555-0101',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Desktop Example').first);
    await tester.pumpAndSettle();

    expect(find.text('Select a client to view their details'), findsNothing);
    expect(find.textContaining('Desktop Example'), findsNWidgets(2));
    expect(find.text('Open details'), findsOneWidget);
  });
}
