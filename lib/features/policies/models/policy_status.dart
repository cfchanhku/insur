/// Policy status labels are represented by ARB keys, not localized enum values.
enum PolicyStatus {
  /// ARB labels are looked up by key so localization stays outside the model.
  active,

  /// ARB labels are looked up by key so localization stays outside the model.
  lapsed,

  /// ARB labels are looked up by key so localization stays outside the model.
  surrendered;

  /// Returns the localization key used to resolve this status label.
  String get labelKey => switch (this) {
    PolicyStatus.active => 'policy_status_active',
    PolicyStatus.lapsed => 'policy_status_lapsed',
    PolicyStatus.surrendered => 'policy_status_surrendered',
  };

  /// Returns the stable lowercase representation used in serialized data.
  String get value => name;

  /// Parses a serialized status or throws if it is not recognized.
  static PolicyStatus fromString(String value) {
    return switch (value) {
      'active' => PolicyStatus.active,
      'lapsed' => PolicyStatus.lapsed,
      'surrendered' => PolicyStatus.surrendered,
      _ => throw ArgumentError('Unknown policy status'),
    };
  }
}
