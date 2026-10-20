import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory secure storage for tests that need deterministic storage state.
class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = <String, String>{};

  /// Key that should cause the corresponding write to fail.
  String? failWriteKey;

  /// An immutable snapshot of stored values.
  Map<String, String> get rawData => Map<String, String>.unmodifiable(_data);

  /// Seeds values synchronously for legacy-storage migration scenarios.
  void seed(Map<String, String> values) => _data.addAll(values);

  /// Whether [key] is present in storage.
  bool hasKey(String key) => _data.containsKey(key);

  /// Removes all in-memory values.
  void clear() => _data.clear();

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (key == failWriteKey) {
      throw StateError('Synthetic secure-storage write failure');
    }
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => rawData;
}
