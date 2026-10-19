/// Represents a locally stored policy holder or insured person.
///
/// TODO(insur): Keep this model aligned with the client data-model plan.
library;

import 'client_enums.dart';

const Object _unset = Object();

/// A client record containing identifying and lifecycle information.
class Client {
  /// Creates a client. A persisted [id], when present, must be a UUID v4.
  Client({
    this.id,
    required this.role,
    required this.name,
    required this.gender,
    required this.dob,
    required this.phone,
    required this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  }) : assert(
         id == null || _uuidV4Pattern.hasMatch(id),
         'id must be a valid UUID v4',
       );

  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// UUID v4 assigned when the client is persisted; null for a new client.
  final String? id;

  /// Whether the person is the policy holder or an insured person.
  final ClientRole role;

  /// The client's name.
  final String name;

  /// The client's gender.
  final Gender gender;

  /// The client's date of birth.
  final DateTime dob;

  /// Optional contact details and notes.
  final String? phone;
  final String? email;
  final String? notes;

  /// Persistence lifecycle timestamps; [archivedAt] is null while active.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  /// Returns a copy with selected values replaced.
  ///
  /// Nullable fields use an internal sentinel, so explicitly passing null
  /// clears the field while omitting it preserves the current value.
  Client copyWith({
    Object? id = _unset,
    ClientRole? role,
    String? name,
    Gender? gender,
    DateTime? dob,
    Object? phone = _unset,
    Object? email = _unset,
    Object? notes = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? archivedAt = _unset,
  }) {
    return Client(
      id: _copyNullable<String>(id, this.id),
      role: role ?? this.role,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      phone: _copyNullable<String>(phone, this.phone),
      email: _copyNullable<String>(email, this.email),
      notes: _copyNullable<String>(notes, this.notes),
      createdAt: _copyNullable<DateTime>(createdAt, this.createdAt),
      updatedAt: _copyNullable<DateTime>(updatedAt, this.updatedAt),
      archivedAt: _copyNullable<DateTime>(archivedAt, this.archivedAt),
    );
  }

  /// Converts this client to a JSON-compatible map using ISO 8601 dates.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'role': role.value,
      'name': name,
      'gender': gender.value,
      'dob': dob.toIso8601String(),
      'phone': phone,
      'email': email,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
    };
  }

  /// Creates a client from a JSON-compatible map.
  ///
  /// Missing or malformed fields fail with [ArgumentError]; enum values are
  /// parsed strictly rather than silently defaulted.
  factory Client.fromJson(Map<String, Object?> json) {
    return Client(
      id: _optionalString(json, 'id'),
      role: ClientRole.fromString(_requiredString(json, 'role')),
      name: _requiredString(json, 'name'),
      gender: Gender.fromString(_requiredString(json, 'gender')),
      dob: _requiredDateTime(json, 'dob'),
      phone: _requiredNullableString(json, 'phone'),
      email: _requiredNullableString(json, 'email'),
      notes: _optionalString(json, 'notes'),
      createdAt: _requiredNullableDateTime(json, 'createdAt'),
      updatedAt: _requiredNullableDateTime(json, 'updatedAt'),
      archivedAt: _requiredNullableDateTime(json, 'archivedAt'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Client &&
        other.id == id &&
        other.role == role &&
        other.name == name &&
        other.gender == gender &&
        other.dob == dob &&
        other.phone == phone &&
        other.email == email &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.archivedAt == archivedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    role,
    name,
    gender,
    dob,
    phone,
    email,
    notes,
    createdAt,
    updatedAt,
    archivedAt,
  );

  @override
  String toString() =>
      'Client(id: $id, role: ${role.value}, archived: ${archivedAt != null})';
}

T? _copyNullable<T>(Object? candidate, T? current) {
  if (identical(candidate, _unset)) {
    return current;
  }
  return candidate as T?;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw ArgumentError('Missing or invalid required field: $key');
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw ArgumentError('Invalid optional field: $key');
}

String? _requiredNullableString(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw ArgumentError('Missing required field: $key');
  }
  return _optionalString(json, key);
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final dateTime = DateTime.tryParse(value);
  if (dateTime != null) {
    return dateTime;
  }
  throw ArgumentError('Invalid date field: $key');
}

DateTime? _requiredNullableDateTime(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw ArgumentError('Missing required field: $key');
  }
  return _optionalDateTime(json, key);
}

DateTime? _optionalDateTime(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) {
    return null;
  }
  final dateTime = DateTime.tryParse(value);
  if (dateTime != null) {
    return dateTime;
  }
  throw ArgumentError('Invalid date field: $key');
}
