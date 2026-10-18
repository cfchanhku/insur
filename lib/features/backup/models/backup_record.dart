/// Describes metadata for a locally created encrypted backup.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Metadata identifying a backup without containing backup contents.
class BackupRecord {
  /// Creates backup metadata.
  const BackupRecord({
    required this.id,
    required this.createdAt,
    required this.schemaVersion,
  });

  /// UUID identifying this backup.
  final String id;

  /// UTC time at which the backup was created.
  final DateTime createdAt;

  /// Database schema version represented by the backup.
  final int schemaVersion;
}
