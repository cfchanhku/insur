import 'dart:typed_data';

import 'package:insur/core/database/database.dart';

/// Opens an isolated SQLCipher in-memory database using synthetic key bytes.
Future<AppDatabase> createTestDatabase() {
  final testKey = Uint8List.fromList(List<int>.filled(32, 0x42));
  return AppDatabase.openInMemory(dbKey: testKey);
}

/// Closes [database] after a test.
Future<void> tearDownTestDatabase(AppDatabase database) => database.close();
