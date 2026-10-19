import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/repositories/client_repository.dart';
import 'package:insur/core/database/repositories/policy_repository.dart';
import 'package:insur/core/security/field_crypto.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late AuditRepository audit;
  late ClientRepository clientRepository;
  late PolicyRepository repository;
  late String clientId;

  setUp(() async {
    database = await createTestDatabase();
    audit = AuditRepository(db: database);
    final fieldCrypto = FieldCrypto(
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
    clientId = (await clientRepository.save(_createClient())).id!;
  });

  tearDown(() async {
    await tearDownTestDatabase(database);
  });

  group('PolicyRepository — audit emission', () {
    test('save insert emits CREATE', () async {
      final policy = await repository.save(_createPolicy(clientId));

      final entry = await audit.findLast();
      expect(entry?.eventType, AuditEventType.create);
      expect(entry?.entityType, 'policy');
      expect(entry?.entityId, policy.id);
    });

    test('save update emits UPDATE', () async {
      final policy = await repository.save(_createPolicy(clientId));

      await repository.save(
        policy.copyWith(company: 'Updated Synthetic Insurer'),
      );

      expect((await audit.findLast())?.eventType, AuditEventType.update);
    });

    test('archive emits ARCHIVE', () async {
      final policy = await repository.save(_createPolicy(clientId));

      await repository.archive(policy.id!);

      expect((await audit.findLast())?.eventType, AuditEventType.archive);
    });

    test('restore emits RESTORE', () async {
      final policy = await repository.save(_createPolicy(clientId));
      await repository.archive(policy.id!);

      await repository.restore(policy.id!);

      expect((await audit.findLast())?.eventType, AuditEventType.restore);
    });

    test('delete emits DELETE and removes the record', () async {
      final policy = await repository.save(_createPolicy(clientId));

      await repository.delete(policy.id!);

      expect((await audit.findLast())?.eventType, AuditEventType.delete);
      expect(await repository.findById(policy.id!), isNull);
    });

    test('mutation entries contain no policy PII in metadata', () async {
      final policy = await repository.save(_createPolicy(clientId));
      final entry = (await audit.findLast())!;

      expect(entry.entityId, policy.id);
      expect(entry.metadata, isNull);
    });
  });
}

Client _createClient() {
  return Client(
    role: ClientRole.holder,
    name: 'Synthetic Policy Owner',
    gender: Gender.other,
    dob: DateTime.utc(1980, 1, 2),
    phone: null,
    email: null,
    createdAt: null,
    updatedAt: null,
    archivedAt: null,
  );
}

Policy _createPolicy(String clientId) {
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
