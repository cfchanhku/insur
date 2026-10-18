/// Defines persistence operations for non-secret application settings.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/settings/models/app_settings.dart';

/// Loads and saves local user preferences.
class SettingsRepository {
  /// Loads the saved settings or approved initial defaults.
  Future<AppSettings> load() async {
    throw UnimplementedError('SettingsRepository.load');
  }

  /// Persists [settings] transactionally.
  Future<void> save(AppSettings settings) async {
    throw UnimplementedError('SettingsRepository.save');
  }
}
