/// Records and verifies tamper-evident audit events in memory.
///
/// This implementation is an in-memory foundation; Phase 4 will persist the
/// same append/verify interface to SQLCipher. Retention and metadata privacy
/// remain the caller's responsibility until persistence is implemented.
library;

import 'dart:async';

import 'package:uuid/uuid.dart';

import 'audit_entry.dart';
import 'audit_event_type.dart';
import 'hash_chain.dart';

/// Maintains an append-only in-memory audit hash chain.
class AuditLogger {
  final List<AuditEntry> _entries = <AuditEntry>[];
  String _lastHash = HashChain.genesisHash;
  Future<void> _appendQueue = Future<void>.value();

  /// Appends an event and returns the hash-chained entry.
  ///
  /// Callers must supply only non-PII metadata. Persistence to SQLCipher and
  /// retention enforcement will be added in Phase 4 without changing this API.
  Future<AuditEntry> append({
    required AuditEventType eventType,
    String? entityType,
    String? entityId,
    Map<String, Object?>? metadata,
  }) async {
    final completed = Completer<void>();
    final previous = _appendQueue;
    _appendQueue = completed.future;
    await previous;
    try {
      final timestamp = DateTime.now().toUtc();
      final prevHash = _lastHash;
      final entryHash = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: eventType,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
      );
      final entry = AuditEntry(
        id: const Uuid().v4(),
        timestamp: timestamp,
        eventType: eventType,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
        prevHash: prevHash,
        entryHash: entryHash,
      );
      _entries.add(entry);
      _lastHash = entryHash;
      return entry;
    } finally {
      completed.complete();
    }
  }

  /// Returns an unmodifiable snapshot of all entries in append order.
  List<AuditEntry> get entries => List<AuditEntry>.unmodifiable(_entries);

  /// Verifies the complete in-memory chain.
  Future<bool> verify() => HashChain.verifyChain(_entries);

  /// Number of entries currently in memory.
  int get length => _entries.length;

  /// Hash of the newest entry, or the genesis hash when empty.
  String get lastHash => _lastHash;
}
