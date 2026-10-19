import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/hash_chain.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:insur/features/settings/screens/settings_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuditRepository extends Mock implements AuditRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

AuditEntry _logoutEntry() => AuditEntry(
  id: '00000000-0000-4000-8000-000000000001',
  timestamp: DateTime.utc(2026),
  eventType: AuditEventType.logout,
  entityType: null,
  entityId: null,
  metadata: null,
  prevHash: HashChain.genesisHash,
  entryHash: '1' * 64,
);

GoRouter _router() => GoRouter(
  initialLocation: '/settings',
  routes: <RouteBase>[
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const Scaffold(body: Text('Login screen opened')),
    ),
  ],
);

Widget _app({
  required GoRouter router,
  List<Override> overrides = const <Override>[],
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ),
);

void main() {
  testWidgets('renders settings title and future-update content', (
    WidgetTester tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router: router));

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(find.text('Settings coming soon'), findsOneWidget);
    expect(find.textContaining('Language, auto-lock'), findsOneWidget);
  });

  testWidgets('logout button requests confirmation', (
    WidgetTester tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router: router));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Logout?'), findsOneWidget);
    expect(
      find.text('You will need your passphrase to sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('confirmed logout records event and navigates to login', (
    WidgetTester tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    final audit = _MockAuditRepository();
    final keyManager = _MockKeyManager();
    when(
      () => audit.append(eventType: AuditEventType.logout),
    ).thenAnswer((_) async => _logoutEntry());
    when(keyManager.logout).thenAnswer((_) => Future<void>.value());
    when(() => keyManager.state).thenReturn(KeyManagerState.uninitialized);

    await tester.pumpWidget(
      _app(
        router: router,
        overrides: <Override>[
          auditRepositoryProvider.overrideWith((Ref ref) async => audit),
          keyManagerProvider.overrideWith((Ref ref) async => keyManager),
        ],
      ),
    );
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Login screen opened'), findsOneWidget);
    verify(() => audit.append(eventType: AuditEventType.logout)).called(1);
    verify(keyManager.logout).called(1);
  });
}
