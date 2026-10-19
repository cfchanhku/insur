import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/verification_result.dart' as audit;
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/features/audit/providers/audit_providers.dart';
import 'package:insur/features/audit/screens/audit_log_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuditRepository extends Mock implements AuditRepository {}

AuditEntry _entry(
  int index, {
  AuditEventType eventType = AuditEventType.create,
  DateTime? timestamp,
}) => AuditEntry(
  id: '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
  timestamp: timestamp ?? DateTime.utc(2026, 1, 1, 12, index),
  eventType: eventType,
  entityType: 'client',
  entityId: '00000000-0000-4000-8000-999999999999',
  metadata: <String, Object?>{'count': index},
  prevHash: '0' * 64,
  entryHash: '${index % 10}' * 64,
);

Widget _app(
  _MockAuditRepository repository, {
  List<Override> overrides = const <Override>[],
}) => ProviderScope(
  overrides: <Override>[
    auditRepositoryProvider.overrideWith((Ref ref) async => repository),
    ...overrides,
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AuditLogScreen(),
  ),
);

void _stubFindAll(_MockAuditRepository repository, List<AuditEntry> entries) {
  when(
    () => repository.findAll(
      eventType: any<AuditEventType?>(named: 'eventType'),
      from: any<DateTime?>(named: 'from'),
      to: any<DateTime?>(named: 'to'),
      limit: any<int?>(named: 'limit'),
    ),
  ).thenAnswer((Invocation invocation) async {
    final eventType = invocation.namedArguments[#eventType] as AuditEventType?;
    final limit = invocation.namedArguments[#limit] as int?;
    return entries
        .where(
          (AuditEntry entry) =>
              eventType == null || entry.eventType == eventType,
        )
        .take(limit ?? entries.length)
        .toList(growable: false);
  });
}

void main() {
  testWidgets('renders event labels, timestamp, and entity type', (
    WidgetTester tester,
  ) async {
    final repository = _MockAuditRepository();
    final entries = <AuditEntry>[
      _entry(1),
      _entry(2, eventType: AuditEventType.loginSuccess),
    ];
    _stubFindAll(repository, entries);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Login success'), findsOneWidget);
    expect(find.textContaining('client'), findsNWidgets(2));
  });

  testWidgets('filters by event type', (WidgetTester tester) async {
    final repository = _MockAuditRepository();
    _stubFindAll(repository, <AuditEntry>[
      _entry(1),
      _entry(2, eventType: AuditEventType.loginSuccess),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All events'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login success').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Login success'),
      ),
      findsOneWidget,
    );
    expect(find.text('Create'), findsNothing);
  });

  test('passes date boundaries through the audit entries provider', () async {
    final repository = _MockAuditRepository();
    _stubFindAll(repository, <AuditEntry>[]);
    final container = ProviderContainer(
      overrides: <Override>[
        auditRepositoryProvider.overrideWith((Ref ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    final from = DateTime.utc(2026, 4);
    final to = DateTime.utc(2026, 4, 30, 23, 59, 59, 999, 999);

    await container.read(
      auditEntriesProvider(AuditFilter(from: from, to: to)).future,
    );

    verify(() => repository.findAll(from: from, to: to, limit: 100)).called(1);
  });

  testWidgets('verify action shows a valid-chain banner', (
    WidgetTester tester,
  ) async {
    final repository = _MockAuditRepository();
    _stubFindAll(repository, <AuditEntry>[_entry(1)]);
    when(repository.verifyChain).thenAnswer(
      (_) async => const audit.VerificationResult.valid(entryCount: 1),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Verify chain'));
    await tester.pumpAndSettle();

    expect(find.text('Chain verified (1 entries)'), findsOneWidget);
  });

  testWidgets('verify action shows a broken-chain reason', (
    WidgetTester tester,
  ) async {
    final repository = _MockAuditRepository();
    _stubFindAll(repository, <AuditEntry>[_entry(1)]);
    when(repository.verifyChain).thenAnswer(
      (_) async => const audit.VerificationResult.broken(
        brokenAt: 2,
        reason: 'Entry hash mismatch at index 2',
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Verify chain'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chain broken at index 2: Entry hash mismatch at index 2'),
      findsOneWidget,
    );
  });

  testWidgets('renders the empty state for no matching entries', (
    WidgetTester tester,
  ) async {
    final repository = _MockAuditRepository();
    _stubFindAll(repository, <AuditEntry>[]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('No audit entries match the filters'), findsOneWidget);
  });

  testWidgets('shows details and copies the full entry JSON', (
    WidgetTester tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText =
              (methodCall.arguments as Map<Object?, Object?>)['text']
                  as String?;
        }
        if (methodCall.method == 'Clipboard.getData') {
          return <String, Object?>{'text': copiedText};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final repository = _MockAuditRepository();
    _stubFindAll(repository, <AuditEntry>[_entry(1)]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Entry details'), findsOneWidget);
    expect(find.text('Previous hash'), findsOneWidget);

    await tester.tap(find.text('Copy JSON'));
    await tester.pumpAndSettle();

    final clipboard = await Clipboard.getData('text/plain');
    expect(clipboard?.text, contains('"entryHash"'));
    expect(copiedText, contains('"entryHash"'));
  });

  testWidgets('loads another page when more than 100 entries are available', (
    WidgetTester tester,
  ) async {
    final repository = _MockAuditRepository();
    _stubFindAll(
      repository,
      List<AuditEntry>.generate(200, (int index) => _entry(index + 1)),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Load more'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Load more'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    verify(() => repository.findAll(limit: 200)).called(1);
  });
}
