/// Declares the versioned SQL schema for local application data.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Provides schema creation statements for a new database.
class InsurSchema {
  /// Current database schema version.
  static const int version = 1;

  /// Returns the SQL statements required to create the initial schema.
  List<String> createStatements() {
    throw UnimplementedError('InsurSchema.createStatements');
  }
}
