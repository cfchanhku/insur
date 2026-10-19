import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/clients/widgets/client_card.dart';
import 'package:insur/l10n/app_localizations.dart';

Client _client() => Client(
  id: '00000000-0000-4000-8000-000000000001',
  role: ClientRole.holder,
  name: 'Sample Client',
  gender: Gender.female,
  dob: DateTime(1988, 6, 12),
  phone: null,
  email: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: null,
);

Widget _testApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('shows name, role, date, and policy count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(ClientCard(client: _client(), policyCount: 1)),
    );

    expect(find.text('Sample Client'), findsOneWidget);
    expect(find.textContaining('Policy holder'), findsOneWidget);
    expect(find.textContaining('1 policy'), findsOneWidget);
  });

  testWidgets('uses plural policy label for several policies', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(ClientCard(client: _client(), policyCount: 3)),
    );

    expect(find.textContaining('3 policies'), findsOneWidget);
  });

  testWidgets('invokes onTap when the card is tapped', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _testApp(
        ClientCard(
          client: _client(),
          policyCount: 0,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Sample Client'));
    expect(tapped, isTrue);
  });
}
