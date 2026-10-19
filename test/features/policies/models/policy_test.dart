import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/policies/models/policy.dart';
import 'package:insur/features/policies/models/policy_status.dart';

void main() {
  late Policy samplePolicy;

  setUp(() {
    samplePolicy = Policy(
      id: '123e4567-e89b-42d3-a456-426614174000',
      clientId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
      policyNo: 'POL-2026-0001',
      company: 'Example Insurance Co.',
      effectiveDate: DateTime.utc(2026, 9, 1, 12),
      firstPremiumDate: DateTime.utc(2026, 9, 2, 12),
      currency: 'HKD',
      status: PolicyStatus.active,
      notes: 'Synthetic test notes',
      createdAt: DateTime.utc(2026, 8),
      updatedAt: DateTime.utc(2026, 8, 2),
      archivedAt: DateTime.utc(2026, 10),
    );
  });

  group('PolicyStatus', () {
    test('parses every serialized status', () {
      expect(PolicyStatus.fromString('active'), PolicyStatus.active);
      expect(PolicyStatus.fromString('lapsed'), PolicyStatus.lapsed);
      expect(PolicyStatus.fromString('surrendered'), PolicyStatus.surrendered);
    });

    test('returns lowercase serialized values', () {
      expect(PolicyStatus.active.value, 'active');
      expect(PolicyStatus.lapsed.value, 'lapsed');
      expect(PolicyStatus.surrendered.value, 'surrendered');
    });

    test('returns localization keys', () {
      expect(PolicyStatus.active.labelKey, 'policy_status_active');
      expect(PolicyStatus.lapsed.labelKey, 'policy_status_lapsed');
      expect(PolicyStatus.surrendered.labelKey, 'policy_status_surrendered');
    });

    test('rejects an unknown serialized status', () {
      expect(() => PolicyStatus.fromString('unknown'), throwsArgumentError);
    });
  });

  group('Policy constructor', () {
    test('constructs a valid policy with a persisted UUID', () {
      expect(samplePolicy.id, '123e4567-e89b-42d3-a456-426614174000');
      expect(samplePolicy.clientId, 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d');
    });

    test('allows a null id before persistence', () {
      expect(samplePolicy.copyWith(id: null).id, isNull);
    });

    test('rejects an invalid UUID id with a debug assertion', () {
      // Assertions are active in the Flutter test debug configuration.
      expect(
        () => Policy(
          id: 'not-a-uuid',
          clientId: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
          policyNo: 'POL-2026-0001',
          company: 'Example Insurance Co.',
          effectiveDate: DateTime.utc(2026, 9),
          firstPremiumDate: DateTime.utc(2026, 9, 2),
          currency: 'HKD',
          status: PolicyStatus.active,
          createdAt: null,
          updatedAt: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a currency that is not three uppercase letters', () {
      expect(
        () => samplePolicy.copyWith(currency: 'usd'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an empty client id', () {
      expect(
        () => samplePolicy.copyWith(clientId: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an effective date after the first premium date', () {
      expect(
        () => samplePolicy.copyWith(effectiveDate: DateTime.utc(2026, 9, 3)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('allows an effective date equal to the first premium date', () {
      final date = DateTime.utc(2026, 9, 1, 12);

      expect(
        samplePolicy
            .copyWith(effectiveDate: date, firstPremiumDate: date)
            .effectiveDate,
        date,
      );
    });
  });

  group('Policy.copyWith', () {
    test('returns an equal policy when no values are provided', () {
      expect(samplePolicy.copyWith(), samplePolicy);
    });

    test('updates one field and preserves the others', () {
      final updated = samplePolicy.copyWith(status: PolicyStatus.lapsed);

      expect(updated.status, PolicyStatus.lapsed);
      expect(updated.copyWith(status: samplePolicy.status), samplePolicy);
    });

    test('clears nullable notes when null is explicitly provided', () {
      expect(samplePolicy.copyWith(notes: null).notes, isNull);
    });

    test('sets archivedAt when archiving the policy', () {
      final archivedAt = DateTime.utc(2026, 11);

      expect(
        samplePolicy.copyWith(archivedAt: archivedAt).archivedAt,
        archivedAt,
      );
    });

    test('can clear archivedAt and lifecycle timestamps', () {
      final updated = samplePolicy.copyWith(
        archivedAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(updated.archivedAt, isNull);
      expect(updated.createdAt, isNull);
      expect(updated.updatedAt, isNull);
    });

    test('can clear a persisted id', () {
      expect(samplePolicy.copyWith(id: null).id, isNull);
    });
  });

  group('Policy.toJson / fromJson', () {
    test('round-trips through JSON while preserving the policy', () {
      expect(Policy.fromJson(samplePolicy.toJson()), samplePolicy);
    });

    test('serializes all policy fields', () {
      expect(samplePolicy.toJson(), <String, Object?>{
        'id': '123e4567-e89b-42d3-a456-426614174000',
        'clientId': 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        'policyNo': 'POL-2026-0001',
        'company': 'Example Insurance Co.',
        'effectiveDate': '2026-09-01T12:00:00.000Z',
        'firstPremiumDate': '2026-09-02T12:00:00.000Z',
        'currency': 'HKD',
        'status': 'active',
        'notes': 'Synthetic test notes',
        'createdAt': '2026-08-01T00:00:00.000Z',
        'updatedAt': '2026-08-02T00:00:00.000Z',
        'archivedAt': '2026-10-01T00:00:00.000Z',
      });
    });

    test('round-trips null nullable fields', () {
      final policy = Policy(
        clientId: samplePolicy.clientId,
        policyNo: samplePolicy.policyNo,
        company: samplePolicy.company,
        effectiveDate: samplePolicy.effectiveDate,
        firstPremiumDate: samplePolicy.firstPremiumDate,
        currency: samplePolicy.currency,
        status: samplePolicy.status,
        createdAt: null,
        updatedAt: null,
      );

      expect(Policy.fromJson(policy.toJson()), policy);
      expect(policy.notes, isNull);
      expect(policy.archivedAt, isNull);
    });

    test('serializes DateTime values in UTC ISO 8601 form', () {
      final json = samplePolicy.toJson();

      expect(json['effectiveDate'], '2026-09-01T12:00:00.000Z');
      expect(json['effectiveDate'], endsWith('Z'));
    });

    test('parses dates into local time while preserving the instant', () {
      final restored = Policy.fromJson(samplePolicy.toJson());
      final expected = DateTime.utc(2026, 9, 1, 12);

      expect(restored.effectiveDate.isAtSameMomentAs(expected), isTrue);
      expect(
        restored.firstPremiumDate.isAtSameMomentAs(
          DateTime.utc(2026, 9, 2, 12),
        ),
        isTrue,
      );
      expect(restored.effectiveDate.isUtc, isFalse);
    });

    test('rejects a missing required field', () {
      expect(
        () => Policy.fromJson(<String, Object?>{
          'clientId': samplePolicy.clientId,
          'policyNo': samplePolicy.policyNo,
        }),
        throwsArgumentError,
      );
    });

    test('rejects an unknown status value', () {
      final json = samplePolicy.toJson()..['status'] = 'unknown';

      expect(() => Policy.fromJson(json), throwsArgumentError);
    });

    test('rejects an invalid date string', () {
      final json = samplePolicy.toJson()..['effectiveDate'] = 'not-a-date';

      expect(() => Policy.fromJson(json), throwsArgumentError);
    });
  });

  group('Policy equality', () {
    test('equal policies have matching hash codes', () {
      final restored = Policy.fromJson(samplePolicy.toJson());

      expect(restored, samplePolicy);
      expect(restored.hashCode, samplePolicy.hashCode);
    });

    test('policies with different fields are not equal', () {
      expect(samplePolicy.copyWith(id: null), isNot(samplePolicy));
      expect(
        samplePolicy.copyWith(clientId: 'different-client'),
        isNot(samplePolicy),
      );
      expect(samplePolicy.copyWith(policyNo: 'POL-OTHER'), isNot(samplePolicy));
      expect(samplePolicy.copyWith(company: 'Other Co.'), isNot(samplePolicy));
      expect(
        samplePolicy.copyWith(effectiveDate: DateTime.utc(2026, 9)),
        isNot(samplePolicy),
      );
      expect(
        samplePolicy.copyWith(firstPremiumDate: DateTime.utc(2026, 9, 4)),
        isNot(samplePolicy),
      );
      expect(samplePolicy.copyWith(currency: 'USD'), isNot(samplePolicy));
      expect(
        samplePolicy.copyWith(status: PolicyStatus.surrendered),
        isNot(samplePolicy),
      );
      expect(samplePolicy.copyWith(notes: null), isNot(samplePolicy));
      expect(samplePolicy.copyWith(createdAt: null), isNot(samplePolicy));
      expect(samplePolicy.copyWith(updatedAt: null), isNot(samplePolicy));
      expect(samplePolicy.copyWith(archivedAt: null), isNot(samplePolicy));
    });
  });

  group('Policy.toString', () {
    test('does not include company or notes', () {
      final summary = samplePolicy.toString();

      expect(summary, contains(samplePolicy.id!));
      expect(summary, contains('POL-2026-0001'));
      expect(summary, contains('active'));
      expect(summary, isNot(contains('Example Insurance Co.')));
      expect(summary, isNot(contains('Synthetic test notes')));
    });
  });
}
