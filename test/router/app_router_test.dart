import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:insur/features/splash/screens/splash_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:insur/router/app_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeyManager extends Mock implements KeyManager {}

class _KeyManagerOverride {
  const _KeyManagerOverride(this.keyManager);

  final KeyManager keyManager;

  Future<KeyManager> build(Ref _) async => keyManager;
}

void main() {
  group('routerProvider', () {
    test('builds the app router', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(routerProvider), isA<GoRouter>());
    });

    test('starts at the splash route', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      expect(router.routeInformationProvider.value.uri.path, '/');
    });

    testWidgets('resolves the initial route to SplashScreen', (
      WidgetTester tester,
    ) async {
      final keyManager = _MockKeyManager();
      when(keyManager.isInitialized).thenAnswer((_) async => false);
      when(() => keyManager.state).thenReturn(KeyManagerState.uninitialized);
      final container = ProviderContainer(
        overrides: <Override>[
          keyManagerProvider.overrideWith(
            _KeyManagerOverride(keyManager).build,
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
    });

    test('navigates to a registered route', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      final routeInformation = router.routeInformationProvider;

      router.go('/login');

      expect(routeInformation.value.uri.path, '/login');
    });
  });
}
