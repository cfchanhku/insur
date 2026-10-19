/// Represents one event in the tamper-evident audit chain.
///
/// TODO(insur): Persist verified entries using the approved SQLCipher store.
library;

import 'dart:convert';

import 'audit_event_type.dart';

/// One timestamped audit event linked to its predecessor by a SHA-256 hash.
class AuditEntry {
  /// Creates an entry.
  ///
  /// The const constructor asserts basic structure. UTC and full UUID/hash
  /// formatting are checked when parsing and verifying because they cannot be
  /// validated by const-evaluable assertions.
  const AuditEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.entityType,
    required this.entityId,
    required this.metadata,
    required this.prevHash,
    required this.entryHash,
  }) : assert(id.length == 36, 'id must be a UUID v4'),
       assert(prevHash.length == 64, 'prevHash must be a SHA-256 hex digest'),
       assert(entryHash.length == 64, 'entryHash must be a SHA-256 hex digest');

  /// UUID v4 identifying this audit entry.
  final String id;

  /// UTC timestamp at which the event occurred.
  final DateTime timestamp;

  /// Stable event identifier.
  final AuditEventType eventType;

  /// Type of associated entity, when applicable.
  final String? entityType;

  /// Identifier of the associated entity, when applicable.
  final String? entityId;

  /// Never include PII. Only IDs, counts, and non-sensitive diagnostics.
  final Map<String, Object?>? metadata;

  /// Lowercase SHA-256 hash of the preceding entry; zeros for the first entry.
  final String prevHash;

  /// Lowercase SHA-256 hash authenticating this entry and its predecessor.
  final String entryHash;

  /// Serializes the entry with a UTC ISO 8601 timestamp.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'eventType': eventType.value,
      'entityType': entityType,
      'entityId': entityId,
      'metadata': metadata,
      'prevHash': prevHash,
      'entryHash': entryHash,
    };
  }

  /// Parses an entry, rejecting missing fields and invalid identifiers/hashes.
  factory AuditEntry.fromJson(Map<String, Object?> json) {
    if (!json.containsKey('metadata')) {
      throw ArgumentError('Missing required audit field: metadata');
    }
    final rawMetadata = json['metadata'];
    Map<String, Object?>? metadata;
    if (rawMetadata != null) {
      if (rawMetadata is! Map) {
        throw ArgumentError('Invalid audit metadata');
      }
      metadata = <String, Object?>{};
      for (final MapEntry<Object?, Object?> item in rawMetadata.entries) {
        final key = item.key;
        if (key is! String) {
          throw ArgumentError('Audit metadata keys must be strings');
        }
        metadata[key] = item.value;
      }
    }

    final id = _requiredString(json, 'id');
    final prevHash = _requiredString(json, 'prevHash');
    final entryHash = _requiredString(json, 'entryHash');
    if (!_uuidV4Pattern.hasMatch(id)) {
      throw ArgumentError('Invalid audit entry id');
    }
    if (!_hashPattern.hasMatch(prevHash) || !_hashPattern.hasMatch(entryHash)) {
      throw ArgumentError('Invalid audit hash');
    }

    final timestamp = _requiredTimestamp(json, 'timestamp');
    return AuditEntry(
      id: id,
      timestamp: timestamp,
      eventType: AuditEventType.fromString(_requiredString(json, 'eventType')),
      entityType: _requiredNullableString(json, 'entityType'),
      entityId: _requiredNullableString(json, 'entityId'),
      metadata: metadata,
      prevHash: prevHash,
      entryHash: entryHash,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuditEntry &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.eventType == eventType &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        _canonicalJson(other.metadata) == _canonicalJson(metadata) &&
        other.prevHash == prevHash &&
        other.entryHash == entryHash;
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    eventType,
    entityType,
    entityId,
    _canonicalJson(metadata),
    prevHash,
    entryHash,
  );

  @override
  String toString() => 'AuditEntry($id, ${eventType.value}, $timestamp)';
}

final RegExp _uuidV4Pattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
final RegExp _hashPattern = RegExp(r'^[0-9a-f]{64}$');

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw ArgumentError('Missing or invalid audit field: $key');
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw ArgumentError('Invalid audit field: $key');
}

String? _requiredNullableString(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw ArgumentError('Missing required audit field: $key');
  }
  return _optionalString(json, key);
}

DateTime _requiredTimestamp(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final timestamp = DateTime.tryParse(value);
  if (timestamp == null || !timestamp.isUtc) {
    throw ArgumentError('Audit timestamp must be a valid UTC date');
  }
  return timestamp;
}

String _canonicalJson(Map<String, Object?>? value) {
  if (value == null) {
    return '{}';
  }
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
