/// Declares providers for application settings.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/settings_repository.dart';

/// Provides the settings repository.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) {
      throw UnimplementedError('settingsRepositoryProvider');
    });
