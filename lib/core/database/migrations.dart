/// Applies ordered database schema migrations transactionally.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Coordinates migration from one stored schema version to another.
class DatabaseMigrator {
  /// Applies one migration from version [fromVersion] to [toVersion].
  Future<void> migrateOne({
    required int fromVersion,
    required int toVersion,
  }) async {
    throw UnimplementedError('DatabaseMigrator.migrateOne');
  }

  /// Migrates the database from [fromVersion] to [toVersion].
  Future<void> migrate({
    required int fromVersion,
    required int toVersion,
  }) async {
    throw UnimplementedError('DatabaseMigrator.migrate');
  }
}
