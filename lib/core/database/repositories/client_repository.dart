/// Defines persistence operations for client records.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/clients/models/client.dart';

/// Reads and writes client records through the encrypted database.
class ClientRepository {
  /// Returns all active clients.
  Future<List<Client>> findAll() async {
    throw UnimplementedError('ClientRepository.findAll');
  }

  /// Finds a client by UUID.
  Future<Client?> findById(String id) async {
    throw UnimplementedError('ClientRepository.findById');
  }

  /// Persists a new or updated client.
  Future<void> save(Client client) async {
    throw UnimplementedError('ClientRepository.save');
  }

  /// Archives a client without physically deleting its record.
  Future<void> archive(String id) async {
    throw UnimplementedError('ClientRepository.archive');
  }
}
