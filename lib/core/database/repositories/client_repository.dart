/// Persists clients while encrypting identifying fields before database writes.
///
/// PII columns contain base64 AES-GCM ciphertext, and each value is bound by
/// AAD to the `client` entity, field name, and client UUID. Plaintext values
/// are decrypted only when constructing domain models.
library;

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../security/field_crypto.dart';
import '../database.dart';
import '../schema.dart';

/// Reads and writes client records through [AppDatabase].
class ClientRepository {
  /// Creates a repository with its database and field encryption service.
  ClientRepository({
    required AppDatabase db,
    required FieldCrypto fieldCrypto,
  })  : _db = db,
        _fieldCrypto = fieldCrypto;

  static const String _entityType = 'client';
  static const Uuid _uuid = Uuid();

  final AppDatabase _db;
  final FieldCrypto _fieldCrypto;

  /// Encrypts client PII and inserts or updates the client atomically.
  Future<Client> save(Client client) async {
    final id = client.id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final existing = client.id == null
        ? <Map<String, Object?>>[]
        : await _db.query(
            Schema.clients,
            where: '${Schema.id} = ?',
            whereArgs: <Object?>[id],
          );
    if (client.id != null && existing.isEmpty) {
      throw StateError('Cannot update a client that does not exist');
    }

    final createdAt = existing.isEmpty
        ? client.createdAt?.toUtc() ?? now
        : _requiredDate(existing.first, Schema.createdAt);
    final saved = client.copyWith(
      id: id,
      createdAt: createdAt,
      updatedAt: now,
    );
    final row = <String, Object?>{
      Schema.id: id,
      Schema.role: saved.role.value,
      Schema.name: await _encrypt(saved.name, 'name', id),
      Schema.gender: saved.gender.value,
      Schema.dob:
          await _encrypt(saved.dob.toUtc().toIso8601String(), 'dob', id),
      Schema.phone: await _fieldCrypto.encryptNullable(
        plaintext: saved.phone,
        entityType: _entityType,
        fieldName: Schema.phone,
        recordId: id,
      ),
      Schema.email: await _fieldCrypto.encryptNullable(
        plaintext: saved.email,
        entityType: _entityType,
        fieldName: Schema.email,
        recordId: id,
      ),
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

    await _db.db.transaction((Transaction transaction) async {
      if (existing.isEmpty) {
        await transaction.insert(Schema.clients, row);
      } else {
        final changed = await transaction.update(
          Schema.clients,
          row,
          where: '${Schema.id} = ?',
          whereArgs: <Object?>[id],
        );
        if (changed != 1) {
          throw StateError('Client update did not affect exactly one row');
        }
      }
    });
    return saved;
  }

  /// Finds and decrypts a client by UUID.
  Future<Client?> findById(String id) async {
    final rows = await _db.query(
      Schema.clients,
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  /// Returns clients ordered by creation time, excluding archived clients by
  /// default.
  Future<List<Client>> findAll({bool includeArchived = false}) async {
    final rows = await _db.query(
      Schema.clients,
      where: includeArchived ? null : '${Schema.archivedAt} IS NULL',
      orderBy: '${Schema.createdAt} ASC, ${Schema.id} ASC',
    );
    final clients = <Client>[];
    for (final row in rows) {
      clients.add(await _fromRow(row));
    }
    return clients;
  }

  /// Archives a client without physically deleting the business record.
  Future<void> archive(String id) async {
    await _setArchived(id, DateTime.now().toUtc());
  }

  /// Restores an archived client.
  Future<void> restore(String id) async {
    await _setArchived(id, null);
  }

  /// Archives the client; permanent erasure is not exposed by this repository.
  Future<void> delete(String id) => archive(id);

  Future<String> _encrypt(String plaintext, String fieldName, String id) {
    return _fieldCrypto.encrypt(
      plaintext: plaintext,
      entityType: _entityType,
      fieldName: fieldName,
      recordId: id,
    );
  }

  Future<Client> _fromRow(Map<String, Object?> row) async {
    final id = _requiredString(row, Schema.id);
    final name = await _decrypt(row, Schema.name, id);
    final dobText = await _decrypt(row, Schema.dob, id);
    final dob = DateTime.tryParse(dobText);
    if (dob == null) {
      throw StateError('Stored client date is invalid');
    }

    return Client(
      id: id,
      role: ClientRole.fromString(_requiredString(row, Schema.role)),
      name: name,
      gender: Gender.fromString(_requiredString(row, Schema.gender)),
      dob: dob,
      phone: await _decryptNullable(row, Schema.phone, id),
      email: await _decryptNullable(row, Schema.email, id),
      notes: await _decryptNullable(row, Schema.notes, id),
      createdAt: _requiredDate(row, Schema.createdAt),
      updatedAt: _requiredDate(row, Schema.updatedAt),
      archivedAt: _optionalDate(row, Schema.archivedAt),
    );
  }

  Future<String> _decrypt(
    Map<String, Object?> row,
    String fieldName,
    String id,
  ) async {
    return _fieldCrypto.decrypt(
      ciphertext: _requiredString(row, fieldName),
      entityType: _entityType,
      fieldName: fieldName,
      recordId: id,
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
      throw StateError('Stored client value is invalid');
    }
    return _fieldCrypto.decryptNullable(
      ciphertext: value,
      entityType: _entityType,
      fieldName: fieldName,
      recordId: id,
    );
  }

  Future<void> _setArchived(String id, DateTime? archivedAt) async {
    final changed = await _db.db.update(
      Schema.clients,
      <String, Object?>{
        Schema.archivedAt: archivedAt?.toUtc().toIso8601String(),
        Schema.updatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${Schema.id} = ?',
      whereArgs: <Object?>[id],
    );
    if (changed != 1) {
      throw StateError('Client archive operation did not affect one row');
    }
  }
}

String _requiredString(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value is String) {
    return value;
  }
  throw StateError('Stored client value is invalid');
}

DateTime _requiredDate(Map<String, Object?> row, String column) {
  final value = DateTime.tryParse(_requiredString(row, column));
  if (value != null) {
    return value;
  }
  throw StateError('Stored client timestamp is invalid');
}

DateTime? _optionalDate(Map<String, Object?> row, String column) {
  final value = row[column];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw StateError('Stored client timestamp is invalid');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return parsed;
  }
  throw StateError('Stored client timestamp is invalid');
}
