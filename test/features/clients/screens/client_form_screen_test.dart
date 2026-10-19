import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/clients/screens/client_form_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';

Client _client() => Client(
  id: '00000000-0000-4000-8000-000000000001',
  role: ClientRole.holder,
  name: 'Existing Example',
  gender: Gender.other,
  dob: DateTime(1990, 1, 2),
  phone: null,
  email: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: null,
);

Widget _localizedApp(
  Widget child, {
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('renders a blank create form', (WidgetTester tester) async {
    await tester.pumpWidget(_localizedApp(const ClientFormScreen()));

    expect(find.text('New client'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5));
  });

  testWidgets('loads and pre-populates the client in edit mode', (
    WidgetTester tester,
  ) async {
    final client = _client();
    await tester.pumpWidget(
      _localizedApp(
        ClientFormScreen(id: client.id),
        overrides: <Override>[
          clientByIdProvider(
            client.id!,
          ).overrideWith((Ref ref) async => client),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit client'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Existing Example'),
      findsOneWidget,
    );
  });
}
