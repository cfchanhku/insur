import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/schema.dart';

import 'database_test_helper.dart';

void main() {
  group('AppDatabase schema initialization', () {
    test('records schema version one', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.query(Schema.schemaVersion);

      expect(rows, hasLength(1));
      expect(rows.single[Schema.version], Schema.currentSchemaVersion);
      expect(rows.single['applied_at'], isA<String>());
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
      expect(names, contains('idx_audit_timestamp'));
    });

    test('enables foreign key enforcement', () async {
      final database = await createTestDatabase();
      addTearDown(() => tearDownTestDatabase(database));

      final rows = await database.db.rawQuery(
        'PRAGMA foreign_keys',
      );

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
