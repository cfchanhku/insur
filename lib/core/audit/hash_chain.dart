/// Computes and verifies the SHA-256 links between audit entries.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'audit_entry.dart';
import 'audit_event_type.dart';

/// Hash-chain primitives for tamper-evident audit entries.
class HashChain {
  const HashChain._();

  /// Previous hash used by the first entry in a chain.
  static const String genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  static final RegExp _hashPattern = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// Computes the lowercase SHA-256 hash of an audit entry payload.
  ///
  /// Metadata keys are sorted recursively before encoding so identical
  /// entries produce the same bytes regardless of map insertion order.
  static Future<String> computeEntryHash({
    required String prevHash,
    required DateTime timestamp,
    required AuditEventType eventType,
    String? entityType,
    String? entityId,
    Map<String, Object?>? metadata,
  }) async {
    if (!_hashPattern.hasMatch(prevHash)) {
      throw ArgumentError.value(
        prevHash,
        'prevHash',
        'Must be 64 lowercase hex characters',
      );
    }
    if (!timestamp.isUtc) {
      throw ArgumentError.value(timestamp, 'timestamp', 'Must be UTC');
    }
    if (!_isValidJsonValue(metadata ?? <String, Object?>{})) {
      throw ArgumentError.value(
        metadata,
        'metadata',
        'Must contain only acyclic JSON-compatible values',
      );
    }
    final payload = <String>[
      prevHash,
      timestamp.toUtc().toIso8601String(),
      eventType.value,
      entityType ?? '',
      entityId ?? '',
      _canonicalJson(metadata ?? <String, Object?>{}),
    ].join('|');
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Returns whether [entries] form an intact chain.
  ///
  /// Verification is a query, not an assertion: empty chains verify, and
  /// malformed entries or broken links return false rather than propagating
  /// ordinary validation/JSON-encoding errors.
  static Future<bool> verifyChain(List<AuditEntry> entries) async {
    if (entries.isEmpty) {
      return true;
    }
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final expectedPreviousHash = index == 0
          ? genesisHash
          : entries[index - 1].entryHash;
      if (!_uuidV4Pattern.hasMatch(entry.id) ||
          entry.prevHash != expectedPreviousHash ||
          !_hashPattern.hasMatch(entry.entryHash) ||
          !entry.timestamp.isUtc ||
          !_isValidJsonValue(entry.metadata ?? <String, Object?>{})) {
        return false;
      }
      final expectedHash = await computeEntryHash(
        prevHash: entry.prevHash,
        timestamp: entry.timestamp,
        eventType: entry.eventType,
        entityType: entry.entityType,
        entityId: entry.entityId,
        metadata: entry.metadata,
      );
      if (entry.entryHash != expectedHash) {
        return false;
      }
    }
    return true;
  }
}

String _canonicalJson(Map<String, Object?> value) {
  return jsonEncode(_sortJsonValue(value));
}

Object? _sortJsonValue(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    final sorted = <String, Object?>{};
    for (final key in keys) {
      sorted[key] = _sortJsonValue(value[key]);
    }
    return sorted;
  }
  if (value is List<Object?>) {
    return value.map<Object?>(_sortJsonValue).toList();
  }
  return value;
}

bool _isValidJsonValue(Object? value) {
  return _validateJsonValue(value, HashSet<Object>.identity());
}

bool _validateJsonValue(Object? value, Set<Object> ancestors) {
  if (value == null || value is String || value is bool) {
    return true;
  }
  if (value is num) {
    return value.isFinite;
  }
  if (value is List<Object?>) {
    if (!ancestors.add(value)) {
      return false;
    }
    final valid = value.every(
      (Object? item) => _validateJsonValue(item, ancestors),
    );
    ancestors.remove(value);
    return valid;
  }
  if (value is Map<String, Object?>) {
    if (!ancestors.add(value)) {
      return false;
    }
    final valid = value.entries.every(
      (MapEntry<String, Object?> item) =>
          _validateJsonValue(item.value, ancestors),
    );
    ancestors.remove(value);
    return valid;
  }
  return false;
}
