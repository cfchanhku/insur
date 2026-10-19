/// Defines an optional rider attached to an insurance plan.
library;

const Object _unset = Object();

/// Additional coverage associated with a plan.
class Rider {
  /// Creates a rider that may be persisted later.
  Rider({
    this.id,
    required this.planId,
    required this.riderName,
    this.coverageAmount,
    this.paymentTerm,
    this.deductible,
    this.waitingPeriod,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  }) : assert(
         id == null || _uuidV4Pattern.hasMatch(id),
         'id must be a valid UUID v4',
       ),
       assert(planId != '', 'planId must not be empty'),
       assert(riderName != '', 'riderName must not be empty'),
       assert(
         coverageAmount == null || coverageAmount >= 0,
         'coverageAmount must not be negative',
       ),
       assert(
         deductible == null || deductible >= 0,
         'deductible must not be negative',
       );

  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// UUID v4 assigned when this rider is persisted.
  final String? id;

  /// UUID of the plan that owns this rider.
  final String planId;

  /// Rider display name.
  final String riderName;

  /// Optional coverage amount, encrypted before database storage.
  final double? coverageAmount;

  /// Optional payment term.
  final String? paymentTerm;

  /// Optional deductible, encrypted before database storage.
  final double? deductible;

  /// Optional waiting period.
  final String? waitingPeriod;

  /// Creation timestamp in UTC when persisted.
  final DateTime? createdAt;

  /// Last update timestamp in UTC when persisted.
  final DateTime? updatedAt;

  /// Archive timestamp, or null while this rider is active.
  final DateTime? archivedAt;

  /// Returns a copy with selected values replaced.
  ///
  /// Nullable fields use sentinels so explicitly passing null clears them.
  Rider copyWith({
    Object? id = _unset,
    String? planId,
    String? riderName,
    Object? coverageAmount = _unset,
    Object? paymentTerm = _unset,
    Object? deductible = _unset,
    Object? waitingPeriod = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? archivedAt = _unset,
  }) {
    return Rider(
      id: _copyNullable<String>(id, this.id),
      planId: planId ?? this.planId,
      riderName: riderName ?? this.riderName,
      coverageAmount: _copyNullableDouble(coverageAmount, this.coverageAmount),
      paymentTerm: _copyNullable<String>(paymentTerm, this.paymentTerm),
      deductible: _copyNullableDouble(deductible, this.deductible),
      waitingPeriod: _copyNullable<String>(waitingPeriod, this.waitingPeriod),
      createdAt: _copyNullable<DateTime>(createdAt, this.createdAt),
      updatedAt: _copyNullable<DateTime>(updatedAt, this.updatedAt),
      archivedAt: _copyNullable<DateTime>(archivedAt, this.archivedAt),
    );
  }

  /// Serializes coverage and deductible values as strings, and dates as UTC
  /// ISO 8601 values.
  ///
  /// Numeric values are strings in JSON because the encrypted database values
  /// are stored in TEXT columns.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'planId': planId,
      'riderName': riderName,
      'coverageAmount': coverageAmount?.toString(),
      'paymentTerm': paymentTerm,
      'deductible': deductible?.toString(),
      'waitingPeriod': waitingPeriod,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'archivedAt': archivedAt?.toUtc().toIso8601String(),
    };
  }

  /// Creates a rider from JSON, rejecting missing or malformed values.
  factory Rider.fromJson(Map<String, Object?> json) {
    return Rider(
      id: _optionalString(json, 'id'),
      planId: _requiredString(json, 'planId'),
      riderName: _requiredString(json, 'riderName'),
      coverageAmount: _optionalDoubleString(json, 'coverageAmount'),
      paymentTerm: _optionalString(json, 'paymentTerm'),
      deductible: _optionalDoubleString(json, 'deductible'),
      waitingPeriod: _optionalString(json, 'waitingPeriod'),
      createdAt: _optionalDateTime(json, 'createdAt'),
      updatedAt: _optionalDateTime(json, 'updatedAt'),
      archivedAt: _optionalDateTime(json, 'archivedAt'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Rider &&
        other.id == id &&
        other.planId == planId &&
        other.riderName == riderName &&
        other.coverageAmount == coverageAmount &&
        other.paymentTerm == paymentTerm &&
        other.deductible == deductible &&
        other.waitingPeriod == waitingPeriod &&
        _sameInstant(other.createdAt, createdAt) &&
        _sameInstant(other.updatedAt, updatedAt) &&
        _sameInstant(other.archivedAt, archivedAt);
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    riderName,
    coverageAmount,
    paymentTerm,
    deductible,
    waitingPeriod,
    createdAt?.millisecondsSinceEpoch,
    updatedAt?.millisecondsSinceEpoch,
    archivedAt?.millisecondsSinceEpoch,
  );

  @override
  String toString() => 'Rider($id, archived=${archivedAt != null})';
}

T? _copyNullable<T>(Object? candidate, T? current) {
  if (identical(candidate, _unset)) {
    return current;
  }
  return candidate as T?;
}

double? _copyNullableDouble(Object? candidate, double? current) {
  if (identical(candidate, _unset)) {
    return current;
  }
  if (candidate == null) {
    return null;
  }
  if (candidate is num) {
    return candidate.toDouble();
  }
  throw ArgumentError.value(candidate, 'amount', 'Must be numeric');
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

double? _optionalDoubleString(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) {
    return null;
  }
  final parsed = double.tryParse(value);
  if (parsed == null) {
    throw ArgumentError('Invalid numeric field: $key');
  }
  return parsed;
}

DateTime? _optionalDateTime(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw ArgumentError('Invalid date field: $key');
  }
  return parsed.toUtc();
}

bool _sameInstant(DateTime? left, DateTime? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return left.isAtSameMomentAs(right);
}
