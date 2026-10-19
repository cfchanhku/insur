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
  late PlanRepository repository;
  late RiderRepository riderRepository;
  late String firstPolicyId;
  late String secondPolicyId;

  setUp(() async {
    database = await createTestDatabase();
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
    repository = PlanRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    riderRepository = RiderRepository(
      db: database,
      fieldCrypto: fieldCrypto,
      audit: audit,
    );
    final firstClient = await clients.save(_client('Synthetic Client One'));
    final secondClient = await clients.save(_client('Synthetic Client Two'));
    firstPolicyId = (await policies.save(_policy(firstClient.id!))).id!;
    secondPolicyId = (await policies.save(_policy(secondClient.id!))).id!;
  });

  tearDown(() async {
    await tearDownTestDatabase(database);
  });

  Future<Map<String, Object?>> rawPlan(String id) async {
    final rows = await database.query(
      Schema.plans,
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
    );
    return rows.single;
  }

  Future<AuditEntry?> findPlanAudit(String id, AuditEventType eventType) async {
    final entries = await audit.findAll(eventType: eventType);
    for (final entry in entries) {
      if (entry.entityType == 'plan' && entry.entityId == id) {
        return entry;
      }
    }
    return null;
  }

  group('PlanRepository — save (insert)', () {
    test('creates a plan with a new UUID and UTC timestamps', () async {
      final saved = await repository.save(_plan(firstPolicyId));

      expect(saved.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(saved.createdAt?.isUtc, isTrue);
      expect(saved.updatedAt?.isUtc, isTrue);
    });

    test('encrypts sensitive fields and emits a create audit entry', () async {
      final saved = await repository.save(
        _plan(firstPolicyId).copyWith(deductible: 500),
      );
      final row = await rawPlan(saved.id!);
      final encryptedCoverage = row[Schema.coverageAmount]! as String;
      final encryptedDeductible = row[Schema.deductible]! as String;
      final encryptedNotes = row[Schema.notes]! as String;

      expect(encryptedCoverage, isNot('1000000.0'));
      expect(encryptedDeductible, isNot('500.0'));
      expect(encryptedNotes, isNot('Synthetic plan note'));
      expect(base64Decode(encryptedCoverage), isA<Uint8List>());
      expect(base64Decode(encryptedDeductible), isA<Uint8List>());
      expect(base64Decode(encryptedNotes), isA<Uint8List>());
      expect(await findPlanAudit(saved.id!, AuditEventType.create), isNotNull);
    });

    test('preserves null encrypted fields', () async {
      final saved = await repository.save(
        _plan(firstPolicyId).copyWith(coverageAmount: null, notes: null),
      );
      final row = await rawPlan(saved.id!);

      expect(row[Schema.coverageAmount], isNull);
      expect(row[Schema.notes], isNull);
    });

    test(
      'rolls back the audit event when a foreign key rejects insert',
      () async {
        final before = await audit.count();

        await expectLater(
          repository.save(_plan('missing-policy')),
          throwsA(anything),
        );

        expect(await audit.count(), before);
      },
    );
  });

  group('PlanRepository — save (update)', () {
    test(
      'updates an existing plan and preserves its ID and creation time',
      () async {
        final inserted = await repository.save(_plan(firstPolicyId));
        final updated = await repository.save(
          inserted.copyWith(planName: 'Updated synthetic plan'),
        );

        expect(updated.id, inserted.id);
        expect(updated.planName, 'Updated synthetic plan');
        expect(updated.createdAt, inserted.createdAt);
        expect(updated.updatedAt!.isAfter(inserted.updatedAt!), isTrue);
      },
    );

    test('emits an update audit entry', () async {
      final inserted = await repository.save(_plan(firstPolicyId));

      await repository.save(inserted.copyWith(notes: 'Updated note'));

      expect(
        await findPlanAudit(inserted.id!, AuditEventType.update),
        isNotNull,
      );
    });

    test('rejects updating a missing record', () async {
      final plan = _plan(
        firstPolicyId,
      ).copyWith(id: '123e4567-e89b-42d3-a456-426614174000');

      await expectLater(repository.save(plan), throwsStateError);
    });
  });

  group('PlanRepository — findById', () {
    test('returns the plan with decrypted fields', () async {
      final inserted = await repository.save(_plan(firstPolicyId));

      expect(await repository.findById(inserted.id!), inserted);
    });

    test('returns null when the plan does not exist', () async {
      expect(await repository.findById('missing-plan'), isNull);
    });

    test('round-trips an encrypted plan deductible', () async {
      final inserted = await repository.save(
        _plan(firstPolicyId).copyWith(deductible: 500),
      );

      expect((await repository.findById(inserted.id!))?.deductible, 500);
    });
  });

  group('PlanRepository — findByPolicyId', () {
    test('returns plans for only the requested policy', () async {
      final first = await repository.save(_plan(firstPolicyId));
      await repository.save(_plan(secondPolicyId));

      expect(await repository.findByPolicyId(firstPolicyId), <Plan>[first]);
    });

    test('excludes archived plans unless explicitly included', () async {
      final plan = await repository.save(_plan(firstPolicyId));
      await repository.archive(plan.id!);

      expect(await repository.findByPolicyId(firstPolicyId), isEmpty);
      expect(
        await repository.findByPolicyId(firstPolicyId, includeArchived: true),
        hasLength(1),
      );
    });

    test('orders results by creation time then ID', () async {
      final first = await repository.save(
        _plan(firstPolicyId, createdAt: DateTime.utc(2020)),
      );
      final second = await repository.save(
        _plan(firstPolicyId, createdAt: DateTime.utc(2021)),
      );

      expect(await repository.findByPolicyId(firstPolicyId), <Plan>[
        first,
        second,
      ]);
    });
  });

  group('PlanRepository — findAll / findByCategory', () {
    test('findAll returns active plans across policies', () async {
      final first = await repository.save(_plan(firstPolicyId));
      final second = await repository.save(_plan(secondPolicyId));

      expect(await repository.findAll(), containsAll(<Plan>[first, second]));
    });

    test('findAll optionally includes archived plans', () async {
      final plan = await repository.save(_plan(firstPolicyId));
      await repository.archive(plan.id!);

      expect(await repository.findAll(), isEmpty);
      expect(await repository.findAll(includeArchived: true), hasLength(1));
    });

    test('findAllArchived returns only archived plans', () async {
      await repository.save(_plan(firstPolicyId));
      final archived = await repository.save(_plan(firstPolicyId));
      await repository.archive(archived.id!);

      expect(await repository.findAllArchived(), <Plan>[
        (await repository.findById(archived.id!))!,
      ]);
    });

    test('findByCategory filters by the serialized category', () async {
      final life = await repository.save(
        _plan(firstPolicyId, category: PlanCategory.life),
      );
      await repository.save(
        _plan(secondPolicyId, category: PlanCategory.other),
      );

      expect(await repository.findByCategory(PlanCategory.life), <Plan>[life]);
    });

    test('findByCategory can include archived plans', () async {
      final plan = await repository.save(
        _plan(firstPolicyId, category: PlanCategory.life),
      );
      await repository.archive(plan.id!);

      expect(await repository.findByCategory(PlanCategory.life), isEmpty);
      expect(
        await repository.findByCategory(
          PlanCategory.life,
          includeArchived: true,
        ),
        hasLength(1),
      );
    });
  });

  group('PlanRepository — archive / restore', () {
    test('archives with a UTC timestamp and emits an archive event', () async {
      final plan = await repository.save(_plan(firstPolicyId));

      await repository.archive(plan.id!);

      final archived = await repository.findById(plan.id!);
      expect(archived!.archivedAt?.isUtc, isTrue);
      expect(await findPlanAudit(plan.id!, AuditEventType.archive), isNotNull);
    });

    test('restores and emits a restore event', () async {
      final plan = await repository.save(_plan(firstPolicyId));
      await repository.archive(plan.id!);

      await repository.restore(plan.id!);

      expect((await repository.findById(plan.id!))!.archivedAt, isNull);
      expect(await findPlanAudit(plan.id!, AuditEventType.restore), isNotNull);
    });
  });

  group('PlanRepository — delete', () {
    test(
      'physically deletes the plan and emits a delete audit entry',
      () async {
        final plan = await repository.save(_plan(firstPolicyId));

        await repository.delete(plan.id!);

        expect(await repository.findById(plan.id!), isNull);
        expect(await findPlanAudit(plan.id!, AuditEventType.delete), isNotNull);
      },
    );

    test('cascades deletion to riders without a second delete event', () async {
      final plan = await repository.save(_plan(firstPolicyId));
      final rider = await riderRepository.save(
        Rider(planId: plan.id!, riderName: 'Synthetic rider'),
      );

      await repository.delete(plan.id!);

      expect(await riderRepository.findById(rider.id!), isNull);
      final riderDeleteEvents = (await audit.findAll()).where(
        (entry) =>
            entry.entityType == 'rider' &&
            entry.entityId == rider.id &&
            entry.eventType == AuditEventType.delete,
      );
      expect(riderDeleteEvents, isEmpty);
    });
  });

  group('PlanRepository — PII encryption', () {
    test('ciphertext is bound to plan, field, and row ID', () async {
      final saved = await repository.save(_plan(firstPolicyId));
      final row = await rawPlan(saved.id!);
      final encrypted = row[Schema.coverageAmount]! as String;

      expect(
        await fieldCrypto.decrypt(
          ciphertext: encrypted,
          entityType: 'plan',
          fieldName: Schema.coverageAmount,
          recordId: saved.id,
        ),
        '1000000.0',
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

    test('audit metadata contains only the parent policy ID', () async {
      final saved = await repository.save(_plan(firstPolicyId));
      final entry = await findPlanAudit(saved.id!, AuditEventType.create);

      expect(entry!.metadata, <String, Object?>{
        Schema.policyId: firstPolicyId,
      });
    });
  });

  group('PlanRepository — countByPolicyId', () {
    test('counts active plans but excludes archived plans', () async {
      final active = await repository.save(_plan(firstPolicyId));
      final archived = await repository.save(_plan(firstPolicyId));
      await repository.archive(archived.id!);

      expect(await repository.countByPolicyId(firstPolicyId), 1);
      await repository.restore(archived.id!);
      expect(await repository.countByPolicyId(firstPolicyId), 2);
      expect(active.id, isNot(archived.id));
    });
  });
}

Client _client(String name) {
  return Client(
    role: ClientRole.holder,
    name: name,
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

Plan _plan(
  String policyId, {
  PlanCategory category = PlanCategory.ci,
  DateTime? createdAt,
}) {
  return Plan(
    policyId: policyId,
    category: category,
    planName: 'Synthetic plan',
    coverageAmount: 1000000,
    paymentTerm: '20 years',
    coveragePeriod: 'To age 80',
    notes: 'Synthetic plan note',
    createdAt: createdAt,
  );
}
