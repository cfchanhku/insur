import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/riders/models/rider.dart';

void main() {
  late Rider sample;

  setUp(() {
    sample = Rider(
      id: '123e4567-e89b-42d3-a456-426614174000',
      planId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
      riderName: 'Synthetic hospital rider',
      coverageAmount: 50000,
      paymentTerm: '10 years',
      deductible: 250.5,
      waitingPeriod: '30 days',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 2),
    );
  });

  group('Rider constructor', () {
    test('constructs a valid rider', () {
      expect(sample.riderName, 'Synthetic hospital rider');
      expect(sample.deductible, 250.5);
    });

    test('allows an unpersisted rider with no id', () {
      expect(_rider().id, isNull);
    });

    test('asserts on an invalid UUID', () {
      expect(() => _rider(id: 'invalid'), throwsA(isA<AssertionError>()));
    });

    test('asserts on an empty plan id', () {
      expect(() => _rider(planId: ''), throwsA(isA<AssertionError>()));
    });

    test('asserts on an empty rider name', () {
      expect(() => _rider(riderName: ''), throwsA(isA<AssertionError>()));
    });

    test('asserts on negative monetary values', () {
      expect(() => _rider(coverageAmount: -1), throwsA(isA<AssertionError>()));
      expect(() => _rider(deductible: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('Rider.copyWith', () {
    test('preserves all values when no changes are supplied', () {
      expect(sample.copyWith(), sample);
    });

    test('changes one field and preserves the rest', () {
      final updated = sample.copyWith(riderName: 'Updated synthetic rider');

      expect(updated.riderName, 'Updated synthetic rider');
      expect(updated.copyWith(riderName: sample.riderName), sample);
    });

    test('clears nullable business fields when explicitly null', () {
      final updated = sample.copyWith(
        coverageAmount: null,
        paymentTerm: null,
        deductible: null,
        waitingPeriod: null,
      );

      expect(updated.coverageAmount, isNull);
      expect(updated.paymentTerm, isNull);
      expect(updated.deductible, isNull);
      expect(updated.waitingPeriod, isNull);
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

  group('Rider.toJson / fromJson', () {
    test('round-trips the rider', () {
      expect(Rider.fromJson(sample.toJson()), sample);
    });

    test('serializes numeric values as strings and timestamps as UTC', () {
      final json = sample.toJson();

      expect(json['coverageAmount'], '50000.0');
      expect(json['deductible'], '250.5');
      expect(json['createdAt'], '2026-01-01T00:00:00.000Z');
      expect(json['updatedAt'], '2026-02-01T00:00:00.000Z');
    });

    test('preserves null optional fields', () {
      final rider = _rider();

      expect(Rider.fromJson(rider.toJson()), rider);
    });

    test('parses monetary values from strings', () {
      final json = sample.toJson()
        ..['coverageAmount'] = '12.5'
        ..['deductible'] = '2';

      final parsed = Rider.fromJson(json);
      expect(parsed.coverageAmount, 12.5);
      expect(parsed.deductible, 2);
    });

    test('rejects malformed monetary values', () {
      final json = sample.toJson()..['deductible'] = 'invalid';

      expect(() => Rider.fromJson(json), throwsArgumentError);
    });

    test('converts parsed timestamps to UTC', () {
      final json = sample.toJson()..['createdAt'] = '2026-01-01T08:00:00+08:00';

      expect(Rider.fromJson(json).createdAt, DateTime.utc(2026));
    });
  });

  group('Rider equality', () {
    test('equal riders compare equal and have matching hashes', () {
      final equalRider = Rider.fromJson(sample.toJson());

      expect(equalRider, sample);
      expect(equalRider.hashCode, sample.hashCode);
    });

    test('different riders do not compare equal', () {
      expect(sample.copyWith(deductible: 251), isNot(sample));
    });
  });

  group('Rider.toString', () {
    test('does not expose name or financial amounts', () {
      expect(sample.toString(), isNot(contains(sample.riderName)));
      expect(sample.toString(), isNot(contains('50000')));
      expect(sample.toString(), isNot(contains('250.5')));
    });
  });
}

Rider _rider({
  String? id,
  String planId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
  String riderName = 'Synthetic rider',
  double? coverageAmount,
  double? deductible,
}) {
  return Rider(
    id: id,
    planId: planId,
    riderName: riderName,
    coverageAmount: coverageAmount,
    deductible: deductible,
  );
}
