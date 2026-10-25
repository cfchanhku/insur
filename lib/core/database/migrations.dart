/// Runs ordered, forward-only database migrations.
///
/// Never modify a migration that has shipped; add a new numbered migration
/// instead. The sqflite `onUpgrade` callback invokes this function inside its
/// migration transaction, so schema changes and version records roll back
/// together on failure.
library;

import 'package:sqflite_sqlcipher/sqflite.dart';

import 'schema.dart';

/// Applies all migrations from [oldVersion] through [newVersion].
Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 0 ||
      newVersion < oldVersion ||
      newVersion > Schema.currentSchemaVersion) {
    throw ArgumentError('Unsupported schema version transition');
  }

  for (var version = oldVersion + 1; version <= newVersion; version++) {
    switch (version) {
      case 1:
        if (oldVersion != 0) {
          throw StateError('Migration to schema version 1 is not supported');
        }
        for (final statement in Schema.createStatements) {
          await db.execute(statement);
        }
        for (final index in Schema.indexes) {
          await db.execute(index);
        }
      case 2:
        for (final trigger in Schema.auditTriggers) {
          await db.execute(trigger);
        }
      case 3:
        await db.execute(
          'ALTER TABLE ${Schema.plans} ADD COLUMN ${Schema.deductible} TEXT',
        );
      case 4:
        await db.execute(
          'ALTER TABLE ${Schema.plans} ADD COLUMN ${Schema.insuredId} TEXT '
          'REFERENCES ${Schema.clients}(${Schema.id}) ON DELETE SET NULL',
        );
        await db.execute(
          'CREATE INDEX idx_plans_insured ON ${Schema.plans}(${Schema.insuredId})',
        );
      default:
        throw StateError('No migration is defined for schema version $version');
    }

    await db.insert(Schema.schemaVersion, <String, Object?>{
      Schema.version: version,
      'applied_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
