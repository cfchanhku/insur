import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/backup/backup_file_service.dart';
import 'package:insur/core/backup/backup_result.dart';
import 'package:insur/core/backup/backup_service.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/config_repository.dart';
import 'package:insur/core/security/key_manager.dart';
import 'package:insur/features/backup/screens/backup_screen.dart';
import 'package:insur/features/settings/settings_notifier.dart';
import 'package:insur/features/settings/settings_state.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';
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
  Future<void> setAll(Map<String, String> values) async {
    this.values.addAll(values);
  }

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<Map<String, String>> getAll() async => Map<String, String>.of(values);

  @override
  Future<void> clear() async => values.clear();
}

class _SettingsNotifier extends SettingsNotifier {
  @override
  Future<SettingsState> build() async => const SettingsState();
}

class _MockBackupService extends Mock implements BackupService {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _BackupFileService implements BackupFileService {
  _BackupFileService(this.destination);

  final String destination;

  @override
  Future<String?> pickDirectory() async => null;

  @override
  Future<String?> pickSaveLocation({
    required String suggestedName,
    String extension = 'enc',
  }) async => destination;

  @override
  Future<String?> pickOpenFile() async => null;

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {}

  @override
  Future<Uint8List> readBytes(String path) async => Uint8List(0);

  @override
  Future<bool> exists(String path) async => false;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<Directory> getDefaultBackupDirectory() async => Directory.systemTemp;
}

Widget _app(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BackupScreen(),
  ),
);

void main() {
  testWidgets('renders backup information and protected passphrase fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(<Override>[settingsProvider.overrideWith(_SettingsNotifier.new)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Encrypted backup'), findsOneWidget);
    expect(find.text('No backups yet'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      tester.widget<TextField>(find.byType(TextField).first).obscureText,
      isTrue,
    );
    expect(find.text('Choose destination'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('enables create only after valid passphrase and destination', (
    WidgetTester tester,
  ) async {
    final destination = _BackupFileService(r'C:\synthetic\backup.enc');
    await tester.pumpWidget(
      _app(<Override>[
        settingsProvider.overrideWith(_SettingsNotifier.new),
        appVersionProvider.overrideWith((Ref ref) async => '0.1.0'),
        backupFileServiceProvider.overrideWithValue(destination),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'long backup passphrase',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'long backup passphrase',
    );
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Choose destination'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'creates backup, records metadata, and clears passphrase fields',
    (WidgetTester tester) async {
      final database = _MockAppDatabase();
      when(() => database.path).thenReturn(r'C:\synthetic\vault.db');
      when(database.close).thenAnswer((_) async {});
      final keyManager = _MockKeyManager();
      when(() => keyManager.state).thenReturn(KeyManagerState.unlocked);
      final backupService = _MockBackupService();
      final createdAt = DateTime.utc(2026, 5, 1, 12);
      final result = BackupResult(
        success: true,
        path: r'C:\synthetic\backup.enc',
        sizeBytes: 2048,
        createdAt: createdAt,
      );
      when(
        () => backupService.createBackup(
          passphrase: any<String>(named: 'passphrase'),
          dbFilePath: any<String>(named: 'dbFilePath'),
          destinationPath: any<String>(named: 'destinationPath'),
        ),
      ).thenAnswer((_) async => result);
      when(
        () => backupService.recordBackupAudit(result),
      ).thenAnswer((_) async {});
      final config = _MemoryConfigRepository();
      await tester.pumpWidget(
        _app(<Override>[
          settingsProvider.overrideWith(_SettingsNotifier.new),
          configRepositoryProvider.overrideWith((Ref ref) async => config),
          appVersionProvider.overrideWith((Ref ref) async => '0.1.0'),
          backupFileServiceProvider.overrideWithValue(
            _BackupFileService(result.path),
          ),
          keyManagerProvider.overrideWith((Ref ref) async => keyManager),
          keyManagerStateProvider.overrideWith(
            (Ref ref) => KeyManagerState.unlocked,
          ),
          appDatabaseProvider.overrideWith((Ref ref) async => database),
          backupServiceProvider.overrideWith((Ref ref) async => backupService),
        ]),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).at(0),
        'long backup passphrase',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'long backup passphrase',
      );
      await tester.pump();
      await tester.tap(find.text('Choose destination'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Backup created'), findsOneWidget);
      expect(find.textContaining(result.path), findsWidgets);
      verify(
        () => backupService.createBackup(
          passphrase: 'long backup passphrase',
          dbFilePath: r'C:\synthetic\vault.db',
          destinationPath: result.path,
        ),
      ).called(1);
      verify(database.close).called(1);
      verify(() => backupService.recordBackupAudit(result)).called(1);
      expect(find.text('No backups yet'), findsNothing);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((TextField field) => field.controller!.text.isEmpty),
        isTrue,
      );
    },
  );
}
