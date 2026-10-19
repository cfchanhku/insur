import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/database.dart';
import 'package:insur/core/database/repositories/config_repository.dart';

import 'database_test_helper.dart';

void main() {
  late AppDatabase database;
  late ConfigRepository repository;

  setUp(() async {
    database = await createTestDatabase();
    repository = ConfigRepository(db: database);
  });

  tearDown(() => tearDownTestDatabase(database));

  test('returns null for a missing setting', () async {
    expect(await repository.get('settings.language'), isNull);
  });

  test('sets and reads a setting with a UTC timestamp', () async {
    await repository.set('settings.language', 'zh-Hant');

    expect(await repository.get('settings.language'), 'zh-Hant');
    final rows = await database.query('app_config');
    final updatedAt = DateTime.parse(rows.single['updated_at']! as String);
    expect(updatedAt.isUtc, isTrue);
  });

  test('replaces a setting without creating duplicate keys', () async {
    await repository.set('settings.theme_mode', 'light');
    await repository.set('settings.theme_mode', 'dark');

    expect(await repository.getAll(), <String, String>{
      'settings.theme_mode': 'dark',
    });
  });

  test('deletes only the selected setting', () async {
    await repository.set('settings.language', 'en');
    await repository.set('settings.theme_mode', 'dark');

    await repository.delete('settings.language');

    expect(await repository.get('settings.language'), isNull);
    expect(await repository.get('settings.theme_mode'), 'dark');
  });

  test('clears all settings', () async {
    await repository.set('settings.language', 'en');
    await repository.set('settings.theme_mode', 'dark');

    await repository.clear();

    expect(await repository.getAll(), isEmpty);
  });
}
