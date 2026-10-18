/// Applies ordered database schema migrations transactionally.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Coordinates migration from one stored schema version to another.
class DatabaseMigrator {
  /// Migrates the database from [fromVersion] to [toVersion].
  Future<void> migrate({
    required int fromVersion,
    required int toVersion,
  }) async {
    throw UnimplementedError();
  }
}
