import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqlite3/open.dart' as sqlite_open;

final ffi.DatabaseFactory? _macOsTestDatabaseFactory =
    _createMacOsTestDatabaseFactory();

/// Opens a SQLCipher database with the test-specific factory where needed.
Future<AppDatabase> openTestDatabase({
  required Uint8List dbKey,
  required String path,
}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  return AppDatabase.open(
    dbKey: dbKey,
    path: path,
    databaseFactory: _macOsTestDatabaseFactory,
  );
}

/// Opens an isolated SQLCipher in-memory database using synthetic key bytes.
Future<AppDatabase> createTestDatabase() {
  final testKey = Uint8List.fromList(List<int>.filled(32, 0x42));
  return openTestDatabase(
    dbKey: testKey,
    path: AppDatabase.inMemoryDatabasePath,
  );
}

ffi.DatabaseFactory? _createMacOsTestDatabaseFactory() {
  if (!Platform.isMacOS) {
    return null;
  }

  final libraryPath = Platform.environment['INSUR_SQLCIPHER_LIBRARY'];
  if (libraryPath == null || libraryPath.isEmpty) {
    throw StateError(
      'macOS database tests require SQLCipher. Install it with '
      '`brew install sqlcipher`, then set INSUR_SQLCIPHER_LIBRARY to '
      '`brew --prefix sqlcipher` plus `/lib/libsqlcipher.dylib`.',
    );
  }

  sqlite_open.open.overrideFor(
    sqlite_open.OperatingSystem.macOS,
    () => DynamicLibrary.open(libraryPath),
  );
  return ffi.createDatabaseFactoryFfi(noIsolate: true);
}

/// Closes [database] after a test.
Future<void> tearDownTestDatabase(AppDatabase database) => database.close();
