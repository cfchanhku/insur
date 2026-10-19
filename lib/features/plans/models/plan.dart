/// Defines a plan attached to an insurance policy.
library;

import 'plan_category.dart';

const Object _unset = Object();

/// An insurance plan belonging to a policy.
class Plan {
  /// Creates a plan that may be persisted later.
  Plan({
    this.id,
    required this.policyId,
    required this.category,
    required this.planName,
    this.coverageAmount,
    this.paymentTerm,
    this.coveragePeriod,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  }) : assert(
         id == null || _uuidV4Pattern.hasMatch(id),
         'id must be a valid UUID v4',
       ),
       assert(policyId != '', 'policyId must not be empty'),
       assert(planName != '', 'planName must not be empty'),
       assert(
         coverageAmount == null || coverageAmount >= 0,
         'coverageAmount must not be negative',
       );

  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// UUID v4 assigned when this plan is persisted.
  final String? id;

  /// UUID of the policy that owns this plan.
  final String policyId;

  /// Insurance category for this plan.
  final PlanCategory category;

  /// Plan display name.
  final String planName;

  /// Optional coverage amount, encrypted before database storage.
  final double? coverageAmount;

  /// Optional payment term.
  final String? paymentTerm;

  /// Optional coverage period.
  final String? coveragePeriod;

  /// Optional notes, encrypted before database storage.
  final String? notes;

  /// Creation timestamp in UTC when persisted.
  final DateTime? createdAt;

  /// Last update timestamp in UTC when persisted.
  final DateTime? updatedAt;

  /// Archive timestamp, or null while this plan is active.
  final DateTime? archivedAt;

  /// Returns a copy with selected values replaced.
  ///
  /// Nullable fields use sentinels so explicitly passing null clears them.
  Plan copyWith({
    Object? id = _unset,
    String? policyId,
    PlanCategory? category,
    String? planName,
    Object? coverageAmount = _unset,
    Object? paymentTerm = _unset,
    Object? coveragePeriod = _unset,
    Object? notes = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? archivedAt = _unset,
  }) {
    return Plan(
      id: _copyNullable<String>(id, this.id),
      policyId: policyId ?? this.policyId,
      category: category ?? this.category,
      planName: planName ?? this.planName,
      coverageAmount: _copyNullableDouble(coverageAmount, this.coverageAmount),
      paymentTerm: _copyNullable<String>(paymentTerm, this.paymentTerm),
      coveragePeriod: _copyNullable<String>(
        coveragePeriod,
        this.coveragePeriod,
      ),
      notes: _copyNullable<String>(notes, this.notes),
      createdAt: _copyNullable<DateTime>(createdAt, this.createdAt),
      updatedAt: _copyNullable<DateTime>(updatedAt, this.updatedAt),
      archivedAt: _copyNullable<DateTime>(archivedAt, this.archivedAt),
    );
  }

  /// Serializes coverage amounts as strings and dates as UTC ISO 8601 values.
  ///
  /// A coverage amount is a [double] in memory but uses a string here because
  /// its encrypted database representation is stored in a TEXT column.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'policyId': policyId,
      'category': category.value,
      'planName': planName,
      'coverageAmount': coverageAmount?.toString(),
      'paymentTerm': paymentTerm,
      'coveragePeriod': coveragePeriod,
      'notes': notes,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'archivedAt': archivedAt?.toUtc().toIso8601String(),
    };
  }

  /// Creates a plan from JSON, rejecting missing or malformed values.
  factory Plan.fromJson(Map<String, Object?> json) {
    return Plan(
      id: _optionalString(json, 'id'),
      policyId: _requiredString(json, 'policyId'),
      category: PlanCategory.fromString(_requiredString(json, 'category')),
      planName: _requiredString(json, 'planName'),
      coverageAmount: _optionalDoubleString(json, 'coverageAmount'),
      paymentTerm: _optionalString(json, 'paymentTerm'),
      coveragePeriod: _optionalString(json, 'coveragePeriod'),
      notes: _optionalString(json, 'notes'),
      createdAt: _optionalDateTime(json, 'createdAt'),
      updatedAt: _optionalDateTime(json, 'updatedAt'),
      archivedAt: _optionalDateTime(json, 'archivedAt'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Plan &&
        other.id == id &&
        other.policyId == policyId &&
        other.category == category &&
        other.planName == planName &&
        other.coverageAmount == coverageAmount &&
        other.paymentTerm == paymentTerm &&
        other.coveragePeriod == coveragePeriod &&
        other.notes == notes &&
        _sameInstant(other.createdAt, createdAt) &&
        _sameInstant(other.updatedAt, updatedAt) &&
        _sameInstant(other.archivedAt, archivedAt);
  }

  @override
  int get hashCode => Object.hash(
    id,
    policyId,
    category,
    planName,
    coverageAmount,
    paymentTerm,
    coveragePeriod,
    notes,
    createdAt?.millisecondsSinceEpoch,
    updatedAt?.millisecondsSinceEpoch,
    archivedAt?.millisecondsSinceEpoch,
  );

  @override
  String toString() =>
      'Plan($id, ${category.value}, archived=${archivedAt != null})';
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
  throw ArgumentError.value(candidate, 'coverageAmount', 'Must be numeric');
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
