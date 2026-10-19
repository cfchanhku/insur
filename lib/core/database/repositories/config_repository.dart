/// Persists non-PII application preferences in the encrypted app configuration
/// table.
library;

import '../database.dart';
import '../schema.dart';

/// Reads and writes non-sensitive settings such as language, theme, and
/// auto-lock preferences.
class ConfigRepository {
  /// Creates a repository for [db].
  ConfigRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// Returns the configured value for [key], or null when it is unset.
  Future<String?> get(String key) async {
    final rows = await _db.query(
      Schema.appConfig,
      where: '${Schema.key} = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final value = rows.single[Schema.value];
    if (value is! String) {
      throw StateError('Stored configuration value is invalid');
    }
    return value;
  }

  /// Stores [value] under [key], updating its UTC modification timestamp.
  Future<void> set(String key, String value) async {
    await _db.db.rawInsert(
      'INSERT OR REPLACE INTO ${Schema.appConfig} '
      '(${Schema.key}, ${Schema.value}, ${Schema.updatedAt}) VALUES (?, ?, ?)',
      <Object?>[key, value, DateTime.now().toUtc().toIso8601String()],
    );
  }

  /// Removes the configuration associated with [key].
  Future<void> delete(String key) async {
    await _db.db.delete(
      Schema.appConfig,
      where: '${Schema.key} = ?',
      whereArgs: <Object?>[key],
    );
  }

  /// Returns all stored configuration values.
  Future<Map<String, String>> getAll() async {
    final rows = await _db.query(Schema.appConfig);
    final values = <String, String>{};
    for (final row in rows) {
      final key = row[Schema.key];
      final value = row[Schema.value];
      if (key is! String || value is! String) {
        throw StateError('Stored configuration is invalid');
      }
      values[key] = value;
    }
    return values;
  }

  /// Clears all configuration values; reserved for an approved reset flow.
  Future<void> clear() async {
    await _db.db.delete(Schema.appConfig);
  }
}
