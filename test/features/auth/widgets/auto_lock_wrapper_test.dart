import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/hash_chain.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/repositories/config_repository.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:insur/features/auth/widgets/auto_lock_wrapper.dart';
import 'package:insur/features/settings/settings_keys.dart';
import 'package:insur/features/settings/settings_notifier.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:insur/router/app_router.dart';
import 'package:mocktail/mocktail.dart';

class _MemoryConfigRepository implements ConfigRepository {
  _MemoryConfigRepository(int minutes)
    : values = <String, String>{SettingsKeys.autoLockMinutes: '$minutes'};

  final Map<String, String> values;

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> setAll(Map<String, String> values) async {
    this.values.addAll(values);
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

AuditEntry _autoLockEntry() => AuditEntry(
  id: '00000000-0000-4000-8000-000000000001',
  timestamp: DateTime.utc(2026),
  eventType: AuditEventType.autoLock,
  entityType: null,
  entityId: null,
  metadata: null,
  prevHash: HashChain.genesisHash,
  entryHash: '1' * 64,
);

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    GoRoute(
      path: '/home',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: TextButton(onPressed: _noop, child: Text('Activity')),
        ),
      ),
    ),
    GoRoute(
      path: '/lock',
      builder: (context, state) =>
          const Scaffold(body: Text('Locked route opened')),
    ),
  ],
);

ProviderContainer _container({
  required _MemoryConfigRepository config,
  required _MockKeyManager keyManager,
  required _MockAuditRepository audit,
  required GoRouter router,
}) => ProviderContainer(
  overrides: <Override>[
    configRepositoryProvider.overrideWith((Ref ref) async => config),
    keyManagerProvider.overrideWith((Ref ref) async => keyManager),
    keyManagerStateProvider.overrideWith((Ref ref) => KeyManagerState.unlocked),
    auditRepositoryProvider.overrideWith((Ref ref) async => audit),
    routerProvider.overrideWith((Ref ref) => router),
  ],
);

void _noop() {}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: container.read(routerProvider),
    builder: (BuildContext context, Widget? child) =>
        AutoLockWrapper(child: child ?? const SizedBox.shrink()),
  ),
);

void _stubLock(_MockKeyManager keyManager, _MockAuditRepository audit) {
  var state = KeyManagerState.unlocked;
  when(() => keyManager.state).thenAnswer((_) => state);
  when(keyManager.lock).thenAnswer((_) async {
    state = KeyManagerState.locked;
  });
  when(
    () => audit.append(eventType: AuditEventType.autoLock),
  ).thenAnswer((_) async => _autoLockEntry());
}

void main() {
  testWidgets('pointer activity resets the inactivity timer', (
    WidgetTester tester,
  ) async {
    final keyManager = _MockKeyManager();
    final audit = _MockAuditRepository();
    _stubLock(keyManager, audit);
    final router = _router();
    final container = _container(
      config: _MemoryConfigRepository(5),
      keyManager: keyManager,
      audit: audit,
      router: router,
    );
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 4));
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 4));
    expect(find.text('Locked route opened'), findsNothing);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.text('Locked route opened'), findsOneWidget);
  });

  testWidgets('changing auto-lock setting restarts the timer at new duration', (
    WidgetTester tester,
  ) async {
    final keyManager = _MockKeyManager();
    final audit = _MockAuditRepository();
    _stubLock(keyManager, audit);
    final router = _router();
    final config = _MemoryConfigRepository(5);
    final container = _container(
      config: config,
      keyManager: keyManager,
      audit: audit,
      router: router,
    );
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 4));
    await container.read(settingsProvider.notifier).updateAutoLockMinutes(15);
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('Locked route opened'), findsNothing);
    await tester.pump(const Duration(minutes: 10));
    await tester.pumpAndSettle();

    expect(find.text('Locked route opened'), findsOneWidget);
  });

  testWidgets('timeout records the event and locks the key manager', (
    WidgetTester tester,
  ) async {
    final keyManager = _MockKeyManager();
    final audit = _MockAuditRepository();
    _stubLock(keyManager, audit);
    final router = _router();
    final container = _container(
      config: _MemoryConfigRepository(5),
      keyManager: keyManager,
      audit: audit,
      router: router,
    );
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 5));
    await tester.pumpAndSettle();

    expect(find.text('Locked route opened'), findsOneWidget);
    verify(() => audit.append(eventType: AuditEventType.autoLock)).called(1);
    verify(keyManager.lock).called(1);
  });

  testWidgets('does not start the inactivity timer while locked', (
    WidgetTester tester,
  ) async {
    final keyManager = _MockKeyManager();
    final audit = _MockAuditRepository();
    _stubLock(keyManager, audit);
    final router = _router();
    final container = _container(
      config: _MemoryConfigRepository(5),
      keyManager: keyManager,
      audit: audit,
      router: router,
    );
    container.read(keyManagerStateProvider.notifier).state =
        KeyManagerState.locked;
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 6));

    expect(find.text('Locked route opened'), findsNothing);
    verifyNever(() => audit.append(eventType: AuditEventType.autoLock));
  });
}
