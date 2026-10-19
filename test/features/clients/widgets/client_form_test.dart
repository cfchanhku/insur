import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/clients/widgets/client_form.dart';
import 'package:insur/l10n/app_localizations.dart';

Widget _testApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _scrollToFormActions(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('requires a name and date of birth', (WidgetTester tester) async {
    await tester.pumpWidget(
      _testApp(
        ClientForm(initialClient: null, onSaved: (_) async {}, onCancel: () {}),
      ),
    );

    await _scrollToFormActions(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Date of birth is required'), findsOneWidget);
  });

  testWidgets('submits trimmed values for a valid existing client', (
    WidgetTester tester,
  ) async {
    final client = Client(
      id: '00000000-0000-4000-8000-000000000001',
      role: ClientRole.holder,
      name: 'Initial Name',
      gender: Gender.female,
      dob: DateTime(1988, 6, 12),
      phone: null,
      email: null,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      archivedAt: null,
    );
    Client? saved;
    await tester.pumpWidget(
      _testApp(
        ClientForm(
          initialClient: client,
          onSaved: (value) async => saved = value,
          onCancel: () {},
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      '  Updated Name  ',
    );
    await _scrollToFormActions(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved?.name, 'Updated Name');
    expect(saved?.id, client.id);
  });

  testWidgets('invokes cancel callback', (WidgetTester tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      _testApp(
        ClientForm(
          initialClient: null,
          onSaved: (_) async {},
          onCancel: () => cancelled = true,
        ),
      ),
    );

    await _scrollToFormActions(tester);
    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });
}
