import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insur/app.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/hash_chain.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/repositories/config_repository.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:insur/features/settings/screens/settings_screen.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:insur/router/app_router.dart';
import 'package:mocktail/mocktail.dart';

class _MemoryConfigRepository implements ConfigRepository {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<Map<String, String>> getAll() async => Map<String, String>.of(values);

  @override
  Future<void> clear() async => values.clear();
}

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
      path: '/settings/audit',
      builder: (context, state) =>
          const Scaffold(body: Text('Audit route opened')),
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
  required _MemoryConfigRepository config,
  List<Override> overrides = const <Override>[],
}) => ProviderScope(
  overrides: <Override>[
    configRepositoryProvider.overrideWith((Ref ref) async => config),
    appVersionProvider.overrideWith((Ref ref) async => '0.1.0'),
    biometricAvailabilityProvider.overrideWith((Ref ref) async => false),
    routerProvider.overrideWith((Ref ref) => router),
    ...overrides,
  ],
  child: const InsurApp(),
);

Future<void> _pumpSettings(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    _app(
      router: router,
      config: _MemoryConfigRepository(),
      overrides: overrides,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _showText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets('renders all settings groups and app version', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);

    for (final title in <String>[
      'General',
      'Security',
      'Backup',
      'Audit',
      'About',
      'Danger zone',
    ]) {
      await _showText(tester, title);
      expect(find.text(title), findsOneWidget);
    }
    await _showText(tester, '0.1.0');
    expect(find.text('0.1.0'), findsOneWidget);
    expect(find.text('Settings coming soon'), findsNothing);
  });

  testWidgets('changing language immediately updates app locale', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('繁體中文'));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsNWidgets(2));
    expect(find.text('一般'), findsOneWidget);
  });

  testWidgets('changing theme immediately updates app theme mode', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('disables biometric toggle when device support is unavailable', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);
    await _showText(tester, 'Biometric unlock');

    expect(find.text('Not available on this device'), findsOneWidget);
    final switchTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Biometric unlock'),
    );
    expect(switchTile.onChanged, isNull);
  });

  testWidgets('shows the passphrase guidance dialog', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);
    await _showText(tester, 'Change passphrase');
    await tester.tap(find.text('Change passphrase'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      find.textContaining('Use your Recovery Key to reset your passphrase.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the recovery-key coming-soon dialog', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);
    await _showText(tester, 'Regenerate recovery key');
    await tester.tap(find.text('Regenerate recovery key'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      find.text('This feature will be available in a future update.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the reset-app coming-soon dialog', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);
    await _showText(tester, 'Reset app');
    await tester.tap(find.text('Reset app'));
    await tester.pumpAndSettle();

    expect(
      find.text('This feature will be available in a future update.'),
      findsOneWidget,
    );
  });

  testWidgets('navigates to audit history', (WidgetTester tester) async {
    await _pumpSettings(tester);
    await _showText(tester, 'View audit log');
    await tester.tap(find.text('View audit log'));
    await tester.pumpAndSettle();

    expect(find.text('Audit route opened'), findsOneWidget);
  });

  testWidgets('logout button requests confirmation', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);
    await _showText(tester, 'Logout');
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
    final audit = _MockAuditRepository();
    final keyManager = _MockKeyManager();
    when(
      () => audit.append(eventType: AuditEventType.logout),
    ).thenAnswer((_) async => _logoutEntry());
    when(keyManager.logout).thenAnswer((_) => Future<void>.value());
    when(() => keyManager.state).thenReturn(KeyManagerState.uninitialized);

    await _pumpSettings(
      tester,
      overrides: <Override>[
        auditRepositoryProvider.overrideWith((Ref ref) async => audit),
        keyManagerProvider.overrideWith((Ref ref) async => keyManager),
      ],
    );
    await _showText(tester, 'Logout');
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Login screen opened'), findsOneWidget);
    verify(() => audit.append(eventType: AuditEventType.logout)).called(1);
    verify(keyManager.logout).called(1);
  });
}
