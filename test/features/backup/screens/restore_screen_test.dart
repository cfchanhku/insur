import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/backup/screens/restore_screen.dart';
import 'package:insur/l10n/app_localizations.dart';
import 'package:insur/providers/app_providers.dart';

import '../../../core/backup/fake_backup_file_service.dart';

void main() {
  testWidgets('requires file, passphrase, and overwrite confirmation', (
    WidgetTester tester,
  ) async {
    final fileService = FakeBackupFileService(Directory(r'C:\synthetic'))
      ..selectedFilePath = r'C:\synthetic\backup.enc';
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          backupFileServiceProvider.overrideWithValue(fileService),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RestoreScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final restoreButton = find.widgetWithText(FilledButton, 'Restore now');
    expect(restoreButton, findsOneWidget);
    expect(tester.widget<FilledButton>(restoreButton).onPressed, isNull);

    await tester.tap(find.text('Select backup file'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'backup passphrase');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    expect(tester.widget<FilledButton>(restoreButton).onPressed, isNotNull);
    expect(find.textContaining('backup.enc'), findsOneWidget);
  });

  testWidgets('canceling overwrite confirmation does not navigate or restore', (
    WidgetTester tester,
  ) async {
    final fileService = FakeBackupFileService(Directory(r'C:\synthetic'))
      ..selectedFilePath = r'C:\synthetic\backup.enc';
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          backupFileServiceProvider.overrideWithValue(fileService),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RestoreScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Select backup file'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'backup passphrase');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Restore now'));
    await tester.pumpAndSettle();

    expect(find.text('Restore from backup?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Restore from backup?'), findsNothing);
    expect(find.text('Restore now'), findsOneWidget);
  });
}
