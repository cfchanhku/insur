import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/clients/screens/client_detail_screen.dart';
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
          clientPolicyCountProvider(
            client.id!,
          ).overrideWith((Ref ref) async => 0),
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
