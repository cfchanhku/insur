import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/migrations.dart';
import 'package:insur/core/database/schema.dart';

import 'database_test_helper.dart';

void main() {
  group('AppDatabase schema initialization', () {
    test('records the latest schema version', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.query(Schema.schemaVersion);

      expect(rows, hasLength(Schema.currentSchemaVersion));
      final currentVersion = rows.singleWhere(
        (Map<String, Object?> row) =>
            row[Schema.version] == Schema.currentSchemaVersion,
      );
      expect(currentVersion['applied_at'], isA<String>());
    });

    test('upgrades version-one database with append-only triggers', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));
      await database.executeRaw('DROP TRIGGER audit_log_no_update');
      await database.executeRaw('DROP TRIGGER audit_log_no_delete');
      await database.db.delete(
        Schema.schemaVersion,
        where: '${Schema.version} = ?',
        whereArgs: <Object?>[2],
      );

      await runMigrations(database.db, 1, 2);

      final triggers = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'trigger'",
      );
      expect(
        triggers.map((Map<String, Object?> row) => row['name']),
        containsAll(<String>{'audit_log_no_update', 'audit_log_no_delete'}),
      );
    });

    test('creates every required table', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = rows
          .map((Map<String, Object?> row) => row['name'])
          .whereType<String>()
          .toSet();

      expect(
        names,
        containsAll(<String>{
          Schema.clients,
          Schema.policies,
          Schema.plans,
          Schema.riders,
          Schema.auditLog,
          Schema.schemaVersion,
          Schema.appConfig,
        }),
      );
    });

    test('adds the encrypted plan deductible column', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final columns = await database.db.rawQuery(
        'PRAGMA table_info(${Schema.plans})',
      );

      expect(
        columns.map((Map<String, Object?> column) => column['name']),
        contains(Schema.deductible),
      );
    });

    test(
      'upgrades version three plans without assigning an insured client',
      () async {
        final database = await createTestDatabase();
        addTearDown(() => tearDownTestDatabase(database));
        const timestamp = '2026-01-01T00:00:00.000Z';
        await database.db.insert(Schema.clients, <String, Object?>{
          Schema.id: 'synthetic-holder',
          Schema.role: 'holder',
          Schema.name: 'Synthetic holder',
          Schema.gender: 'other',
          Schema.dob: '1980-01-01T00:00:00.000Z',
          Schema.createdAt: timestamp,
          Schema.updatedAt: timestamp,
        });
        await database.db.insert(Schema.policies, <String, Object?>{
          Schema.id: 'synthetic-policy',
          Schema.clientId: 'synthetic-holder',
          Schema.policyNo: 'SYNTHETIC-POLICY',
          Schema.company: 'Synthetic insurer',
          Schema.effectiveDate: timestamp,
          Schema.firstPremiumDate: timestamp,
          Schema.currency: 'USD',
          Schema.status: 'active',
          Schema.createdAt: timestamp,
          Schema.updatedAt: timestamp,
        });
        await database.db.insert(Schema.plans, <String, Object?>{
          Schema.id: 'synthetic-plan',
          Schema.policyId: 'synthetic-policy',
          Schema.category: 'life',
          Schema.planName: 'Synthetic plan',
          Schema.createdAt: timestamp,
          Schema.updatedAt: timestamp,
        });

        await database.executeRaw('DROP INDEX idx_plans_insured');
        await database.executeRaw(
          'ALTER TABLE ${Schema.plans} DROP COLUMN ${Schema.insuredId}',
        );
        await database.db.delete(
          Schema.schemaVersion,
          where: '${Schema.version} = ?',
          whereArgs: <Object?>[4],
        );

        await runMigrations(database.db, 3, 4);

        final plan = await database.db.query(
          Schema.plans,
          where: '${Schema.id} = ?',
          whereArgs: <Object?>['synthetic-plan'],
        );
        expect(plan.single[Schema.insuredId], isNull);
        final foreignKeys = await database.db.rawQuery(
          'PRAGMA foreign_key_list(${Schema.plans})',
        );
        expect(
          foreignKeys.any(
            (Map<String, Object?> row) =>
                row['from'] == Schema.insuredId &&
                row['table'] == Schema.clients &&
                row['on_delete'] == 'SET NULL',
          ),
          isTrue,
        );
      },
    );

    test('creates required indexes', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      final names = rows
          .map((Map<String, Object?> row) => row['name'])
          .whereType<String>()
          .toSet();

      expect(names, contains('idx_clients_role'));
      expect(names, contains('idx_policies_client'));
      expect(names, contains('idx_plans_insured'));
      expect(names, contains('idx_audit_timestamp'));
    });

    test('creates append-only audit triggers', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'trigger'",
      );
      final names = rows
          .map((Map<String, Object?> row) => row['name'])
          .whereType<String>()
          .toSet();

      expect(
        names,
        containsAll(<String>{'audit_log_no_update', 'audit_log_no_delete'}),
      );
    });

    test('enables foreign key enforcement', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.db.rawQuery('PRAGMA foreign_keys');

      expect(rows.single.values.single, 1);
    });

    test('rejects opening with a key of the wrong length', () {
      expect(
        () => AppDatabase.openInMemory(dbKey: Uint8List(16)),
        throwsArgumentError,
      );
    });
  });
}
