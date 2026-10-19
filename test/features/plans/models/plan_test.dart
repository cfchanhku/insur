import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/plans/models/plan.dart';
import 'package:insur/features/plans/models/plan_category.dart';

void main() {
  late Plan sample;

  setUp(() {
    sample = Plan(
      id: '123e4567-e89b-42d3-a456-426614174000',
      policyId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
      category: PlanCategory.ci,
      planName: 'Synthetic critical illness cover',
      coverageAmount: 125000.5,
      paymentTerm: '20 years',
      coveragePeriod: 'To age 80',
      notes: 'Synthetic plan note',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 2),
    );
  });

  group('PlanCategory', () {
    test('parses every category', () {
      for (final category in PlanCategory.values) {
        expect(PlanCategory.fromString(category.value), category);
      }
    });

    test('rejects an unknown category', () {
      expect(() => PlanCategory.fromString('unknown'), throwsArgumentError);
    });

    test('serializes values as stable snake case', () {
      expect(
        PlanCategory.values.map((PlanCategory category) => category.value),
        <String>['life', 'ci', 'hospital', 'accident', 'savings', 'other'],
      );
    });

    test('returns the matching localization keys', () {
      expect(
        PlanCategory.values.map((PlanCategory category) => category.labelKey),
        <String>[
          'plan_category_life',
          'plan_category_ci',
          'plan_category_hospital',
          'plan_category_accident',
          'plan_category_savings',
          'plan_category_other',
        ],
      );
    });
  });

  group('Plan constructor', () {
    test('constructs a valid plan', () {
      expect(sample.id, '123e4567-e89b-42d3-a456-426614174000');
      expect(sample.coverageAmount, 125000.5);
    });

    test('allows an unpersisted plan with no id', () {
      expect(_plan().id, isNull);
    });

    test('asserts on an invalid UUID', () {
      expect(() => _plan(id: 'invalid'), throwsA(isA<AssertionError>()));
    });

    test('asserts on an empty policy id', () {
      expect(() => _plan(policyId: ''), throwsA(isA<AssertionError>()));
    });

    test('asserts on an empty plan name', () {
      expect(() => _plan(planName: ''), throwsA(isA<AssertionError>()));
    });

    test('asserts on a negative coverage amount', () {
      expect(() => _plan(coverageAmount: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('Plan.copyWith', () {
    test('preserves all values when no changes are supplied', () {
      expect(sample.copyWith(), sample);
    });

    test('changes one field and preserves the rest', () {
      final updated = sample.copyWith(planName: 'Updated synthetic plan');

      expect(updated.planName, 'Updated synthetic plan');
      expect(updated.copyWith(planName: sample.planName), sample);
    });

    test('clears each nullable business field when explicitly null', () {
      final updated = sample.copyWith(
        coverageAmount: null,
        paymentTerm: null,
        coveragePeriod: null,
        notes: null,
      );

      expect(updated.coverageAmount, isNull);
      expect(updated.paymentTerm, isNull);
      expect(updated.coveragePeriod, isNull);
      expect(updated.notes, isNull);
    });

    test('clears nullable identifier and lifecycle timestamps', () {
      final updated = sample.copyWith(
        id: null,
        createdAt: null,
        updatedAt: null,
        archivedAt: null,
      );

      expect(updated.id, isNull);
      expect(updated.createdAt, isNull);
      expect(updated.updatedAt, isNull);
      expect(updated.archivedAt, isNull);
    });
  });

  group('Plan.toJson / fromJson', () {
    test('round-trips the plan', () {
      expect(Plan.fromJson(sample.toJson()), sample);
    });

    test('serializes all values and normalizes timestamps to UTC', () {
      expect(sample.toJson(), <String, Object?>{
        'id': sample.id,
        'policyId': sample.policyId,
        'category': 'ci',
        'planName': sample.planName,
        'coverageAmount': '125000.5',
        'paymentTerm': '20 years',
        'coveragePeriod': 'To age 80',
        'notes': 'Synthetic plan note',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-02-01T00:00:00.000Z',
        'archivedAt': null,
      });
    });

    test('preserves null optional fields', () {
      final plan = _plan();

      expect(Plan.fromJson(plan.toJson()), plan);
    });

    test('parses coverage amount from a string', () {
      final json = sample.toJson()..['coverageAmount'] = '42.75';

      expect(Plan.fromJson(json).coverageAmount, 42.75);
    });

    test('rejects malformed numeric data', () {
      final json = sample.toJson()..['coverageAmount'] = 'not-a-number';

      expect(() => Plan.fromJson(json), throwsArgumentError);
    });

    test('converts parsed timestamps to UTC', () {
      final json = sample.toJson()..['createdAt'] = '2026-01-01T08:00:00+08:00';

      expect(Plan.fromJson(json).createdAt, DateTime.utc(2026));
    });
  });

  group('Plan equality', () {
    test('equal plans compare equal and have matching hashes', () {
      final equalPlan = Plan.fromJson(sample.toJson());

      expect(equalPlan, sample);
      expect(equalPlan.hashCode, sample.hashCode);
    });

    test('different plans do not compare equal', () {
      expect(sample.copyWith(category: PlanCategory.life), isNot(sample));
    });
  });

  group('Plan.toString', () {
    test('does not include the plan name, coverage, or notes', () {
      expect(sample.toString(), isNot(contains(sample.planName)));
      expect(sample.toString(), isNot(contains('125000.5')));
      expect(sample.toString(), isNot(contains(sample.notes!)));
    });
  });
}

Plan _plan({
  String? id,
  String policyId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
  String planName = 'Synthetic plan',
  double? coverageAmount,
}) {
  return Plan(
    id: id,
    policyId: policyId,
    category: PlanCategory.life,
    planName: planName,
    coverageAmount: coverageAmount,
  );
}
