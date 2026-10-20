import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/home/screens/home_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';

import '../../../helpers/fake_client_repository.dart';

Client _client({
  required String id,
  required String name,
  required ClientRole role,
  String? phone,
}) => Client(
  id: id,
  role: role,
  name: name,
  gender: Gender.other,
  dob: DateTime(1990, 1, 2),
  phone: phone,
  email: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  archivedAt: null,
);

Widget _testApp(List<Client> clients, {ThemeData? theme}) {
  final repository = FakeClientRepository(clients);
  final counts = <String, int>{for (final client in clients) client.id!: 0};
  return ProviderScope(
    overrides: <Override>[
      clientRepositoryProvider.overrideWith((Ref ref) async => repository),
      clientPolicyCountsProvider.overrideWith((Ref ref) async => counts),
    ],
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ),
  );
}

Widget _testAppWithRouter(
  List<Client> clients,
  GoRouter router, {
  ThemeData? theme,
}) {
  final repository = FakeClientRepository(clients);
  final counts = <String, int>{for (final client in clients) client.id!: 0};
  return ProviderScope(
    overrides: <Override>[
      clientRepositoryProvider.overrideWith((Ref ref) async => repository),
      clientPolicyCountsProvider.overrideWith((Ref ref) async => counts),
    ],
    child: MaterialApp.router(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void _useDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('shows the empty state when there are no clients', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[], theme: ThemeData(platform: TargetPlatform.windows)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No clients yet'), findsOneWidget);
    expect(find.text('Add client'), findsNWidgets(2));
  });

  testWidgets('renders active clients from the repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Alice Example',
          role: ClientRole.holder,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice Example'), findsOneWidget);
    expect(find.textContaining('Policy holder'), findsNWidgets(2));
  });

  testWidgets('filters clients by role', (WidgetTester tester) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Holder Example',
          role: ClientRole.holder,
        ),
        _client(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Insured Example',
          role: ClientRole.insured,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Insured').last);
    await tester.pumpAndSettle();

    expect(find.text('Insured Example'), findsOneWidget);
    expect(find.text('Holder Example'), findsNothing);
  });

  testWidgets('searches decrypted client names in memory', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Alice Example',
          role: ClientRole.holder,
        ),
        _client(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Bob Example',
          role: ClientRole.insured,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'alice');
    await tester.pumpAndSettle();

    expect(find.text('Alice Example'), findsOneWidget);
    expect(find.text('Bob Example'), findsNothing);
  });

  testWidgets('reports when search or filters match no clients', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Alice Example',
          role: ClientRole.holder,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'not found');
    await tester.pumpAndSettle();

    expect(find.text('No matching clients'), findsOneWidget);
  });

  testWidgets('uses a master-detail layout on desktop', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Desktop Example',
          role: ClientRole.holder,
          phone: '555-0101',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Desktop Example').first);
    await tester.pumpAndSettle();

    expect(find.text('Select a client to view their details'), findsNothing);
    expect(find.textContaining('Desktop Example'), findsNWidgets(2));
    expect(find.text('Client information'), findsOneWidget);
  });

  testWidgets('uses a two-pane layout at tablet widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(<Client>[
        _client(
          id: '00000000-0000-4000-8000-000000000001',
          name: 'Tablet Example',
          role: ClientRole.holder,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Select a client to view their details'), findsOneWidget);
    await tester.tap(find.text('Tablet Example').first);
    await tester.pumpAndSettle();

    expect(find.text('Client information'), findsOneWidget);
  });

  testWidgets('Ctrl+F focuses the client search field on desktop', (
    WidgetTester tester,
  ) async {
    _useDesktopViewport(tester);
    await tester.pumpWidget(
      _testApp(<Client>[], theme: ThemeData(platform: TargetPlatform.windows)),
    );
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey<String>('home-search'));
    expect(Theme.of(tester.element(search)).platform, TargetPlatform.windows);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(HardwareKeyboard.instance.isControlPressed, isTrue);
    final handled = await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    expect(handled, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
  });

  testWidgets('Ctrl+N does not navigate while text input is focused', (
    WidgetTester tester,
  ) async {
    _useDesktopViewport(tester);
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/clients/new',
          builder: (_, _) => const Scaffold(body: Text('New client route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _testAppWithRouter(
        <Client>[],
        router,
        theme: ThemeData(platform: TargetPlatform.windows),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-search')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'search text',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('New client route'), findsNothing);
  });

  testWidgets('Ctrl+N opens the new client route when not typing', (
    WidgetTester tester,
  ) async {
    _useDesktopViewport(tester);
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/clients/new',
          builder: (_, _) => const Scaffold(body: Text('New client route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _testAppWithRouter(
        <Client>[],
        router,
        theme: ThemeData(platform: TargetPlatform.windows),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('home-search')),
    );
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).platform,
      TargetPlatform.windows,
    );
    expect(searchField.focusNode!.hasFocus, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget is EditableText,
      isFalse,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final handled = await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    expect(handled, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('New client route'), findsOneWidget);
  });
}
