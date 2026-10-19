import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/hash_chain.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/schema.dart';
import 'package:uuid/uuid.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late AuditRepository repository;

  setUp(() async {
    database = await createTestDatabase();
    repository = AuditRepository(db: database);
  });

  tearDown(() async {
    await tearDownTestDatabase(database);
  });

  group('AuditRepository — initialize', () {
    test('empty table initializes to the genesis hash', () async {
      await repository.initialize();

      final entry = await repository.append(
        eventType: AuditEventType.loginFail,
      );

      expect(entry.prevHash, HashChain.genesisHash);
    });

    test('restores the latest hash on a new repository instance', () async {
      final first = await repository.append(
        eventType: AuditEventType.loginSuccess,
      );
      final restarted = AuditRepository(db: database);
      await restarted.initialize();

      final next = await restarted.append(eventType: AuditEventType.logout);

      expect(next.prevHash, first.entryHash);
    });
  });

  group('AuditRepository — append', () {
    test('first entry uses the genesis hash', () async {
      final entry = await repository.append(eventType: AuditEventType.appSetup);

      expect(entry.prevHash, HashChain.genesisHash);
    });

    test('second entry links to the first entry hash', () async {
      final first = await repository.append(
        eventType: AuditEventType.loginSuccess,
      );

      final second = await repository.append(eventType: AuditEventType.logout);

      expect(second.prevHash, first.entryHash);
    });

    test('persists the appended entry', () async {
      await repository.append(eventType: AuditEventType.backup);

      expect(await repository.count(), 1);
    });

    test('rejects metadata with a forbidden PII key without its value', () {
      expect(
        () => repository.append(
          eventType: AuditEventType.create,
          metadata: <String, Object?>{'name': 'Synthetic Person'},
        ),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError error) => error.toString(),
            'message',
            isNot(contains('Synthetic Person')),
          ),
        ),
      );
    });

    test('rejects a forbidden PII key nested in metadata', () {
      expect(
        () => repository.append(
          eventType: AuditEventType.create,
          metadata: <String, Object?>{
            'details': <String, Object?>{'phone': 'Synthetic phone'},
          },
        ),
        throwsArgumentError,
      );
    });

    test('checks forbidden metadata keys without case sensitivity', () {
      expect(
        () => repository.append(
          eventType: AuditEventType.create,
          metadata: <String, Object?>{'Policy_No': 'SYNTHETIC-001'},
        ),
        throwsArgumentError,
      );
    });

    test('accepts safe metadata', () async {
      final entry = await repository.append(
        eventType: AuditEventType.loginFail,
        metadata: <String, Object?>{'attempts': 2, 'method': 'passphrase'},
      );

      expect(entry.metadata, <String, Object?>{
        'attempts': 2,
        'method': 'passphrase',
      });
    });

    test('returns a populated UTC UUID v4 entry', () async {
      final entry = await repository.append(
        eventType: AuditEventType.archive,
        entityType: 'client',
        entityId: 'synthetic-entity-id',
      );

      expect(entry.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(entry.timestamp.isUtc, isTrue);
      expect(entry.eventType, AuditEventType.archive);
      expect(entry.entityType, 'client');
      expect(entry.entityId, 'synthetic-entity-id');
      expect(entry.entryHash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('AuditRepository — findAll', () {
    test('returns all entries', () async {
      await repository.append(eventType: AuditEventType.loginSuccess);
      await repository.append(eventType: AuditEventType.logout);

      expect(await repository.findAll(), hasLength(2));
    });

    test('filters by event type', () async {
      await repository.append(eventType: AuditEventType.loginSuccess);
      await repository.append(eventType: AuditEventType.logout);

      final entries = await repository.findAll(
        eventType: AuditEventType.logout,
      );

      expect(entries, hasLength(1));
      expect(entries.single.eventType, AuditEventType.logout);
    });

    test('filters by inclusive UTC date range', () async {
      final entry = await repository.append(
        eventType: AuditEventType.loginSuccess,
      );

      final entries = await repository.findAll(
        from: entry.timestamp,
        to: entry.timestamp,
      );

      expect(entries, hasLength(1));
      expect(entries.single.id, entry.id);
    });

    test('respects the result limit', () async {
      await repository.append(eventType: AuditEventType.loginSuccess);
      await repository.append(eventType: AuditEventType.logout);

      expect(await repository.findAll(limit: 1), hasLength(1));
    });

    test('orders entries newest first', () async {
      final first = await repository.append(
        eventType: AuditEventType.loginSuccess,
      );
      final second = await repository.append(eventType: AuditEventType.logout);

      final entries = await repository.findAll();

      expect(entries.first.id, second.id);
      expect(entries.last.id, first.id);
    });

    test('rejects a non-positive limit', () {
      expect(() => repository.findAll(limit: 0), throwsArgumentError);
    });
  });

  group('AuditRepository — verifyChain', () {
    test('empty chain is valid', () async {
      final result = await repository.verifyChain();

      expect(result.isValid, isTrue);
      expect(result.entryCount, 0);
    });

    test('single valid entry verifies', () async {
      await repository.append(eventType: AuditEventType.appSetup);

      final result = await repository.verifyChain();

      expect(result.isValid, isTrue);
      expect(result.entryCount, 1);
    });

    test('multiple valid entries verify', () async {
      for (var index = 0; index < 4; index++) {
        await repository.append(eventType: AuditEventType.loginSuccess);
      }

      expect((await repository.verifyChain()).isValid, isTrue);
    });

    test('tampered entry hash returns the first broken index', () async {
      final entry = await repository.append(eventType: AuditEventType.appSetup);
      await database.withTriggersDropped(() async {
        await database.db.update(
          Schema.auditLog,
          <String, Object?>{
            Schema.entryHash: List<String>.filled(64, 'a').join(),
          },
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[entry.id],
        );
      });

      final result = await repository.verifyChain();

      expect(result.isValid, isFalse);
      expect(result.brokenAt, 0);
      expect(result.reason, contains('Entry hash mismatch'));
    });

    test('broken previous-hash link returns the first broken index', () async {
      await repository.append(eventType: AuditEventType.appSetup);
      final second = await repository.append(eventType: AuditEventType.logout);
      await database.withTriggersDropped(() async {
        await database.db.update(
          Schema.auditLog,
          <String, Object?>{
            Schema.prevHash: List<String>.filled(64, 'a').join(),
          },
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[second.id],
        );
      });

      final result = await repository.verifyChain();

      expect(result.isValid, isFalse);
      expect(result.brokenAt, 1);
    });

    test('wrong genesis hash fails verification', () async {
      final entry = await repository.append(eventType: AuditEventType.appSetup);
      final wrongGenesisHash = List<String>.filled(64, 'a').join();
      final updatedHash = await HashChain.computeEntryHash(
        prevHash: wrongGenesisHash,
        timestamp: entry.timestamp,
        eventType: entry.eventType,
      );
      await database.withTriggersDropped(() async {
        await database.db.update(
          Schema.auditLog,
          <String, Object?>{
            Schema.prevHash: wrongGenesisHash,
            Schema.entryHash: updatedHash,
          },
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[entry.id],
        );
      });

      final result = await repository.verifyChain();

      expect(result.isValid, isFalse);
      expect(result.brokenAt, 0);
      expect(result.reason, contains('initial chain anchor'));
    });
  });

  group('AuditRepository — purgeOlderThan', () {
    test(
      'returns zero without a purge entry when no entries are old',
      () async {
        await repository.append(eventType: AuditEventType.loginSuccess);

        expect(
          await repository.purgeOlderThan(duration: const Duration(days: 1)),
          0,
        );
        expect(await repository.count(), 1);
      },
    );

    test('removes old entries and appends a purge anchor', () async {
      final first = await _insertOldEntry(
        database,
        prevHash: HashChain.genesisHash,
        timestamp: DateTime.now().toUtc().subtract(const Duration(days: 4)),
      );
      final second = await _insertOldEntry(
        database,
        prevHash: first.entryHash,
        timestamp: DateTime.now().toUtc().subtract(const Duration(days: 3)),
      );

      final deleted = await repository.purgeOlderThan(
        duration: const Duration(days: 2),
      );

      expect(deleted, 2);
      final purge = await repository.findLast();
      expect(purge?.eventType, AuditEventType.purge);
      expect(purge?.prevHash, second.entryHash);
      expect(purge?.metadata?['count'], 2);
      expect(purge?.metadata?['purged_through_hash'], second.entryHash);
    });

    test(
      'verification accepts a first-row purge anchor after retention',
      () async {
        final old = await _insertOldEntry(
          database,
          prevHash: HashChain.genesisHash,
          timestamp: DateTime.now().toUtc().subtract(const Duration(days: 4)),
        );
        await repository.purgeOlderThan(duration: const Duration(days: 2));

        final result = await repository.verifyChain();

        expect((await repository.findLast())?.prevHash, old.entryHash);
        expect(result.isValid, isTrue);
      },
    );

    test(
      'verifies retained entries after purging an older chain prefix',
      () async {
        final old = await _insertOldEntry(
          database,
          prevHash: HashChain.genesisHash,
          timestamp: DateTime.now().toUtc().subtract(const Duration(days: 4)),
        );
        final retained = await _insertOldEntry(
          database,
          prevHash: old.entryHash,
          timestamp: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        );

        await repository.purgeOlderThan(duration: const Duration(days: 2));

        final purge = (await repository.findLast())!;
        final verification = await repository.verifyChain();
        expect(purge.prevHash, old.entryHash);
        expect(purge.metadata?['purged_through_hash'], old.entryHash);
        expect(retained.entryHash, isNot(old.entryHash));
        expect(verification.isValid, isTrue);
      },
    );

    test('recreates append-only triggers after purge', () async {
      await _insertOldEntry(
        database,
        prevHash: HashChain.genesisHash,
        timestamp: DateTime.now().toUtc().subtract(const Duration(days: 4)),
      );
      await repository.purgeOlderThan(duration: const Duration(days: 2));

      final triggers = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'trigger'",
      );
      expect(
        triggers.map((Map<String, Object?> row) => row['name']),
        containsAll(<String>{'audit_log_no_update', 'audit_log_no_delete'}),
      );
    });

    test('rejects a non-positive retention duration', () {
      expect(
        () => repository.purgeOlderThan(duration: Duration.zero),
        throwsArgumentError,
      );
    });
  });

  group('AuditRepository — count / findLast', () {
    test('count returns the current number of entries', () async {
      await repository.append(eventType: AuditEventType.appSetup);
      await repository.append(eventType: AuditEventType.logout);

      expect(await repository.count(), 2);
    });

    test('findLast returns the newest entry', () async {
      await repository.append(eventType: AuditEventType.appSetup);
      final last = await repository.append(eventType: AuditEventType.logout);

      expect(await repository.findLast(), last);
    });

    test('findLast returns null when empty', () async {
      expect(await repository.findLast(), isNull);
    });
  });

  group('AuditRepository — append-only triggers', () {
    test('blocks direct updates and deletes', () async {
      final entry = await repository.append(eventType: AuditEventType.appSetup);

      await expectLater(
        database.db.update(
          Schema.auditLog,
          <String, Object?>{Schema.eventType: AuditEventType.logout.value},
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[entry.id],
        ),
        throwsA(anything),
      );
      await expectLater(
        database.db.delete(
          Schema.auditLog,
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[entry.id],
        ),
        throwsA(anything),
      );
    });
  });
}

Future<AuditEntry> _insertOldEntry(
  AppDatabase database, {
  required String prevHash,
  required DateTime timestamp,
}) async {
  const uuid = Uuid();
  final id = uuid.v4();
  const eventType = AuditEventType.loginSuccess;
  final entryHash = await HashChain.computeEntryHash(
    prevHash: prevHash,
    timestamp: timestamp,
    eventType: eventType,
  );
  final entry = AuditEntry(
    id: id,
    timestamp: timestamp,
    eventType: eventType,
    entityType: null,
    entityId: null,
    metadata: null,
    prevHash: prevHash,
    entryHash: entryHash,
  );
  await database.db.insert(Schema.auditLog, <String, Object?>{
    Schema.id: id,
    Schema.timestamp: timestamp.toIso8601String(),
    Schema.eventType: eventType.value,
    'entity_type': null,
    'entity_id': null,
    Schema.metadata: null,
    Schema.prevHash: prevHash,
    Schema.entryHash: entryHash,
  });
  return entry;
}
