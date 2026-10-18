/// Declares providers for client data and operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/client_repository.dart';

/// Provides the client repository.
final Provider<ClientRepository> clientRepositoryProvider =
    Provider<ClientRepository>((ref) {
  throw UnimplementedError('clientRepositoryProvider');
});
