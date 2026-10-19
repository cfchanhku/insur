import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/audit/audit_logger.dart';
import 'package:insur/core/audit/hash_chain.dart';

void main() {
  group('AuditLogger — append', () {
    test('first entry uses the genesis hash', () async {
      final logger = AuditLogger();
      final entry = await logger.append(eventType: AuditEventType.appSetup);

      expect(entry.prevHash, HashChain.genesisHash);
    });

    test('second entry links to the first entry hash', () async {
      final logger = AuditLogger();
      final first = await logger.append(eventType: AuditEventType.loginSuccess);
      final second = await logger.append(eventType: AuditEventType.logout);

      expect(second.prevHash, first.entryHash);
    });

    test('returns the appended UTC entry with a UUID v4 id', () async {
      final logger = AuditLogger();
      final entry = await logger.append(
        eventType: AuditEventType.create,
        entityType: 'client',
        entityId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        metadata: <String, Object?>{'count': 1},
      );

      expect(
        entry.id,
        matches(
          RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
          ),
        ),
      );
      expect(entry.timestamp.isUtc, isTrue);
      expect(entry.eventType, AuditEventType.create);
      expect(entry.entityType, 'client');
      expect(entry.metadata, <String, Object?>{'count': 1});
    });
  });

  group('AuditLogger — verify', () {
    test('verifies a fresh chain', () async {
      expect(await AuditLogger().verify(), isTrue);
    });

    test('verifies after multiple appends', () async {
      final logger = AuditLogger();
      await logger.append(eventType: AuditEventType.loginSuccess);
      await logger.append(eventType: AuditEventType.update);
      await logger.append(eventType: AuditEventType.archive);

      expect(await logger.verify(), isTrue);
    });

    test('serializes concurrent appends into one valid chain', () async {
      final logger = AuditLogger();
      await Future.wait(<Future<AuditEntry>>[
        logger.append(eventType: AuditEventType.create),
        logger.append(eventType: AuditEventType.update),
        logger.append(eventType: AuditEventType.archive),
      ]);

      expect(logger.length, 3);
      expect(await logger.verify(), isTrue);
    });
  });

  group('AuditLogger — entries', () {
    test('returns an unmodifiable list', () async {
      final logger = AuditLogger();
      await logger.append(eventType: AuditEventType.loginSuccess);

      expect(() => logger.entries.clear(), throwsUnsupportedError);
    });

    test('returns a stable snapshot when later entries are appended', () async {
      final logger = AuditLogger();
      await logger.append(eventType: AuditEventType.loginSuccess);
      final snapshot = logger.entries;
      await logger.append(eventType: AuditEventType.logout);

      expect(snapshot, hasLength(1));
      expect(logger.entries, hasLength(2));
    });
  });

  group('AuditLogger — length / lastHash', () {
    test('reports genesis hash and zero length when empty', () {
      final logger = AuditLogger();

      expect(logger.length, 0);
      expect(logger.lastHash, HashChain.genesisHash);
    });

    test('updates length and lastHash after appends', () async {
      final logger = AuditLogger();
      final first = await logger.append(eventType: AuditEventType.create);
      expect(logger.length, 1);
      expect(logger.lastHash, first.entryHash);

      final second = await logger.append(eventType: AuditEventType.update);
      expect(logger.length, 2);
      expect(logger.lastHash, second.entryHash);
    });
  });

  group('AuditEntry', () {
    test(
      'round-trips through JSON without exposing metadata in toString',
      () async {
        final logger = AuditLogger();
        final entry = await logger.append(
          eventType: AuditEventType.exportPdf,
          entityType: 'policy',
          entityId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
          metadata: <String, Object?>{'count': 2},
        );
        final restored = AuditEntry.fromJson(entry.toJson());

        expect(restored, entry);
        expect(entry.toJson()['timestamp'], endsWith('Z'));
        expect(
          entry.toString(),
          'AuditEntry(${entry.id}, export_pdf, ${entry.timestamp})',
        );
        expect(entry.toString(), isNot(contains('count')));
        expect(entry.toString(), isNot(contains('policy')));
      },
    );

    test('rejects malformed UUIDs while parsing JSON', () async {
      final entry = await AuditLogger().append(
        eventType: AuditEventType.create,
      );
      final json = entry.toJson()..['id'] = 'invalid';

      expect(() => AuditEntry.fromJson(json), throwsArgumentError);
    });
  });
}
