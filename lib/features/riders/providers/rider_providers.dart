/// Declares providers for rider data and operations.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/rider_repository.dart';

/// Provides the rider repository.
final Provider<RiderRepository> riderRepositoryProvider =
    Provider<RiderRepository>((ref) {
  throw UnimplementedError('riderRepositoryProvider');
});
