/// Declares providers for authentication state and operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/auth_repository.dart';

/// Provides the authentication repository.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider');
});
