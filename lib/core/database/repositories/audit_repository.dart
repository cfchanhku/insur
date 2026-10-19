/// Persists append-only audit events and verifies their hash chain.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart' show Transaction;
import 'package:uuid/uuid.dart';

import '../../audit/audit_entry.dart';
import '../../audit/audit_event_type.dart';
import '../../audit/hash_chain.dart';
import '../../audit/verification_result.dart';
import '../database.dart';
import '../schema.dart';

/// Reads, appends, verifies, and retention-purges audit entries.
class AuditRepository {
  /// Creates a repository for [db].
  AuditRepository({required AppDatabase db}) : _db = db;

  static const Uuid _uuid = Uuid();
  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _hashPattern = RegExp(r'^[0-9a-f]{64}$');

  /// Default retention period for audit events.
  static const Duration retention = Duration(days: 365 * 2);

  /// Metadata keys that can expose personally identifiable or policy data.
  static const Set<String> forbiddenMetadataKeys = <String>{
    'name',
    'dob',
    'phone',
    'email',
    'address',
    'policy_no',
    'coverage_amount',
    'notes',
    'id_number',
  };

  final AppDatabase _db;
  String _lastHash = HashChain.genesisHash;
  DateTime? _lastTimestamp;
  bool _initialized = false;
  Future<void> _writeTail = Future<void>.value();

  /// Loads the latest persisted hash, or the genesis hash for an empty table.
  Future<void> initialize() {
    return _serialize(() async {
      await _initializeIfNeeded();
    });
  }

  /// Appends an immutable event linked to the latest persisted entry.
  Future<AuditEntry> append({
    required AuditEventType eventType,
    String? entityType,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    return recordMutation(
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
      mutation: (_) async {},
    );
  }

  /// Commits a business mutation and its audit entry in the same transaction.
  ///
  /// This prevents a persisted business change from being left without its
  /// corresponding audit event if hashing or insertion fails.
  Future<AuditEntry> recordMutation({
    required AuditEventType eventType,
    required Future<void> Function(Transaction transaction) mutation,
    String? entityType,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    _validateMetadata(metadata);
    return _serialize(() async {
      await _initializeIfNeeded();
      final entry = await _createEntry(
        prevHash: _lastHash,
        eventType: eventType,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
        timestamp: _nextTimestamp(),
      );
      await _db.db.transaction((Transaction transaction) async {
        await mutation(transaction);
        await transaction.insert(Schema.auditLog, _toRow(entry));
      });
      _lastHash = entry.entryHash;
      _lastTimestamp = entry.timestamp;
      return entry;
    });
  }

  /// Returns matching events, newest first.
  Future<List<AuditEntry>> findAll({
    AuditEventType? eventType,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    if (limit != null && limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];
    if (eventType != null) {
      whereClauses.add('${Schema.eventType} = ?');
      whereArgs.add(eventType.value);
    }
    if (from != null) {
      whereClauses.add('${Schema.timestamp} >= ?');
      whereArgs.add(from.toUtc().toIso8601String());
    }
    if (to != null) {
      whereClauses.add('${Schema.timestamp} <= ?');
      whereArgs.add(to.toUtc().toIso8601String());
    }
    final rows = await _db.db.query(
      Schema.auditLog,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '${Schema.timestamp} DESC, ${Schema.id} DESC',
      limit: limit,
    );
    return rows.map(_entryFromRow).toList(growable: false);
  }

  /// Recomputes hashes and links in timestamp order.
  ///
  /// A non-genesis initial link is accepted only when a retained purge event
  /// authenticates that hash as the retention boundary.
  Future<VerificationResult> verifyChain() async {
    final rows = await _db.db.query(
      Schema.auditLog,
      orderBy: '${Schema.timestamp} ASC, ${Schema.id} ASC',
    );
    if (rows.isEmpty) {
      return const VerificationResult.valid(entryCount: 0);
    }
    final entries = <AuditEntry>[];
    for (var index = 0; index < rows.length; index++) {
      final entry = _tryEntryFromRow(rows[index]);
      if (entry == null) {
        return VerificationResult.broken(
          brokenAt: index,
          reason: 'Invalid audit entry at index $index',
        );
      }
      entries.add(entry);
    }

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (!_hashPattern.hasMatch(entry.prevHash) ||
          !_hashPattern.hasMatch(entry.entryHash)) {
        return VerificationResult.broken(
          brokenAt: index,
          reason: 'Invalid audit hash at index $index',
        );
      }
      final expectedHash = await HashChain.computeEntryHash(
        prevHash: entry.prevHash,
        timestamp: entry.timestamp,
        eventType: entry.eventType,
        entityType: entry.entityType,
        entityId: entry.entityId,
        metadata: entry.metadata,
      );
      if (entry.entryHash != expectedHash) {
        return VerificationResult.broken(
          brokenAt: index,
          reason: 'Entry hash mismatch at index $index',
        );
      }
      final isPurgeBoundary =
          entry.eventType == AuditEventType.purge &&
          entry.metadata?['purged_through_hash'] == entry.prevHash;
      if (index > 0 &&
          entry.prevHash != entries[index - 1].entryHash &&
          !isPurgeBoundary) {
        return VerificationResult.broken(
          brokenAt: index,
          reason: 'Chain link broken at index $index',
        );
      }
      if (index == 0 &&
          entry.prevHash != HashChain.genesisHash &&
          !(entry.eventType == AuditEventType.purge &&
              entry.metadata?['purged_through_hash'] == entry.prevHash) &&
          !_hasRetentionAnchor(entries, entry.prevHash)) {
        return const VerificationResult.broken(
          brokenAt: 0,
          reason: 'Unexpected initial chain anchor',
        );
      }
    }
    return VerificationResult.valid(entryCount: entries.length);
  }

  /// Deletes entries older than [duration] and appends a purge anchor.
  ///
  /// The anchor points to the newest removed hash. The retention marker lets
  /// verification recognize this expected boundary rather than treating it as
  /// arbitrary tampering; entries appended afterward continue from the purge
  /// entry's hash.
  /// The append-only triggers are temporarily dropped only for this operation.
  Future<int> purgeOlderThan({Duration? duration}) {
    final effectiveDuration = duration ?? retention;
    if (effectiveDuration <= Duration.zero) {
      throw ArgumentError.value(
        effectiveDuration,
        'duration',
        'Must be positive',
      );
    }
    return _serialize(() async {
      await _initializeIfNeeded();
      final cutoff = DateTime.now()
          .toUtc()
          .subtract(effectiveDuration)
          .toIso8601String();
      final candidates = await _db.db.query(
        Schema.auditLog,
        columns: <String>[Schema.entryHash],
        where: '${Schema.timestamp} < ?',
        whereArgs: <Object?>[cutoff],
        orderBy: '${Schema.timestamp} DESC, ${Schema.id} DESC',
        limit: 1,
      );
      if (candidates.isEmpty) {
        return 0;
      }
      final anchorValue = candidates.single[Schema.entryHash];
      if (anchorValue is! String) {
        throw StateError('Stored audit hash is invalid');
      }

      var deletedCount = 0;
      AuditEntry? purgeEntry;
      await _db.withTriggersDropped(() async {
        await _db.db.transaction((Transaction transaction) async {
          deletedCount = await transaction.delete(
            Schema.auditLog,
            where: '${Schema.timestamp} < ?',
            whereArgs: <Object?>[cutoff],
          );
          if (deletedCount > 0) {
            purgeEntry = await _createEntry(
              prevHash: anchorValue,
              eventType: AuditEventType.purge,
              metadata: <String, Object?>{
                'count': deletedCount,
                'purged_through_hash': anchorValue,
              },
              timestamp: _nextTimestamp(),
            );
            await transaction.insert(Schema.auditLog, _toRow(purgeEntry!));
          }
        });
      });
      if (purgeEntry != null) {
        _lastHash = purgeEntry!.entryHash;
        _lastTimestamp = purgeEntry!.timestamp;
      }
      return deletedCount;
    });
  }

  /// Returns the number of persisted audit entries.
  Future<int> count() async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${Schema.auditLog}',
    );
    final value = rows.single['count'];
    if (value is int) {
      return value;
    }
    throw StateError('Audit entry count is invalid');
  }

  /// Returns the newest persisted entry, or null when the log is empty.
  Future<AuditEntry?> findLast() async {
    final rows = await _db.db.query(
      Schema.auditLog,
      orderBy: '${Schema.timestamp} DESC, ${Schema.id} DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _entryFromRow(rows.single);
  }

  Future<void> _initializeIfNeeded() async {
    if (_initialized) {
      return;
    }
    final rows = await _db.db.query(
      Schema.auditLog,
      columns: <String>[Schema.entryHash, Schema.timestamp],
      orderBy: '${Schema.timestamp} DESC, ${Schema.id} DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      _lastHash = HashChain.genesisHash;
      _lastTimestamp = null;
    } else {
      final value = rows.single[Schema.entryHash];
      final timestampValue = rows.single[Schema.timestamp];
      final timestamp = timestampValue is String
          ? DateTime.tryParse(timestampValue)
          : null;
      if (value is! String || timestamp == null || !timestamp.isUtc) {
        throw StateError('Stored audit hash is invalid');
      }
      _lastHash = value;
      _lastTimestamp = timestamp;
    }
    _initialized = true;
  }

  DateTime _nextTimestamp() {
    final now = DateTime.now().toUtc();
    final previous = _lastTimestamp;
    if (previous == null || now.isAfter(previous)) {
      return now;
    }
    return previous.add(const Duration(microseconds: 1));
  }

  bool _hasRetentionAnchor(List<AuditEntry> entries, String previousHash) {
    return entries.any(
      (AuditEntry entry) =>
          entry.eventType == AuditEventType.purge &&
          entry.metadata?['purged_through_hash'] == previousHash,
    );
  }

  Future<AuditEntry> _createEntry({
    required String prevHash,
    required AuditEventType eventType,
    required DateTime timestamp,
    String? entityType,
    String? entityId,
    Map<String, Object?>? metadata,
  }) async {
    final id = _uuid.v4();
    final entryHash = await HashChain.computeEntryHash(
      prevHash: prevHash,
      timestamp: timestamp,
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
    return AuditEntry(
      id: id,
      timestamp: timestamp,
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
      prevHash: prevHash,
      entryHash: entryHash,
    );
  }

  Map<String, Object?> _toRow(AuditEntry entry) {
    return <String, Object?>{
      Schema.id: entry.id,
      Schema.timestamp: entry.timestamp.toUtc().toIso8601String(),
      Schema.eventType: entry.eventType.value,
      'entity_type': entry.entityType,
      'entity_id': entry.entityId,
      Schema.metadata: entry.metadata == null
          ? null
          : jsonEncode(entry.metadata),
      Schema.prevHash: entry.prevHash,
      Schema.entryHash: entry.entryHash,
    };
  }

  AuditEntry _entryFromRow(Map<String, Object?> row) {
    final entry = _tryEntryFromRow(row);
    if (entry == null) {
      throw StateError('Stored audit entry is invalid');
    }
    return entry;
  }

  AuditEntry? _tryEntryFromRow(Map<String, Object?> row) {
    final id = row[Schema.id];
    final timestampValue = row[Schema.timestamp];
    final eventTypeValue = row[Schema.eventType];
    final entityTypeValue = row['entity_type'];
    final entityIdValue = row['entity_id'];
    final prevHash = row[Schema.prevHash];
    final entryHash = row[Schema.entryHash];
    if (id is! String ||
        !_uuidV4Pattern.hasMatch(id) ||
        timestampValue is! String ||
        eventTypeValue is! String ||
        entityTypeValue != null && entityTypeValue is! String ||
        entityIdValue != null && entityIdValue is! String ||
        prevHash is! String ||
        !_hashPattern.hasMatch(prevHash) ||
        entryHash is! String ||
        !_hashPattern.hasMatch(entryHash)) {
      return null;
    }
    final timestamp = DateTime.tryParse(timestampValue);
    if (timestamp == null || !timestamp.isUtc) {
      return null;
    }
    AuditEventType? eventType;
    for (final candidate in AuditEventType.values) {
      if (candidate.value == eventTypeValue) {
        eventType = candidate;
        break;
      }
    }
    if (eventType == null) {
      return null;
    }

    final rawMetadata = row[Schema.metadata];
    Map<String, Object?>? metadata;
    if (rawMetadata != null) {
      if (rawMetadata is! String) {
        return null;
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(rawMetadata);
      } on FormatException {
        return null;
      }
      if (decoded is! Map) {
        return null;
      }
      metadata = Map<String, Object?>.from(decoded);
    }
    return AuditEntry(
      id: id,
      timestamp: timestamp,
      eventType: eventType,
      entityType: entityTypeValue as String?,
      entityId: entityIdValue as String?,
      metadata: metadata,
      prevHash: prevHash,
      entryHash: entryHash,
    );
  }

  void _validateMetadata(Map<String, Object?>? metadata) {
    if (metadata == null) {
      return;
    }
    final visited = HashSet<Object>.identity();
    if (_hasForbiddenKey(metadata, visited)) {
      throw ArgumentError('Metadata must not contain PII');
    }
  }

  bool _hasForbiddenKey(Object? value, Set<Object> visited) {
    if (value is Map) {
      if (!visited.add(value)) {
        throw ArgumentError('Metadata must contain acyclic JSON values');
      }
      for (final MapEntry<Object?, Object?> item in value.entries) {
        final key = item.key;
        if (key is! String) {
          throw ArgumentError('Metadata keys must be strings');
        }
        if (forbiddenMetadataKeys.contains(key.toLowerCase()) ||
            _hasForbiddenKey(item.value, visited)) {
          return true;
        }
      }
      visited.remove(value);
    } else if (value is Iterable) {
      if (!visited.add(value)) {
        throw ArgumentError('Metadata must contain acyclic JSON values');
      }
      for (final item in value) {
        if (_hasForbiddenKey(item, visited)) {
          return true;
        }
      }
      visited.remove(value);
    }
    return false;
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final previous = _writeTail;
    final release = Completer<void>();
    _writeTail = release.future;
    return () async {
      await previous;
      try {
        return await operation();
      } finally {
        release.complete();
      }
    }();
  }
}
