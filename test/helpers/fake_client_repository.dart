import 'package:insur/core/database/repositories/client_repository.dart';
import 'package:insur/features/clients/models/client.dart';

/// In-memory client repository for tests that do not open the encrypted DB.
class FakeClientRepository implements ClientRepository {
  FakeClientRepository([List<Client> clients = const <Client>[]])
    : _clients = List<Client>.of(clients);

  final List<Client> _clients;
  int _nextId = 1;

  @override
  Future<Client> save(Client client) async {
    final id =
        client.id ??
        '00000000-0000-4000-8000-${(_nextId++).toString().padLeft(12, '0')}';
    final saved = client.copyWith(
      id: id,
      createdAt: client.createdAt ?? DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final index = _clients.indexWhere((Client entry) => entry.id == id);
    if (index == -1) {
      _clients.add(saved);
    } else {
      _clients[index] = saved;
    }
    return saved;
  }

  @override
  Future<Client?> findById(String id) async {
    for (final client in _clients) {
      if (client.id == id) {
        return client;
      }
    }
    return null;
  }

  @override
  Future<List<Client>> findAll({bool includeArchived = false}) async => _clients
      .where((Client client) => includeArchived || client.archivedAt == null)
      .toList(growable: false);

  @override
  Future<void> archive(String id) async {
    final index = _clients.indexWhere((Client client) => client.id == id);
    if (index >= 0) {
      _clients[index] = _clients[index].copyWith(
        archivedAt: DateTime.utc(2026),
      );
    }
  }

  @override
  Future<void> restore(String id) async {
    final index = _clients.indexWhere((Client client) => client.id == id);
    if (index >= 0) {
      _clients[index] = _clients[index].copyWith(archivedAt: null);
    }
  }

  @override
  Future<void> delete(String id) async {
    _clients.removeWhere((Client client) => client.id == id);
  }
}
