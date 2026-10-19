/// Opens and controls the application's SQLCipher-encrypted database.
///
/// The SQLCipher key is converted to hexadecimal for the native SQLCipher
/// password interface. Windows and Linux use the FFI sqflite factory linked
/// against `sqlcipher_flutter_libs`; Android, iOS, and macOS use the
/// SQLCipher-specific sqflite plugin. In-memory paths support isolated tests.
/// This wrapper is the single application entry point for database access.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;
import 'package:sqflite_sqlcipher/sqflite.dart'
    show Database, OnDatabaseCreateFn;
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'migrations.dart';
import 'schema.dart';

/// A single open SQLCipher database connection.
class AppDatabase {
  AppDatabase._(this.db);

  /// FFI in-memory path, primarily intended for tests.
  static const String inMemoryDatabasePath = ':memory:';

  /// The underlying database connection for repository transactions.
  final Database db;

  /// Opens [path] with a 32-byte SQLCipher [dbKey].
  ///
  /// The key is hex-encoded for the SQLCipher key interface. Opening fails
  /// closed if SQLCipher is unavailable.
  static Future<AppDatabase> open({
    required Uint8List dbKey,
    required String path,
  }) async {
    if (dbKey.length != 32) {
      throw ArgumentError.value(
        dbKey.length,
        'dbKey.length',
        'Must be exactly 32 bytes',
      );
    }

    final hexKey =
        dbKey.map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    const OnDatabaseCreateFn onCreate = _createInitialSchema;
    const onUpgrade = runMigrations;

    late final Database database;
    if (Platform.isWindows || Platform.isLinux) {
      final databaseFactory = ffi.createDatabaseFactoryFfi(
        ffiInit: _initializeDesktopSqlCipher,
      );
      database = await databaseFactory.openDatabase(
        path,
        options: ffi.OpenDatabaseOptions(
          version: Schema.currentSchemaVersion,
          onConfigure: (Database database) async {
            await database.execute('PRAGMA key = "x\'$hexKey\'"');
            await _enableForeignKeys(database);
          },
          onCreate: onCreate,
          onUpgrade: onUpgrade,
        ),
      );
      var validCipher = false;
      try {
        await _requireSqlCipher(database);
        validCipher = true;
      } finally {
        if (!validCipher) {
          await database.close();
        }
      }
    } else {
      database = await cipher.openDatabase(
        path,
        password: hexKey,
        version: Schema.currentSchemaVersion,
        onConfigure: _enableForeignKeys,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
      var validCipher = false;
      try {
        await _requireSqlCipher(database);
        validCipher = true;
      } finally {
        if (!validCipher) {
          await database.close();
        }
      }
    }
    return AppDatabase._(database);
  }

  /// Opens a SQLCipher-encrypted in-memory database for tests.
  static Future<AppDatabase> openInMemory({required Uint8List dbKey}) {
    return open(dbKey: dbKey, path: inMemoryDatabasePath);
  }

  /// Closes the connection and releases its resources.
  Future<void> close() => db.close();

  /// Executes a SQL statement.
  Future<void> execute(String sql) => db.execute(sql);

  /// Queries a table using bound query arguments.
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) {
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  static Future<void> _enableForeignKeys(Database database) {
    return database.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _createInitialSchema(
    Database database,
    int version,
  ) async {
    for (final statement in Schema.createStatements) {
      await database.execute(statement);
    }
    for (final index in Schema.indexes) {
      await database.execute(index);
    }
    await database.insert(
      Schema.schemaVersion,
      <String, Object?>{
        Schema.version: Schema.currentSchemaVersion,
        'applied_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  static Future<void> _requireSqlCipher(Database database) async {
    final rows = await database.rawQuery(
      'PRAGMA cipher_version',
    );
    final cipherVersion = rows.isEmpty ? null : rows.first.values.first;
    if (cipherVersion is! String || cipherVersion.isEmpty) {
      throw StateError('SQLCipher is not available for this database');
    }
  }
}

void _initializeDesktopSqlCipher() {
  if (Platform.isWindows) {
    sqlite_open.open.overrideFor(
      sqlite_open.OperatingSystem.windows,
      _openWindowsSqlCipher,
    );
    sqlite.sqlite3.openInMemory().dispose();
  }
}

DynamicLibrary _openWindowsSqlCipher() => DynamicLibrary.open('sqlite3.dll');
