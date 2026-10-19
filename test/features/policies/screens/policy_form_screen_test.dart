import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/policies/screens/policy_form_screen.dart';
import 'package:insur/l10n/app_localizations.dart';

Widget _app() => const ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PolicyFormScreen(clientId: '123e4567-e89b-42d3-a456-426614174001'),
  ),
);

void main() {
  testWidgets('renders create fields with save action enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('New policy'), findsOneWidget);
    expect(find.text('Insurer'), findsOneWidget);
    expect(find.text('Policy number'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('empty required fields show validation errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Insurer is required'), findsOneWidget);
    expect(find.text('Policy number is required'), findsOneWidget);
  });
}
