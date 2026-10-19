import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/repositories/client_repository.dart';
import 'package:insur/core/security/field_crypto.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late AuditRepository audit;
  late ClientRepository repository;

  setUp(() async {
    database = await createTestDatabase();
    audit = AuditRepository(db: database);
    repository = ClientRepository(
      db: database,
      fieldCrypto: FieldCrypto(
        fieldKey: Uint8List.fromList(List<int>.filled(32, 0x53)),
      ),
      audit: audit,
    );
  });

  tearDown(() async {
    await tearDownTestDatabase(database);
  });

  group('ClientRepository — audit emission', () {
    test('save insert emits CREATE', () async {
      final client = await repository.save(_client());

      final entry = await audit.findLast();
      expect(entry?.eventType, AuditEventType.create);
      expect(entry?.entityType, 'client');
      expect(entry?.entityId, client.id);
    });

    test('save update emits UPDATE', () async {
      final client = await repository.save(_client());

      await repository.save(client.copyWith(name: 'Updated synthetic client'));

      expect((await audit.findLast())?.eventType, AuditEventType.update);
    });

    test('archive emits ARCHIVE', () async {
      final client = await repository.save(_client());

      await repository.archive(client.id!);

      expect((await audit.findLast())?.eventType, AuditEventType.archive);
    });

    test('restore emits RESTORE', () async {
      final client = await repository.save(_client());
      await repository.archive(client.id!);

      await repository.restore(client.id!);

      expect((await audit.findLast())?.eventType, AuditEventType.restore);
    });

    test('delete emits DELETE while retaining the record', () async {
      final client = await repository.save(_client());

      await repository.delete(client.id!);

      expect((await audit.findLast())?.eventType, AuditEventType.delete);
      expect(await repository.findById(client.id!), isNotNull);
    });

    test('mutation entries contain no client PII in metadata', () async {
      final client = await repository.save(_client());
      final entry = (await audit.findLast())!;

      expect(entry.entityId, client.id);
      expect(entry.metadata, isNull);
    });
  });
}

Client _client() {
  return Client(
    role: ClientRole.holder,
    name: 'Synthetic Audit Client',
    gender: Gender.other,
    dob: DateTime.utc(1980, 1, 2),
    phone: '+10000000000',
    email: 'audit@example.invalid',
    notes: 'Synthetic note',
    createdAt: null,
    updatedAt: null,
    archivedAt: null,
  );
}
