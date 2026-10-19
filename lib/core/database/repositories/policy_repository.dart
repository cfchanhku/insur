/// Persists policies while encrypting their sensitive identifying fields.
///
/// Policy numbers and notes are base64 AES-GCM ciphertext bound to the policy
/// UUID and field name. Company, currency, status, and dates remain queryable.
library;

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../features/policies/models/policy.dart';
import '../../../features/policies/models/policy_status.dart';
import '../../audit/audit_event_type.dart';
import '../../security/field_crypto.dart';
import '../database.dart';
import '../schema.dart';
import 'audit_repository.dart';

/// Reads and writes policy records through [AppDatabase].
class PolicyRepository {
  /// Creates a repository with its database and field encryption service.
  PolicyRepository({
    required AppDatabase db,
    required FieldCrypto fieldCrypto,
    required AuditRepository audit,
  }) : _db = db,
       _fieldCrypto = fieldCrypto,
       _audit = audit;

  static const String _entityType = 'policy';
  static const Uuid _uuid = Uuid();

  final AppDatabase _db;
  final FieldCrypto _fieldCrypto;
  final AuditRepository _audit;

  /// Encrypts policy identifiers and notes before inserting or updating.
  Future<Policy> save(Policy policy) async {
    final id = policy.id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final existing = policy.id == null
        ? <Map<String, Object?>>[]
        : await _db.query(
            Schema.policies,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
          );
    if (policy.id != null && existing.isEmpty) {
      throw StateError('Cannot update a policy that does not exist');
    }

    final createdAt = existing.isEmpty
        ? policy.createdAt?.toUtc() ?? now
        : _requiredDate(existing.first, Schema.createdAt);
    final saved = policy.copyWith(id: id, createdAt: createdAt, updatedAt: now);
    final row = <String, Object?>{
      Schema.id: id,
      Schema.clientId: saved.clientId,
      Schema.policyNo: await _fieldCrypto.encrypt(
        plaintext: saved.policyNo,
        entityType: _entityType,
        fieldName: Schema.policyNo,
        recordId: id,
      ),
      Schema.company: saved.company,
      Schema.effectiveDate: saved.effectiveDate.toUtc().toIso8601String(),
      Schema.firstPremiumDate: saved.firstPremiumDate.toUtc().toIso8601String(),
      Schema.currency: saved.currency,
      Schema.status: saved.status.value,
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
      mutation: (Transaction transaction) async {
        if (existing.isEmpty) {
          await transaction.insert(Schema.policies, row);
        } else {
          final changed = await transaction.update(
            Schema.policies,
            row,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
          );
          if (changed != 1) {
            throw StateError('Policy update did not affect exactly one row');
          }
        }
      },
    );
    return saved;
  }

  /// Finds and decrypts a policy by UUID.
  Future<Policy?> findById(String id) async {
    final rows = await _db.query(
      Schema.policies,
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  /// Returns policies owned by [clientId], excluding archived rows by default.
  Future<List<Policy>> findByClientId(
    String clientId, {
    bool includeArchived = false,
  }) async {
    final where = includeArchived
        ? '${Schema.clientId} = ?'
        : '${Schema.clientId} = ? AND ${Schema.archivedAt} IS NULL';
    final rows = await _db.query(
      Schema.policies,
      where: where,
      whereArgs: <Object?>[clientId],
      orderBy: '${Schema.createdAt} ASC, ${Schema.id} ASC',
    );
    final policies = <Policy>[];
    for (final row in rows) {
      policies.add(await _fromRow(row));
    }
    return policies;
  }

  /// Returns policies ordered by creation time, excluding archived records by
  /// default.
  Future<List<Policy>> findAll({bool includeArchived = false}) async {
    final rows = await _db.query(
      Schema.policies,
      where: includeArchived ? null : '${Schema.archivedAt} IS NULL',
      orderBy: '${Schema.createdAt} ASC, ${Schema.id} ASC',
    );
    final policies = <Policy>[];
    for (final row in rows) {
      policies.add(await _fromRow(row));
    }
    return policies;
  }

  /// Returns only archived policies, newest archive first.
  Future<List<Policy>> findAllArchived() async {
    final rows = await _db.query(
      Schema.policies,
      where: '${Schema.archivedAt} IS NOT NULL',
      orderBy: '${Schema.archivedAt} DESC, ${Schema.id} ASC',
    );
    final policies = <Policy>[];
    for (final row in rows) {
      policies.add(await _fromRow(row));
    }
    return policies;
  }

  /// Archives a policy without physically deleting the business record.
  Future<void> archive(String id) async {
    await _audit.recordMutation(
      eventType: AuditEventType.archive,
      entityType: _entityType,
      entityId: id,
      mutation: (Transaction transaction) =>
          _setArchived(transaction, id, DateTime.now().toUtc()),
    );
  }

  /// Restores an archived policy.
  Future<void> restore(String id) async {
    await _audit.recordMutation(
      eventType: AuditEventType.restore,
      entityType: _entityType,
      entityId: id,
      mutation: (Transaction transaction) =>
          _setArchived(transaction, id, null),
    );
  }

  /// Permanently deletes a policy and all its plans and riders atomically.
  Future<void> delete(String id) async {
    await _audit.recordMutation(
      eventType: AuditEventType.delete,
      entityType: _entityType,
      entityId: id,
      mutation: (Transaction transaction) async {
        final planIds = await transaction.query(
          Schema.plans,
          columns: <String>[Schema.id],
          where: '${Schema.policyId} = ?',
          whereArgs: <Object?>[id],
        );
        final ids = planIds
            .map((Map<String, Object?> row) => row[Schema.id])
            .whereType<String>()
            .toList(growable: false);
        if (ids.isNotEmpty) {
          final placeholders = List<String>.filled(ids.length, '?').join(', ');
          await transaction.delete(
            Schema.riders,
            where: '${Schema.planId} IN ($placeholders)',
            whereArgs: ids,
          );
          await transaction.delete(
            Schema.plans,
            where: '${Schema.id} IN ($placeholders)',
            whereArgs: ids,
          );
        }
        final deleted = await transaction.delete(
          Schema.policies,
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[id],
        );
        if (deleted != 1) {
          throw StateError('Policy delete did not affect exactly one row');
        }
      },
    );
  }

  Future<Policy> _fromRow(Map<String, Object?> row) async {
    final id = _requiredString(row, Schema.id);
    final effectiveDateText = _requiredString(row, Schema.effectiveDate);
    final firstPremiumDateText = _requiredString(row, Schema.firstPremiumDate);
    final effectiveDate = DateTime.tryParse(effectiveDateText);
    final firstPremiumDate = DateTime.tryParse(firstPremiumDateText);
    if (effectiveDate == null || firstPremiumDate == null) {
      throw StateError('Stored policy date is invalid');
    }

    return Policy(
      id: id,
      clientId: _requiredString(row, Schema.clientId),
      policyNo: await _fieldCrypto.decrypt(
        ciphertext: _requiredString(row, Schema.policyNo),
        entityType: _entityType,
        fieldName: Schema.policyNo,
        recordId: id,
      ),
      company: _requiredString(row, Schema.company),
      effectiveDate: effectiveDate,
      firstPremiumDate: firstPremiumDate,
      currency: _requiredString(row, Schema.currency),
      status: PolicyStatus.fromString(_requiredString(row, Schema.status)),
      notes: await _decryptNullable(row, Schema.notes, id),
      createdAt: _requiredDate(row, Schema.createdAt),
      updatedAt: _requiredDate(row, Schema.updatedAt),
      archivedAt: _optionalDate(row, Schema.archivedAt),
    );
  }

  Future<String?> _decryptNullable(
    Map<String, Object?> row,
    String fieldName,
    String id,
  ) async {
    final value = row[fieldName];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw StateError('Stored policy value is invalid');
    }
    return _fieldCrypto.decryptNullable(
      ciphertext: value,
      entityType: _entityType,
      fieldName: fieldName,
      recordId: id,
    );
  }

  Future<void> _setArchived(
    Transaction transaction,
    String id,
    DateTime? archivedAt,
  ) async {
    final changed = await transaction.update(
      Schema.policies,
      <String, Object?>{
        Schema.archivedAt: archivedAt?.toUtc().toIso8601String(),
        Schema.updatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
    );
    if (changed != 1) {
      throw StateError('Policy archive operation did not affect one row');
    }
  }
}

String _requiredString(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value is String) {
    return value;
  }
  throw StateError('Stored policy value is invalid');
}

DateTime _requiredDate(Map<String, Object?> row, String column) {
  final value = DateTime.tryParse(_requiredString(row, column));
  if (value != null) {
    return value;
  }
  throw StateError('Stored policy timestamp is invalid');
}

DateTime? _optionalDate(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw StateError('Stored policy timestamp is invalid');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return parsed;
  }
  throw StateError('Stored policy timestamp is invalid');
}
