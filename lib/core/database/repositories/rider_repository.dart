/// Persists riders with field-level encryption and transactional audit events.
///
/// Coverage amounts and deductibles are encrypted because they expose
/// sensitive financial details. Deleting a plan cascades to its riders at the
/// database level; only the requested top-level deletion is separately
/// audited.
library;

import 'package:sqflite_sqlcipher/sqflite.dart' show Transaction;
import 'package:uuid/uuid.dart';

import '../../../features/riders/models/rider.dart';
import '../../audit/audit_event_type.dart';
import '../../security/field_crypto.dart';
import '../database.dart';
import '../schema.dart';
import 'audit_repository.dart';

/// Reads and writes rider records through [AppDatabase].
class RiderRepository {
  /// Creates a repository with its database, field encryption, and audit log.
  RiderRepository({
    required AppDatabase db,
    required FieldCrypto fieldCrypto,
    required AuditRepository audit,
  }) : _db = db,
       _fieldCrypto = fieldCrypto,
       _audit = audit;

  static const String _entityType = 'rider';
  static const Uuid _uuid = Uuid();

  final AppDatabase _db;
  final FieldCrypto _fieldCrypto;
  final AuditRepository _audit;

  /// Inserts or updates [rider] and records the mutation atomically.
  Future<Rider> save(Rider rider) async {
    final id = rider.id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final existing = rider.id == null
        ? <Map<String, Object?>>[]
        : await _db.query(
            Schema.riders,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
            limit: 1,
          );
    if (rider.id != null && existing.isEmpty) {
      throw StateError('Cannot update a rider that does not exist');
    }

    final createdAt = existing.isEmpty
        ? rider.createdAt?.toUtc() ?? now
        : _requiredDate(existing.single, Schema.createdAt);
    final saved = rider.copyWith(id: id, createdAt: createdAt, updatedAt: now);
    final row = <String, Object?>{
      Schema.id: id,
      Schema.planId: saved.planId,
      Schema.riderName: saved.riderName,
      Schema.coverageAmount: await _fieldCrypto.encryptNullable(
        plaintext: saved.coverageAmount?.toString(),
        entityType: _entityType,
        fieldName: Schema.coverageAmount,
        recordId: id,
      ),
      Schema.paymentTerm: saved.paymentTerm,
      Schema.deductible: await _fieldCrypto.encryptNullable(
        plaintext: saved.deductible?.toString(),
        entityType: _entityType,
        fieldName: Schema.deductible,
        recordId: id,
      ),
      Schema.waitingPeriod: saved.waitingPeriod,
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
          ? <String, Object?>{Schema.planId: saved.planId}
          : null,
      mutation: (Transaction transaction) async {
        if (existing.isEmpty) {
          await transaction.insert(Schema.riders, row);
        } else {
          final changed = await transaction.update(
            Schema.riders,
            row,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
          );
          if (changed != 1) {
            throw StateError('Rider update did not affect exactly one row');
          }
        }
      },
    );
    return saved;
  }

  /// Finds and decrypts a rider by UUID.
  Future<Rider?> findById(String id) async {
    final rows = await _db.query(
      Schema.riders,
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  /// Returns riders for [planId], excluding archived records by default.
  Future<List<Rider>> findByPlanId(
    String planId, {
    bool includeArchived = false,
  }) {
    return _findMany(
      where: includeArchived
          ? '${Schema.planId} = ?'
          : '${Schema.planId} = ? AND ${Schema.archivedAt} IS NULL',
      whereArgs: <Object?>[planId],
    );
  }

  /// Returns riders ordered by creation time, excluding archived records by
  /// default.
  Future<List<Rider>> findAll({bool includeArchived = false}) {
    return _findMany(
      where: includeArchived ? null : '${Schema.archivedAt} IS NULL',
    );
  }

  /// Returns only archived riders, newest archive first.
  Future<List<Rider>> findAllArchived() {
    return _findMany(
      where: '${Schema.archivedAt} IS NOT NULL',
      orderBy: '${Schema.archivedAt} DESC, ${Schema.id} ASC',
    );
  }

  /// Archives a rider and records the action atomically.
  Future<void> archive(String id) =>
      _changeArchiveState(id, DateTime.now().toUtc(), AuditEventType.archive);

  /// Restores an archived rider and records the action atomically.
  Future<void> restore(String id) =>
      _changeArchiveState(id, null, AuditEventType.restore);

  /// Physically deletes a rider and records a delete audit event.
  Future<void> delete(String id) async {
    await _audit.recordMutation(
      eventType: AuditEventType.delete,
      entityType: _entityType,
      entityId: id,
      mutation: (Transaction transaction) async {
        final deleted = await transaction.delete(
          Schema.riders,
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[id],
        );
        if (deleted != 1) {
          throw StateError('Rider delete did not affect exactly one row');
        }
      },
    );
  }

  /// Counts active riders for [planId].
  Future<int> countByPlanId(String planId) async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${Schema.riders} '
      'WHERE ${Schema.planId} = ? AND ${Schema.archivedAt} IS NULL',
      <Object?>[planId],
    );
    final count = rows.single['count'];
    if (count is int) {
      return count;
    }
    throw StateError('Rider count is invalid');
  }

  Future<List<Rider>> _findMany({
    required String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final rows = await _db.query(
      Schema.riders,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? '${Schema.createdAt} ASC, ${Schema.id} ASC',
    );
    final riders = <Rider>[];
    for (final row in rows) {
      riders.add(await _fromRow(row));
    }
    return riders;
  }

  Future<Rider> _fromRow(Map<String, Object?> row) async {
    final id = _requiredString(row, Schema.id);
    final coverageAmount = await _decryptNullable(
      row,
      Schema.coverageAmount,
      id,
    );
    final deductible = await _decryptNullable(row, Schema.deductible, id);
    final parsedCoverage = coverageAmount == null
        ? null
        : double.tryParse(coverageAmount);
    final parsedDeductible = deductible == null
        ? null
        : double.tryParse(deductible);
    if ((coverageAmount != null && parsedCoverage == null) ||
        (deductible != null && parsedDeductible == null)) {
      throw StateError('Stored rider amount is invalid');
    }
    return Rider(
      id: id,
      planId: _requiredString(row, Schema.planId),
      riderName: _requiredString(row, Schema.riderName),
      coverageAmount: parsedCoverage,
      paymentTerm: _optionalString(row, Schema.paymentTerm),
      deductible: parsedDeductible,
      waitingPeriod: _optionalString(row, Schema.waitingPeriod),
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
      throw StateError('Stored rider field is invalid');
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
          Schema.riders,
          <String, Object?>{
            Schema.archivedAt: archivedAt?.toIso8601String(),
            Schema.updatedAt: DateTime.now().toUtc().toIso8601String(),
          },
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[id],
        );
        if (changed != 1) {
          throw StateError('Rider archive operation did not affect one row');
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
  throw StateError('Stored rider value is invalid');
}

String? _optionalString(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw StateError('Stored rider value is invalid');
}

DateTime _requiredDate(Map<String, Object?> row, String column) {
  final parsed = DateTime.tryParse(_requiredString(row, column));
  if (parsed != null) {
    return parsed.toUtc();
  }
  throw StateError('Stored rider timestamp is invalid');
}

DateTime? _optionalDate(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw StateError('Stored rider timestamp is invalid');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return parsed.toUtc();
  }
  throw StateError('Stored rider timestamp is invalid');
}
