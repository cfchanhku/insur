import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/hash_chain.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:insur/features/auth/screens/recovery_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeyManager extends Mock implements KeyManager {}

class _MockAuditRepository extends Mock implements AuditRepository {}

AuditEntry _recoveryEntry() => AuditEntry(
  id: '00000000-0000-4000-8000-000000000002',
  timestamp: DateTime.utc(2026),
  eventType: AuditEventType.recoveryUsed,
  entityType: null,
  entityId: null,
  metadata: null,
  prevHash: HashChain.genesisHash,
  entryHash: '2' * 64,
);

Widget _screen({
  required KeyManager keyManager,
  required AuditRepository auditRepository,
}) => ProviderScope(
  overrides: <Override>[
    keyManagerProvider.overrideWith((Ref ref) async => keyManager),
    auditRepositoryProvider.overrideWith((Ref ref) async => auditRepository),
  ],
  child: const MaterialApp(
    locale: Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: RecoveryScreen(),
  ),
);

void main() {
  testWidgets('requires a valid recovery key before passphrase reset', (
    WidgetTester tester,
  ) async {
    final keyManager = _MockKeyManager();
    final auditRepository = _MockAuditRepository();
    when(
      () => keyManager.recoveryKeyLogin(recoveryKey: any(named: 'recoveryKey')),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _screen(keyManager: keyManager, auditRepository: auditRepository),
    );
    await tester.enterText(find.byType(TextField), 'synthetic-invalid-key');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('That recovery key is invalid. Check it and try again.'),
      findsOneWidget,
    );
    expect(
      find.text('Set a new passphrase to finish recovering your vault.'),
      findsNothing,
    );
  });

  testWidgets('requires a new passphrase after successful recovery', (
    WidgetTester tester,
  ) async {
    final keyManager = _MockKeyManager();
    final auditRepository = _MockAuditRepository();
    when(
      () => keyManager.recoveryKeyLogin(recoveryKey: any(named: 'recoveryKey')),
    ).thenAnswer((_) async => true);
    when(() => keyManager.state).thenReturn(KeyManagerState.unlocked);
    when(
      () => auditRepository.append(eventType: AuditEventType.recoveryUsed),
    ).thenAnswer((_) async => _recoveryEntry());

    await tester.pumpWidget(
      _screen(keyManager: keyManager, auditRepository: auditRepository),
    );
    await tester.enterText(find.byType(TextField), 'synthetic-recovery-key');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('Set a new passphrase to finish recovering your vault.'),
      findsOneWidget,
    );
    expect(find.text('New passphrase'), findsOneWidget);
    expect(find.text('Confirm passphrase'), findsOneWidget);
  });
}
