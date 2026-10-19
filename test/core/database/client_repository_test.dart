import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/client_repository.dart';
import 'package:insur/core/database/schema.dart';
import 'package:insur/core/security/field_crypto.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late ClientRepository repository;
  late FieldCrypto fieldCrypto;

  setUp(() async {
    database = await createTestDatabase();
    fieldCrypto = FieldCrypto(
      fieldKey: Uint8List.fromList(List<int>.filled(32, 0x53)),
    );
    repository = ClientRepository(db: database, fieldCrypto: fieldCrypto);
  });

  tearDown(() async {
    await tearDownTestDatabase(database);
  });

  group('ClientRepository — save', () {
    test('inserts a new client and assigns a UUID', () async {
      final saved = await repository.save(_client());

      expect(saved.id, isNotNull);
      expect(saved.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(saved.createdAt?.isUtc, isTrue);
      expect(saved.updatedAt?.isUtc, isTrue);
    });

    test('returns the persisted client values', () async {
      final client = _client();

      final saved = await repository.save(client);

      expect(saved.name, client.name);
      expect(saved.gender, client.gender);
      expect(saved.dob, client.dob);
      expect(saved.phone, client.phone);
      expect(saved.email, client.email);
    });

    test('updates an existing client without changing its ID', () async {
      final inserted = await repository.save(_client());
      final oldUpdatedAt = inserted.updatedAt!;
      final changed = await repository.save(
        inserted.copyWith(name: 'Updated synthetic name'),
      );

      expect(changed.id, inserted.id);
      expect(changed.name, 'Updated synthetic name');
      expect(changed.updatedAt!.isAfter(oldUpdatedAt), isTrue);
      expect(changed.createdAt, inserted.createdAt);
    });

    test('preserves stored creation time when updating a client', () async {
      final inserted = await repository.save(_client());
      final changed = await repository.save(
        inserted.copyWith(createdAt: DateTime.utc(2000)),
      );

      expect(changed.createdAt, inserted.createdAt);
    });

    test('rejects update when the client row does not exist', () async {
      final missing = _client().copyWith(
        id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
      );

      await expectLater(repository.save(missing), throwsStateError);
    });
  });

  group('ClientRepository — findById', () {
    test('returns a decrypted client', () async {
      final inserted = await repository.save(_client());

      final loaded = await repository.findById(inserted.id!);

      expect(loaded, inserted);
    });

    test('returns null for a missing client', () async {
      expect(await repository.findById('missing-id'), isNull);
    });
  });

  group('ClientRepository — findAll', () {
    test('returns active clients only by default', () async {
      final active = await repository.save(_client());
      final archived = await repository.save(
        _client(name: 'Archived synthetic person'),
      );
      await repository.archive(archived.id!);

      expect(await repository.findAll(), <Client>[active]);
    });

    test('includes archived clients when requested', () async {
      final archived = await repository.save(_client());
      await repository.archive(archived.id!);

      expect(await repository.findAll(includeArchived: true), hasLength(1));
    });
  });

  group('ClientRepository — archive / restore', () {
    test('archive sets the UTC archive timestamp', () async {
      final saved = await repository.save(_client());

      await repository.archive(saved.id!);

      final loaded = (await repository.findById(saved.id!))!;
      expect(loaded.archivedAt?.isUtc, isTrue);
    });

    test('restore clears the archive timestamp', () async {
      final saved = await repository.save(_client());
      await repository.archive(saved.id!);

      await repository.restore(saved.id!);

      expect((await repository.findById(saved.id!))!.archivedAt, isNull);
    });

    test('delete archives rather than physically erasing the record', () async {
      final saved = await repository.save(_client());

      await repository.delete(saved.id!);

      expect(await repository.findById(saved.id!), isNotNull);
      expect(
        (await repository.findById(saved.id!))!.archivedAt,
        isNotNull,
      );
    });
  });

  group('ClientRepository — PII encryption', () {
    test('raw name column contains ciphertext, not plaintext', () async {
      final saved = await repository.save(_client());
      final rows = await database.query(
        Schema.clients,
        where: '${Schema.id} = ?',
        whereArgs: <Object?>[saved.id],
      );
      final rawName = rows.single[Schema.name]! as String;

      expect(rawName, isNot('Synthetic Client'));
      expect(base64Decode(rawName), isA<Uint8List>());
      expect(
        await fieldCrypto.decrypt(
          ciphertext: rawName,
          entityType: 'client',
          fieldName: Schema.name,
          recordId: saved.id,
        ),
        'Synthetic Client',
      );
    });

    test('nullable PII is preserved as null', () async {
      final saved = await repository.save(
        _client(phone: null, email: null, notes: null),
      );

      final loaded = (await repository.findById(saved.id!))!;

      expect(loaded.phone, isNull);
      expect(loaded.email, isNull);
      expect(loaded.notes, isNull);
    });
  });
}

Client _client({
  String name = 'Synthetic Client',
  String? phone = '+10000000000',
  String? email = 'client@example.invalid',
  String? notes = 'Synthetic note',
}) {
  return Client(
    role: ClientRole.holder,
    name: name,
    gender: Gender.other,
    dob: DateTime.utc(1980, 1, 2),
    phone: phone,
    email: email,
    notes: notes,
    createdAt: null,
    updatedAt: null,
    archivedAt: null,
  );
}
