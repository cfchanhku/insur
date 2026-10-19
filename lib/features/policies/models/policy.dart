/// Represents a locally stored insurance policy and its client relationship.
///
/// TODO(insur): Keep this model aligned with docs/IMPLEMENTATION_PLAN.md.
library;

import 'policy_status.dart';

const Object _unset = Object();

/// An insurance policy belonging to exactly one client.
class Policy {
  /// Creates a policy. Runtime assertions validate identifiers, dates,
  /// currency, and the required client relationship.
  Policy({
    this.id,
    required this.clientId,
    required this.policyNo,
    required this.company,
    required this.effectiveDate,
    required this.firstPremiumDate,
    required this.currency,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  }) : assert(
         id == null || _uuidV4Pattern.hasMatch(id),
         'id must be a valid UUID v4',
       ),
       assert(clientId != '', 'clientId must not be empty'),
       assert(
         _currencyPattern.hasMatch(currency),
         'currency must be a three-letter uppercase ISO 4217 code',
       ),
       assert(
         !effectiveDate.isAfter(firstPremiumDate),
         'effectiveDate must be on or before firstPremiumDate',
       );

  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// UUID v4 assigned when the policy is persisted; null for a new policy.
  final String? id;

  /// UUID of the client who owns this policy.
  final String clientId;

  /// Policy identifier assigned by the insurer.
  final String policyNo;

  /// Insurer name.
  final String company;

  /// Date from which the policy is effective.
  final DateTime effectiveDate;

  /// Date on which the first premium is due or paid.
  final DateTime firstPremiumDate;

  /// Three-letter uppercase ISO 4217 currency code.
  final String currency;

  /// Current lifecycle status of the policy.
  final PolicyStatus status;

  /// Optional notes and persistence lifecycle timestamps.
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Null while the policy is active rather than archived.
  final DateTime? archivedAt;

  /// Returns a copy with selected values replaced.
  ///
  /// Nullable fields use an internal sentinel, so explicitly passing null
  /// clears the field while omitting it preserves the current value.
  Policy copyWith({
    Object? id = _unset,
    String? clientId,
    String? policyNo,
    String? company,
    DateTime? effectiveDate,
    DateTime? firstPremiumDate,
    String? currency,
    PolicyStatus? status,
    Object? notes = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? archivedAt = _unset,
  }) {
    return Policy(
      id: _copyNullable<String>(id, this.id),
      clientId: clientId ?? this.clientId,
      policyNo: policyNo ?? this.policyNo,
      company: company ?? this.company,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      firstPremiumDate: firstPremiumDate ?? this.firstPremiumDate,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      notes: _copyNullable<String>(notes, this.notes),
      createdAt: _copyNullable<DateTime>(createdAt, this.createdAt),
      updatedAt: _copyNullable<DateTime>(updatedAt, this.updatedAt),
      archivedAt: _copyNullable<DateTime>(archivedAt, this.archivedAt),
    );
  }

  /// Serializes every date as a UTC ISO 8601 string.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'clientId': clientId,
      'policyNo': policyNo,
      'company': company,
      'effectiveDate': effectiveDate.toUtc().toIso8601String(),
      'firstPremiumDate': firstPremiumDate.toUtc().toIso8601String(),
      'currency': currency,
      'status': status.value,
      'notes': notes,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'archivedAt': archivedAt?.toUtc().toIso8601String(),
    };
  }

  /// Parses ISO 8601 dates and converts them to the local timezone.
  ///
  /// Missing required fields, malformed values, and unknown statuses fail
  /// with [ArgumentError] instead of being silently defaulted.
  factory Policy.fromJson(Map<String, Object?> json) {
    return Policy(
      id: _optionalString(json, 'id'),
      clientId: _requiredString(json, 'clientId'),
      policyNo: _requiredString(json, 'policyNo'),
      company: _requiredString(json, 'company'),
      effectiveDate: _requiredDateTime(json, 'effectiveDate'),
      firstPremiumDate: _requiredDateTime(json, 'firstPremiumDate'),
      currency: _requiredString(json, 'currency'),
      status: PolicyStatus.fromString(_requiredString(json, 'status')),
      notes: _optionalString(json, 'notes'),
      createdAt: _requiredNullableDateTime(json, 'createdAt'),
      updatedAt: _requiredNullableDateTime(json, 'updatedAt'),
      archivedAt: _optionalDateTime(json, 'archivedAt'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Policy &&
        other.id == id &&
        other.clientId == clientId &&
        other.policyNo == policyNo &&
        other.company == company &&
        _sameInstant(other.effectiveDate, effectiveDate) &&
        _sameInstant(other.firstPremiumDate, firstPremiumDate) &&
        other.currency == currency &&
        other.status == status &&
        other.notes == notes &&
        _sameInstant(other.createdAt, createdAt) &&
        _sameInstant(other.updatedAt, updatedAt) &&
        _sameInstant(other.archivedAt, archivedAt);
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    policyNo,
    company,
    effectiveDate.millisecondsSinceEpoch,
    firstPremiumDate.millisecondsSinceEpoch,
    currency,
    status,
    notes,
    createdAt?.millisecondsSinceEpoch,
    updatedAt?.millisecondsSinceEpoch,
    archivedAt?.millisecondsSinceEpoch,
  );

  @override
  String toString() =>
      'Policy(id: $id, policyNo: $policyNo, status: ${status.value})';
}

bool _sameInstant(DateTime? left, DateTime? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return left.isAtSameMomentAs(right);
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

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  try {
    return DateTime.parse(value).toLocal();
  } on FormatException {
    throw ArgumentError('Invalid date field: $key');
  }
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
  try {
    return DateTime.parse(value).toLocal();
  } on FormatException {
    throw ArgumentError('Invalid date field: $key');
  }
}
