import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/repositories/client_repository.dart';
import 'package:insur/core/database/repositories/policy_repository.dart';
import 'package:insur/core/database/schema.dart';
import 'package:insur/core/security/field_crypto.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late FieldCrypto fieldCrypto;
  late ClientRepository clientRepository;
  late PolicyRepository repository;
  late AuditRepository audit;
  late String clientId;

  setUp(() async {
    database = await createTestDatabase();
    audit = AuditRepository(db: database);
    fieldCrypto = FieldCrypto(
      fieldKey: Uint8List.fromList(List<int>.filled(32, 0x53)),
    );
    clientRepository = ClientRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    repository = PolicyRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    final client = await clientRepository.save(_client());
    clientId = client.id!;
  });

  tearDown(() async {
    await tearDownTestDatabase(database);
  });

  group('PolicyRepository — save', () {
    test('inserts a new policy with an assigned UUID', () async {
      final saved = await repository.save(_policy(clientId));

      expect(saved.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(saved.createdAt?.isUtc, isTrue);
      expect(saved.updatedAt?.isUtc, isTrue);
    });

    test('updates an existing policy and preserves its ID', () async {
      final inserted = await repository.save(_policy(clientId));
      final updated = await repository.save(
        inserted.copyWith(company: 'Updated Synthetic Insurer'),
      );

      expect(updated.id, inserted.id);
      expect(updated.company, 'Updated Synthetic Insurer');
      expect(updated.createdAt, inserted.createdAt);
    });

    test('preserves stored creation time when updating a policy', () async {
      final inserted = await repository.save(_policy(clientId));
      final updated = await repository.save(
        inserted.copyWith(createdAt: DateTime.utc(2000)),
      );

      expect(updated.createdAt, inserted.createdAt);
    });

    test('rejects a policy with a missing client foreign key', () async {
      await expectLater(
        repository.save(_policy('missing-client')),
        throwsA(anything),
      );
    });
  });

  group('PolicyRepository — find', () {
    test('findById returns a policy with decrypted fields', () async {
      final inserted = await repository.save(_policy(clientId));

      expect(await repository.findById(inserted.id!), inserted);
    });

    test('findById returns null for a missing policy', () async {
      expect(await repository.findById('missing-policy'), isNull);
    });

    test('findByClientId returns policies for the client', () async {
      final inserted = await repository.save(_policy(clientId));

      expect(await repository.findByClientId(clientId), <Policy>[inserted]);
    });

    test('findAll returns active policies', () async {
      final inserted = await repository.save(_policy(clientId));

      expect(await repository.findAll(), <Policy>[inserted]);
    });
  });

  group('PolicyRepository — archive / restore', () {
    test('archive removes the policy from active query results', () async {
      final saved = await repository.save(_policy(clientId));

      await repository.archive(saved.id!);

      expect(await repository.findAll(), isEmpty);
      expect(await repository.findAll(includeArchived: true), hasLength(1));
    });

    test('restore makes the policy active again', () async {
      final saved = await repository.save(_policy(clientId));
      await repository.archive(saved.id!);

      await repository.restore(saved.id!);

      expect(await repository.findAll(), hasLength(1));
    });

    test('delete archives the policy instead of erasing it', () async {
      final saved = await repository.save(_policy(clientId));

      await repository.delete(saved.id!);

      expect(await repository.findById(saved.id!), isNotNull);
      expect((await repository.findById(saved.id!))!.archivedAt, isNotNull);
    });
  });

  group('PolicyRepository — PII encryption', () {
    test('raw policy number is ciphertext, not plaintext', () async {
      final saved = await repository.save(_policy(clientId));
      final rows = await database.query(
        Schema.policies,
        where: '${Schema.id} = ?',
        whereArgs: <Object?>[saved.id],
      );
      final encrypted = rows.single[Schema.policyNo]! as String;

      expect(encrypted, isNot('SYNTHETIC-POLICY-001'));
      expect(base64Decode(encrypted), isA<Uint8List>());
      expect(
        await fieldCrypto.decrypt(
          ciphertext: encrypted,
          entityType: 'policy',
          fieldName: Schema.policyNo,
          recordId: saved.id,
        ),
        'SYNTHETIC-POLICY-001',
      );
    });

    test('nullable notes remain null', () async {
      final saved = await repository.save(
        _policy(clientId).copyWith(notes: null),
      );

      expect((await repository.findById(saved.id!))!.notes, isNull);
    });
  });
}

Client _client() {
  return Client(
    role: ClientRole.holder,
    name: 'Synthetic Client',
    gender: Gender.other,
    dob: DateTime.utc(1980, 1, 2),
    phone: null,
    email: null,
    createdAt: null,
    updatedAt: null,
    archivedAt: null,
  );
}

Policy _policy(String clientId) {
  return Policy(
    clientId: clientId,
    policyNo: 'SYNTHETIC-POLICY-001',
    company: 'Synthetic Insurer',
    effectiveDate: DateTime.utc(2020),
    firstPremiumDate: DateTime.utc(2020, 1, 15),
    currency: 'USD',
    status: PolicyStatus.active,
    notes: 'Synthetic policy note',
    createdAt: null,
    updatedAt: null,
  );
}
