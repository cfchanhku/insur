/// Persists plans with field-level encryption and transactional audit events.
///
/// Coverage amounts and notes are encrypted because they can expose sensitive
/// financial or personal information. Deleting a plan removes its riders in
/// the same database transaction; only the requested deletion is audited.
library;

import 'package:sqflite_sqlcipher/sqflite.dart' show Transaction;
import 'package:uuid/uuid.dart';

import '../../../features/plans/models/plan.dart';
import '../../../features/plans/models/plan_category.dart';
import '../../audit/audit_event_type.dart';
import '../../security/field_crypto.dart';
import '../database.dart';
import '../schema.dart';
import 'audit_repository.dart';

/// Reads and writes plan records through [AppDatabase].
class PlanRepository {
  /// Creates a repository with its database, field encryption, and audit log.
  PlanRepository({
    required AppDatabase db,
    required FieldCrypto fieldCrypto,
    required AuditRepository audit,
  }) : _db = db,
       _fieldCrypto = fieldCrypto,
       _audit = audit;

  static const String _entityType = 'plan';
  static const Uuid _uuid = Uuid();

  final AppDatabase _db;
  final FieldCrypto _fieldCrypto;
  final AuditRepository _audit;

  /// Inserts or updates [plan] and records the mutation atomically.
  Future<Plan> save(Plan plan) async {
    final id = plan.id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final existing = plan.id == null
        ? <Map<String, Object?>>[]
        : await _db.query(
            Schema.plans,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
            limit: 1,
          );
    if (plan.id != null && existing.isEmpty) {
      throw StateError('Cannot update a plan that does not exist');
    }

    final createdAt = existing.isEmpty
        ? plan.createdAt?.toUtc() ?? now
        : _requiredDate(existing.single, Schema.createdAt);
    final saved = plan.copyWith(id: id, createdAt: createdAt, updatedAt: now);
    final row = <String, Object?>{
      Schema.id: id,
      Schema.policyId: saved.policyId,
      Schema.category: saved.category.value,
      Schema.planName: saved.planName,
      Schema.coverageAmount: await _fieldCrypto.encryptNullable(
        plaintext: saved.coverageAmount?.toString(),
        entityType: _entityType,
        fieldName: Schema.coverageAmount,
        recordId: id,
      ),
      Schema.paymentTerm: saved.paymentTerm,
      Schema.coveragePeriod: saved.coveragePeriod,
      Schema.notes: await _fieldCrypto.encryptNullable(
        plaintext: saved.notes,
        entityType: _entityType,
        fieldName: Schema.notes,
        recordId: id,
      ),
      Schema.createdAt: createdAt.toIso8601String(),
      Schema.updatedAt: now.toIso8601String(),
      Schema.archivedAt: saved.archivedAt?.toUtc().toIso8601String(),
    };

    await _audit.recordMutation(
      eventType: existing.isEmpty
          ? AuditEventType.create
          : AuditEventType.update,
      entityType: _entityType,
      entityId: id,
      metadata: existing.isEmpty
          ? <String, Object?>{Schema.policyId: saved.policyId}
          : null,
      mutation: (Transaction transaction) async {
        if (existing.isEmpty) {
          await transaction.insert(Schema.plans, row);
        } else {
          final changed = await transaction.update(
            Schema.plans,
            row,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
          );
          if (changed != 1) {
            throw StateError('Plan update did not affect exactly one row');
          }
        }
      },
    );
    return saved;
  }

  /// Finds and decrypts a plan by UUID.
  Future<Plan?> findById(String id) async {
    final rows = await _db.query(
      Schema.plans,
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  /// Returns plans for [policyId], excluding archived records by default.
  Future<List<Plan>> findByPolicyId(
    String policyId, {
    bool includeArchived = false,
  }) {
    return _findMany(
      where: includeArchived
          ? '${Schema.policyId} = ?'
          : '${Schema.policyId} = ? AND ${Schema.archivedAt} IS NULL',
      whereArgs: <Object?>[policyId],
    );
  }

  /// Returns plans ordered by creation time, excluding archived records by
  /// default.
  Future<List<Plan>> findAll({bool includeArchived = false}) {
    return _findMany(
      where: includeArchived ? null : '${Schema.archivedAt} IS NULL',
    );
  }

  /// Returns plans in [category], excluding archived records by default.
  Future<List<Plan>> findByCategory(
    PlanCategory category, {
    bool includeArchived = false,
  }) {
    return _findMany(
      where: includeArchived
          ? '${Schema.category} = ?'
          : '${Schema.category} = ? AND ${Schema.archivedAt} IS NULL',
      whereArgs: <Object?>[category.value],
    );
  }

  /// Archives a plan and records the action atomically.
  Future<void> archive(String id) =>
      _changeArchiveState(id, DateTime.now().toUtc(), AuditEventType.archive);

  /// Restores an archived plan and records the action atomically.
  Future<void> restore(String id) =>
      _changeArchiveState(id, null, AuditEventType.restore);

  /// Physically deletes a plan and its riders in one transaction. The
  /// dependent riders do not receive separate audit entries.
  Future<void> delete(String id) async {
    await _audit.recordMutation(
      eventType: AuditEventType.delete,
      entityType: _entityType,
      entityId: id,
      mutation: (Transaction transaction) async {
        await transaction.delete(
          Schema.riders,
          where: '${Schema.planId} = ?',
          whereArgs: <Object?>[id],
        );
        final deleted = await transaction.delete(
          Schema.plans,
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[id],
        );
        if (deleted != 1) {
          throw StateError('Plan delete did not affect exactly one row');
        }
      },
    );
  }

  /// Counts active plans for [policyId].
  Future<int> countByPolicyId(String policyId) async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${Schema.plans} '
      'WHERE ${Schema.policyId} = ? AND ${Schema.archivedAt} IS NULL',
      <Object?>[policyId],
    );
    final count = rows.single['count'];
    if (count is int) {
      return count;
    }
    throw StateError('Plan count is invalid');
  }

  Future<List<Plan>> _findMany({
    required String? where,
    List<Object?>? whereArgs,
  }) async {
    final rows = await _db.query(
      Schema.plans,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${Schema.createdAt} ASC, ${Schema.id} ASC',
    );
    final plans = <Plan>[];
    for (final row in rows) {
      plans.add(await _fromRow(row));
    }
    return plans;
  }

  Future<Plan> _fromRow(Map<String, Object?> row) async {
    final id = _requiredString(row, Schema.id);
    final coverageAmount = await _decryptNullable(
      row,
      Schema.coverageAmount,
      id,
    );
    final parsedCoverage = coverageAmount == null
        ? null
        : double.tryParse(coverageAmount);
    if (coverageAmount != null && parsedCoverage == null) {
      throw StateError('Stored plan coverage amount is invalid');
    }
    return Plan(
      id: id,
      policyId: _requiredString(row, Schema.policyId),
      category: PlanCategory.fromString(_requiredString(row, Schema.category)),
      planName: _requiredString(row, Schema.planName),
      coverageAmount: parsedCoverage,
      paymentTerm: _optionalString(row, Schema.paymentTerm),
      coveragePeriod: _optionalString(row, Schema.coveragePeriod),
      notes: await _decryptNullable(row, Schema.notes, id),
      createdAt: _requiredDate(row, Schema.createdAt),
      updatedAt: _requiredDate(row, Schema.updatedAt),
      archivedAt: _optionalDate(row, Schema.archivedAt),
    );
  }

  Future<String?> _decryptNullable(
    Map<String, Object?> row,
    String column,
    String id,
  ) async {
    final value = row[column];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw StateError('Stored plan field is invalid');
    }
    return _fieldCrypto.decryptNullable(
      ciphertext: value,
      entityType: _entityType,
      fieldName: column,
      recordId: id,
    );
  }

  Future<void> _changeArchiveState(
    String id,
    DateTime? archivedAt,
    AuditEventType eventType,
  ) async {
    await _audit.recordMutation(
      eventType: eventType,
      entityType: _entityType,
      entityId: id,
      mutation: (Transaction transaction) async {
        final changed = await transaction.update(
          Schema.plans,
          <String, Object?>{
            Schema.archivedAt: archivedAt?.toIso8601String(),
            Schema.updatedAt: DateTime.now().toUtc().toIso8601String(),
          },
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[id],
        );
        if (changed != 1) {
          throw StateError('Plan archive operation did not affect one row');
        }
      },
    );
  }
}

String _requiredString(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value is String) {
    return value;
  }
  throw StateError('Stored plan value is invalid');
}

String? _optionalString(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw StateError('Stored plan value is invalid');
}

DateTime _requiredDate(Map<String, Object?> row, String column) {
  final parsed = DateTime.tryParse(_requiredString(row, column));
  if (parsed != null) {
    return parsed.toUtc();
  }
  throw StateError('Stored plan timestamp is invalid');
}

DateTime? _optionalDate(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw StateError('Stored plan timestamp is invalid');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return parsed.toUtc();
  }
  throw StateError('Stored plan timestamp is invalid');
}
