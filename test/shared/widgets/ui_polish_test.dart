import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/shared/widgets/async_button.dart';
import 'package:insur/shared/widgets/empty_state.dart';
import 'package:insur/shared/widgets/skeletons.dart';
import 'package:insur/theme/app_theme.dart';

void main() {
  group('AsyncButton', () {
    testWidgets('shows progress and disables itself while its action runs', (
      WidgetTester tester,
    ) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncButton(label: 'Save', onPressed: () => completer.future),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  });

  group('loading and empty states', () {
    testWidgets('client skeleton renders without overflow in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: ClientListSkeleton()),
        ),
      );

      expect(find.byType(CardSkeleton), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('policy, plan, and audit skeletons render in their contexts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[PolicyListSkeleton(), PlanListSkeleton()],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CardSkeleton), findsNWidgets(6));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AuditListSkeleton())),
      );

      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state remains readable with enlarged text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: EmptyState(
                icon: Icons.people_outline,
                title: 'No clients',
                subtitle: 'Add a client to get started.',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No clients'), findsOneWidget);
      expect(find.text('Add a client to get started.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
