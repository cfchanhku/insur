import 'package:flutter_test/flutter_test.dart';
import 'package:insur/features/clients/models/client.dart';
import 'package:insur/features/clients/models/client_enums.dart';

void main() {
  late Client sampleClient;

  setUp(() {
    sampleClient = Client(
      id: '123e4567-e89b-42d3-a456-426614174000',
      role: ClientRole.holder,
      name: 'Synthetic Client',
      gender: Gender.other,
      dob: DateTime.utc(1990, 5, 20),
      phone: '+85200000000',
      email: 'synthetic@example.test',
      notes: 'Synthetic notes',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025, 1, 2),
      archivedAt: DateTime.utc(2025, 1, 3),
    );
  });

  group('ClientRole', () {
    test('parses holder from its serialized value', () {
      expect(ClientRole.fromString('holder'), ClientRole.holder);
    });

    test('parses insured from its serialized value', () {
      expect(ClientRole.fromString('insured'), ClientRole.insured);
    });

    test('returns lowercase serialized values', () {
      expect(ClientRole.holder.value, 'holder');
      expect(ClientRole.insured.value, 'insured');
    });

    test('returns localization keys', () {
      expect(ClientRole.holder.labelKey, 'client_role_holder');
      expect(ClientRole.insured.labelKey, 'client_role_insured');
    });

    test('rejects unknown serialized values', () {
      expect(() => ClientRole.fromString('unknown'), throwsArgumentError);
    });
  });

  group('Gender', () {
    test('parses each gender from its serialized value', () {
      expect(Gender.fromString('male'), Gender.male);
      expect(Gender.fromString('female'), Gender.female);
      expect(Gender.fromString('other'), Gender.other);
    });

    test('returns lowercase serialized values', () {
      expect(Gender.male.value, 'male');
      expect(Gender.female.value, 'female');
      expect(Gender.other.value, 'other');
    });

    test('returns localization keys', () {
      expect(Gender.male.labelKey, 'gender_male');
      expect(Gender.female.labelKey, 'gender_female');
      expect(Gender.other.labelKey, 'gender_other');
    });

    test('rejects unknown serialized values', () {
      expect(() => Gender.fromString('unknown'), throwsArgumentError);
    });
  });

  group('Client constructor', () {
    test('constructs a new client with a null id', () {
      final client = Client(
        role: ClientRole.insured,
        name: 'Synthetic Client',
        gender: Gender.female,
        dob: DateTime(1995, 6, 7),
        phone: null,
        email: null,
        createdAt: null,
        updatedAt: null,
        archivedAt: null,
      );

      expect(client.id, isNull);
      expect(client.archivedAt, isNull);
    });

    test('accepts a valid UUID v4 id', () {
      expect(sampleClient.id, '123e4567-e89b-42d3-a456-426614174000');
    });

    test('rejects an invalid UUID id with a debug assertion', () {
      // Assertions are active in the Flutter test debug configuration.
      expect(
        () => Client(
          id: 'not-a-uuid',
          role: ClientRole.holder,
          name: 'Synthetic Client',
          gender: Gender.other,
          dob: DateTime.utc(1990),
          phone: null,
          email: null,
          createdAt: null,
          updatedAt: null,
          archivedAt: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('allows every nullable field to be null', () {
      final client = Client(
        role: ClientRole.holder,
        name: 'Synthetic Client',
        gender: Gender.other,
        dob: DateTime.utc(1990),
        phone: null,
        email: null,
        createdAt: null,
        updatedAt: null,
        archivedAt: null,
      );

      expect(client.id, isNull);
      expect(client.phone, isNull);
      expect(client.email, isNull);
      expect(client.notes, isNull);
      expect(client.createdAt, isNull);
      expect(client.updatedAt, isNull);
      expect(client.archivedAt, isNull);
    });

    test('stores populated optional fields', () {
      expect(sampleClient.phone, '+85200000000');
      expect(sampleClient.email, 'synthetic@example.test');
      expect(sampleClient.notes, 'Synthetic notes');
      expect(sampleClient.createdAt, isNotNull);
      expect(sampleClient.updatedAt, isNotNull);
      expect(sampleClient.archivedAt, isNotNull);
    });
  });

  group('Client.copyWith', () {
    test('returns an equal client when no values are provided', () {
      expect(sampleClient.copyWith(), sampleClient);
    });

    test('updates one field and preserves all other fields', () {
      final updated = sampleClient.copyWith(name: 'Another Synthetic');

      expect(updated.name, 'Another Synthetic');
      expect(updated.copyWith(name: sampleClient.name), sampleClient);
    });

    test('clears a nullable field when null is explicitly provided', () {
      final updated = sampleClient.copyWith(phone: null);

      expect(updated.phone, isNull);
      expect(updated.email, sampleClient.email);
      expect(updated.id, sampleClient.id);
    });

    test('can clear the id and lifecycle timestamps', () {
      final updated = sampleClient.copyWith(
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

  group('Client.toJson / fromJson', () {
    test('round-trips with all fields populated', () {
      expect(Client.fromJson(sampleClient.toJson()), sampleClient);
    });

    test('serializes every model field', () {
      expect(sampleClient.toJson(), <String, Object?>{
        'id': '123e4567-e89b-42d3-a456-426614174000',
        'role': 'holder',
        'name': 'Synthetic Client',
        'gender': 'other',
        'dob': '1990-05-20T00:00:00.000Z',
        'phone': '+85200000000',
        'email': 'synthetic@example.test',
        'notes': 'Synthetic notes',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-02T00:00:00.000Z',
        'archivedAt': '2025-01-03T00:00:00.000Z',
      });
    });

    test('round-trips null optional fields', () {
      final client = Client(
        role: ClientRole.insured,
        name: 'Synthetic Client',
        gender: Gender.male,
        dob: DateTime.utc(2000),
        phone: null,
        email: null,
        createdAt: null,
        updatedAt: null,
        archivedAt: null,
      );

      expect(Client.fromJson(client.toJson()), client);
    });

    test('allows optional id and notes keys to be omitted', () {
      final json = sampleClient.toJson()
        ..remove('id')
        ..remove('notes');

      expect(
        Client.fromJson(json),
        sampleClient.copyWith(id: null, notes: null),
      );
    });

    test('serializes UTC DateTime values as ISO 8601 with a Z suffix', () {
      expect(sampleClient.toJson()['dob'], '1990-05-20T00:00:00.000Z');
      expect(Client.fromJson(sampleClient.toJson()).dob.isUtc, isTrue);
    });

    test('round-trips a local DateTime without changing its timezone form', () {
      final client = Client(
        role: ClientRole.holder,
        name: 'Synthetic Client',
        gender: Gender.other,
        dob: DateTime(1990, 5, 20),
        phone: null,
        email: null,
        createdAt: null,
        updatedAt: null,
        archivedAt: null,
      );

      final serializedDob = client.toJson()['dob'];
      final restored = Client.fromJson(client.toJson());

      expect(serializedDob, '1990-05-20T00:00:00.000');
      expect(restored.dob.isUtc, isFalse);
      expect(restored.dob, client.dob);
    });

    test('rejects a missing required field', () {
      expect(
        () => Client.fromJson(<String, Object?>{
          'role': 'holder',
          'gender': 'other',
          'dob': '1990-05-20T00:00:00.000Z',
        }),
        throwsArgumentError,
      );
    });

    test('rejects a missing required nullable field', () {
      final json = sampleClient.toJson()..remove('phone');

      expect(() => Client.fromJson(json), throwsArgumentError);
    });

    test('rejects an unknown enum value', () {
      expect(
        () => Client.fromJson(<String, Object?>{
          'role': 'unknown',
          'name': 'Synthetic Client',
          'gender': 'other',
          'dob': '1990-05-20T00:00:00.000Z',
        }),
        throwsArgumentError,
      );
    });

    test('rejects a malformed required date', () {
      expect(
        () => Client.fromJson(<String, Object?>{
          'role': 'holder',
          'name': 'Synthetic Client',
          'gender': 'other',
          'dob': 'not-a-date',
        }),
        throwsArgumentError,
      );
    });
  });

  group('Client equality', () {
    test('equal clients have matching hash codes', () {
      final duplicate = Client.fromJson(sampleClient.toJson());

      expect(duplicate, sampleClient);
      expect(duplicate.hashCode, sampleClient.hashCode);
    });

    test('clients with a different field are not equal', () {
      expect(sampleClient.copyWith(id: null), isNot(sampleClient));
      expect(
          sampleClient.copyWith(role: ClientRole.insured), isNot(sampleClient));
      expect(sampleClient.copyWith(name: 'Different'), isNot(sampleClient));
      expect(sampleClient.copyWith(gender: Gender.female), isNot(sampleClient));
      expect(
        sampleClient.copyWith(dob: DateTime.utc(1991)),
        isNot(sampleClient),
      );
      expect(sampleClient.copyWith(phone: null), isNot(sampleClient));
      expect(sampleClient.copyWith(email: null), isNot(sampleClient));
      expect(sampleClient.copyWith(notes: null), isNot(sampleClient));
      expect(sampleClient.copyWith(createdAt: null), isNot(sampleClient));
      expect(sampleClient.copyWith(updatedAt: null), isNot(sampleClient));
      expect(sampleClient.copyWith(archivedAt: null), isNot(sampleClient));
    });
  });

  group('Client.toString', () {
    test('does not include personally identifying or private fields', () {
      final client = sampleClient.copyWith(
        name: 'John Doe',
        phone: '+85212345678',
        email: 'john@example.com',
        notes: 'sensitive',
      );
      final summary = client.toString();

      expect(summary, contains('123e4567-e89b-42d3-a456-426614174000'));
      expect(summary, contains('holder'));
      expect(summary, contains('archived: true'));
      expect(summary, isNot(contains('John')));
      expect(summary, isNot(contains('12345678')));
      expect(summary, isNot(contains('john@')));
      expect(summary, isNot(contains('sensitive')));
    });
  });
}
