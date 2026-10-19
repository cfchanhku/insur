/// Stable categories matching the insurance form's six plan types
/// (壽險/危疾/住院/意外/儲蓄/其他).
///
/// [labelKey] identifies the ARB key the UI uses to look up a localized label.
enum PlanCategory {
  life,
  ci,
  hospital,
  accident,
  savings,
  other;

  /// Stable serialized identifier.
  String get value => switch (this) {
    PlanCategory.life => 'life',
    PlanCategory.ci => 'ci',
    PlanCategory.hospital => 'hospital',
    PlanCategory.accident => 'accident',
    PlanCategory.savings => 'savings',
    PlanCategory.other => 'other',
  };

  /// ARB key used by the UI for the localized category label.
  String get labelKey => 'plan_category_$value';

  /// Parses a serialized category identifier.
  static PlanCategory fromString(String value) {
    return switch (value) {
      'life' => PlanCategory.life,
      'ci' => PlanCategory.ci,
      'hospital' => PlanCategory.hospital,
      'accident' => PlanCategory.accident,
      'savings' => PlanCategory.savings,
      'other' => PlanCategory.other,
      _ => throw ArgumentError('Unknown plan category'),
    };
  }
}
