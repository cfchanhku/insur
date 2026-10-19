import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/hash_chain.dart';

void main() {
  final timestamp = DateTime.utc(2026, 1, 2, 3, 4, 5);
  const entityId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
  const prevHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  group('genesisHash', () {
    test('contains exactly 64 zero characters', () {
      expect(HashChain.genesisHash, List<String>.filled(64, '0').join());
      expect(HashChain.genesisHash, hasLength(64));
    });
  });

  group('computeEntryHash — validation', () {
    test('rejects a malformed previous hash', () {
      expect(
        () => HashChain.computeEntryHash(
          prevHash: 'not-a-hash',
          timestamp: timestamp,
          eventType: AuditEventType.create,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-UTC timestamp', () {
      expect(
        () => HashChain.computeEntryHash(
          prevHash: prevHash,
          timestamp: DateTime(2026, 1, 2),
          eventType: AuditEventType.create,
        ),
        throwsArgumentError,
      );
    });
  });

  group('computeEntryHash — determinism', () {
    test('returns the same hash for identical inputs', () async {
      final first = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'source': 'test', 'count': 2},
      );
      final second = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'source': 'test', 'count': 2},
      );

      expect(second, first);
    });
  });

  group('computeEntryHash — sensitivity', () {
    late String baseHash;

    setUp(() async {
      baseHash = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'count': 1},
      );
    });

    test('changes when the previous hash changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash:
            '1000000000000000000000000000000000000000000000000000000000000000',
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'count': 1},
      );

      expect(changed, isNot(baseHash));
    });

    test('changes when the timestamp changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp.add(const Duration(seconds: 1)),
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'count': 1},
      );

      expect(changed, isNot(baseHash));
    });

    test('changes when the event type changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.update,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'count': 1},
      );

      expect(changed, isNot(baseHash));
    });

    test('changes when the entity type changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'policy',
        entityId: entityId,
        metadata: <String, Object?>{'count': 1},
      );

      expect(changed, isNot(baseHash));
    });

    test('changes when the entity id changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: 'b1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        metadata: <String, Object?>{'count': 1},
      );

      expect(changed, isNot(baseHash));
    });

    test('changes when a metadata key changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'total': 1},
      );

      expect(changed, isNot(baseHash));
    });

    test('changes when a metadata value changes', () async {
      final changed = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'count': 2},
      );

      expect(changed, isNot(baseHash));
    });
  });

  group('computeEntryHash — canonical JSON', () {
    test('metadata key insertion order does not change the hash', () async {
      final first = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        metadata: <String, Object?>{
          'z': 2,
          'nested': <String, Object?>{'y': 1, 'x': 0},
          'a': 3,
        },
      );
      final second = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        metadata: <String, Object?>{
          'a': 3,
          'nested': <String, Object?>{'x': 0, 'y': 1},
          'z': 2,
        },
      );

      expect(second, first);
    });
  });

  group('computeEntryHash — known output', () {
    test('locks the exact audit payload serialization format', () async {
      // Changing this payload format requires updating this vector and
      // invalidating logs written with the previous format.
      final hash = await HashChain.computeEntryHash(
        prevHash: prevHash,
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: entityId,
        metadata: <String, Object?>{'source': 'unit_test', 'count': 2},
      );

      expect(
        hash,
        '3af463e809d364fa8664d684dd3da664a948f88b787c6de519d44d4b5a909f80',
      );
    });
  });

  group('verifyChain', () {
    test('accepts an empty chain', () async {
      expect(await HashChain.verifyChain(<AuditEntry>[]), isTrue);
    });

    test('accepts a single valid entry', () async {
      final entry = await _createEntry(
        prevHash: HashChain.genesisHash,
        timestamp: timestamp,
      );

      expect(await HashChain.verifyChain(<AuditEntry>[entry]), isTrue);
    });

    test('rejects an entry with a tampered entry hash', () async {
      final valid = await _createEntry(
        prevHash: HashChain.genesisHash,
        timestamp: timestamp,
      );
      final tampered = AuditEntry(
        id: valid.id,
        timestamp: valid.timestamp,
        eventType: valid.eventType,
        entityType: valid.entityType,
        entityId: valid.entityId,
        metadata: valid.metadata,
        prevHash: valid.prevHash,
        entryHash: List<String>.filled(64, '1').join(),
      );

      expect(await HashChain.verifyChain(<AuditEntry>[tampered]), isFalse);
    });

    test('rejects a broken previous-hash link', () async {
      final first = await _createEntry(
        prevHash: HashChain.genesisHash,
        timestamp: timestamp,
      );
      final second = await _createEntry(
        prevHash: List<String>.filled(64, '1').join(),
        timestamp: timestamp.add(const Duration(seconds: 1)),
      );

      expect(await HashChain.verifyChain(<AuditEntry>[first, second]), isFalse);
    });

    test('rejects an incorrect genesis hash', () async {
      final entry = await _createEntry(
        prevHash: List<String>.filled(64, '1').join(),
        timestamp: timestamp,
      );

      expect(await HashChain.verifyChain(<AuditEntry>[entry]), isFalse);
    });

    test('returns false for a non-UTC entry without throwing', () async {
      final entry = AuditEntry(
        id: '123e4567-e89b-42d3-a456-426614174000',
        timestamp: DateTime(2026, 1, 2),
        eventType: AuditEventType.create,
        entityType: null,
        entityId: null,
        metadata: null,
        prevHash: HashChain.genesisHash,
        entryHash: List<String>.filled(64, '0').join(),
      );

      expect(await HashChain.verifyChain(<AuditEntry>[entry]), isFalse);
    });

    test('returns false for cyclic metadata without throwing', () async {
      final cyclicMetadata = <String, Object?>{};
      cyclicMetadata['cycle'] = cyclicMetadata;
      final entry = AuditEntry(
        id: '123e4567-e89b-42d3-a456-426614174000',
        timestamp: timestamp,
        eventType: AuditEventType.create,
        entityType: null,
        entityId: null,
        metadata: cyclicMetadata,
        prevHash: HashChain.genesisHash,
        entryHash: List<String>.filled(64, '0').join(),
      );

      expect(await HashChain.verifyChain(<AuditEntry>[entry]), isFalse);
    });
  });
}

Future<AuditEntry> _createEntry({
  required String prevHash,
  required DateTime timestamp,
}) async {
  const eventType = AuditEventType.create;
  const id = '123e4567-e89b-42d3-a456-426614174000';
  final entryHash = await HashChain.computeEntryHash(
    prevHash: prevHash,
    timestamp: timestamp,
    eventType: eventType,
    entityType: 'client',
    entityId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    metadata: <String, Object?>{'count': 1},
  );

  return AuditEntry(
    id: id,
    timestamp: timestamp,
    eventType: eventType,
    entityType: 'client',
    entityId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    metadata: <String, Object?>{'count': 1},
    prevHash: prevHash,
    entryHash: entryHash,
  );
}
