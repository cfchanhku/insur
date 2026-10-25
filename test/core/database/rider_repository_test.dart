import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_entry.dart';
import 'package:insur/core/audit/audit_event_type.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/audit_repository.dart';
import 'package:insur/core/database/repositories/client_repository.dart';
import 'package:insur/core/database/repositories/plan_repository.dart';
import 'package:insur/core/database/repositories/policy_repository.dart';
import 'package:insur/core/database/repositories/rider_repository.dart';
import 'package:insur/core/database/schema.dart';
import 'package:insur/core/security/field_crypto.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';
import 'package:insur/features/plans/models/plan.dart';
import 'package:insur/features/plans/models/plan_category.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';
import 'package:insur/features/riders/models/rider.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late FieldCrypto fieldCrypto;
  late AuditRepository audit;
  late PlanRepository planRepository;
  late RiderRepository repository;
  late String planId;
  late String secondPlanId;

  setUp(() async {
    database = await createTestDatabase();
    addTearDown(() => tearDownTestDatabase(database));
    audit = AuditRepository(db: database);
    fieldCrypto = FieldCrypto(
      fieldKey: Uint8List.fromList(List<int>.filled(32, 0x53)),
    );
    final clients = ClientRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    final policies = PolicyRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    planRepository = PlanRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    repository = RiderRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    final client = await clients.save(_client());
    final policy = await policies.save(_policy(client.id!));
    planId = (await planRepository.save(_plan(policy.id!))).id!;
    secondPlanId = (await planRepository.save(_plan(policy.id!))).id!;
  });

  Future<Map<String, Object?>> rawRider(String id) async {
    final rows = await database.query(
      Schema.riders,
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
    );
    return rows.single;
  }

  Future<AuditEntry?> findRiderAudit(
    String id,
    AuditEventType eventType,
  ) async {
    final entries = await audit.findAll(eventType: eventType);
    for (final entry in entries) {
      if (entry.entityType == 'rider' && entry.entityId == id) {
        return entry;
      }
    }
    return null;
  }

  group('RiderRepository — save (insert)', () {
    test('creates a rider with a new UUID and UTC timestamps', () async {
      final saved = await repository.save(_rider(planId));

      expect(saved.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(saved.createdAt?.isUtc, isTrue);
      expect(saved.updatedAt?.isUtc, isTrue);
    });

    test('encrypts coverage and deductible and emits create audit', () async {
      final saved = await repository.save(_rider(planId));
      final row = await rawRider(saved.id!);
      final encryptedCoverage = row[Schema.coverageAmount]! as String;
      final encryptedDeductible = row[Schema.deductible]! as String;

      expect(encryptedCoverage, isNot('250000.0'));
      expect(encryptedDeductible, isNot('500.0'));
      expect(base64Decode(encryptedCoverage), isA<Uint8List>());
      expect(base64Decode(encryptedDeductible), isA<Uint8List>());
      expect(await findRiderAudit(saved.id!, AuditEventType.create), isNotNull);
    });

    test('preserves null encrypted fields', () async {
      final saved = await repository.save(
        _rider(planId).copyWith(coverageAmount: null, deductible: null),
      );
      final row = await rawRider(saved.id!);

      expect(row[Schema.coverageAmount], isNull);
      expect(row[Schema.deductible], isNull);
    });

    test('rolls back audit when the plan foreign key rejects insert', () async {
      final before = await audit.count();

      await expectLater(
        repository.save(_rider('missing-plan')),
        throwsA(anything),
      );

      expect(await audit.count(), before);
    });
  });

  group('RiderRepository — save (update)', () {
    test(
      'updates an existing rider without changing its ID or creation time',
      () async {
        final inserted = await repository.save(_rider(planId));
        final updated = await repository.save(
          inserted.copyWith(riderName: 'Updated synthetic rider'),
        );

        expect(updated.id, inserted.id);
        expect(updated.riderName, 'Updated synthetic rider');
        expect(updated.createdAt, inserted.createdAt);
        expect(updated.updatedAt!.isAfter(inserted.updatedAt!), isTrue);
      },
    );

    test('emits an update audit entry', () async {
      final inserted = await repository.save(_rider(planId));

      await repository.save(inserted.copyWith(paymentTerm: '15 years'));

      expect(
        await findRiderAudit(inserted.id!, AuditEventType.update),
        isNotNull,
      );
    });

    test('rejects updating a missing rider', () async {
      final rider = _rider(
        planId,
      ).copyWith(id: '123e4567-e89b-42d3-a456-426614174000');

      await expectLater(repository.save(rider), throwsStateError);
    });
  });

  group('RiderRepository — findById', () {
    test('returns the rider with decrypted numeric fields', () async {
      final inserted = await repository.save(_rider(planId));

      expect(await repository.findById(inserted.id!), inserted);
    });

    test('returns null for a missing rider', () async {
      expect(await repository.findById('missing-rider'), isNull);
    });
  });

  group('RiderRepository — findByPlanId', () {
    test('returns riders attached only to the requested plan', () async {
      final first = await repository.save(_rider(planId));
      await repository.save(_rider(secondPlanId));

      expect(await repository.findByPlanId(planId), <Rider>[first]);
    });

    test('excludes archived riders unless requested', () async {
      final rider = await repository.save(_rider(planId));
      await repository.archive(rider.id!);

      expect(await repository.findByPlanId(planId), isEmpty);
      expect(
        await repository.findByPlanId(planId, includeArchived: true),
        hasLength(1),
      );
    });

    test('orders riders by creation time then ID', () async {
      final first = await repository.save(
        _rider(planId, createdAt: DateTime.utc(2020)),
      );
      final second = await repository.save(
        _rider(planId, createdAt: DateTime.utc(2021)),
      );

      expect(await repository.findByPlanId(planId), <Rider>[first, second]);
    });
  });

  group('RiderRepository — findAll', () {
    test('returns active riders across plans', () async {
      final first = await repository.save(_rider(planId));
      final second = await repository.save(_rider(secondPlanId));

      expect(await repository.findAll(), containsAll(<Rider>[first, second]));
    });

    test('can include archived riders', () async {
      final rider = await repository.save(_rider(planId));
      await repository.archive(rider.id!);

      expect(await repository.findAll(), isEmpty);
      expect(await repository.findAll(includeArchived: true), hasLength(1));
    });

    test('findAllArchived returns only archived riders', () async {
      await repository.save(_rider(planId));
      final archived = await repository.save(_rider(planId));
      await repository.archive(archived.id!);

      expect(await repository.findAllArchived(), <Rider>[
        (await repository.findById(archived.id!))!,
      ]);
    });
  });

  group('RiderRepository — archive / restore', () {
    test('archives and records the action', () async {
      final rider = await repository.save(_rider(planId));

      await repository.archive(rider.id!);

      expect((await repository.findById(rider.id!))!.archivedAt?.isUtc, isTrue);
      expect(
        await findRiderAudit(rider.id!, AuditEventType.archive),
        isNotNull,
      );
    });

    test('restores and records the action', () async {
      final rider = await repository.save(_rider(planId));
      await repository.archive(rider.id!);

      await repository.restore(rider.id!);

      expect((await repository.findById(rider.id!))!.archivedAt, isNull);
      expect(
        await findRiderAudit(rider.id!, AuditEventType.restore),
        isNotNull,
      );
    });
  });

  group('RiderRepository — delete', () {
    test('physically deletes a rider and emits a delete event', () async {
      final rider = await repository.save(_rider(planId));

      await repository.delete(rider.id!);

      expect(await repository.findById(rider.id!), isNull);
      expect(await findRiderAudit(rider.id!, AuditEventType.delete), isNotNull);
    });
  });

  group('RiderRepository — field encryption', () {
    test('AAD binds ciphertext to rider type, field, and record ID', () async {
      final saved = await repository.save(_rider(planId));
      final row = await rawRider(saved.id!);
      final encrypted = row[Schema.deductible]! as String;

      expect(
        await fieldCrypto.decrypt(
          ciphertext: encrypted,
          entityType: 'rider',
          fieldName: Schema.deductible,
          recordId: saved.id,
        ),
        '500.0',
      );
      await expectLater(
        fieldCrypto.decrypt(
          ciphertext: encrypted,
          entityType: 'rider',
          fieldName: Schema.coverageAmount,
          recordId: saved.id,
        ),
        throwsA(anything),
      );
    });

    test('create audit metadata contains only its parent plan ID', () async {
      final saved = await repository.save(_rider(planId));
      final entry = await findRiderAudit(saved.id!, AuditEventType.create);

      expect(entry!.metadata, <String, Object?>{Schema.planId: planId});
    });
  });

  group('RiderRepository — countByPlanId', () {
    test('counts active riders and excludes archived records', () async {
      await repository.save(_rider(planId));
      final archived = await repository.save(_rider(planId));
      await repository.archive(archived.id!);

      expect(await repository.countByPlanId(planId), 1);
      await repository.restore(archived.id!);
      expect(await repository.countByPlanId(planId), 2);
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
    createdAt: null,
    updatedAt: null,
  );
}

Plan _plan(String policyId) {
  return Plan(
    policyId: policyId,
    category: PlanCategory.life,
    planName: 'Synthetic plan',
  );
}

Rider _rider(String planId, {DateTime? createdAt}) {
  return Rider(
    planId: planId,
    riderName: 'Synthetic rider',
    coverageAmount: 250000,
    paymentTerm: '10 years',
    deductible: 500,
    waitingPeriod: '30 days',
    createdAt: createdAt,
  );
}
