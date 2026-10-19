/// Client role labels are represented by ARB keys, not localized enum values.
enum ClientRole {
  /// ARB labels are looked up by key so localization stays outside the model.
  holder,

  /// ARB labels are looked up by key so localization stays outside the model.
  insured;

  /// Returns the localization key used to resolve this role's label.
  String get labelKey => switch (this) {
        ClientRole.holder => 'client_role_holder',
        ClientRole.insured => 'client_role_insured',
      };

  /// Returns the stable lowercase representation used in serialized data.
  String get value => name;

  /// Parses a serialized role or throws if it is not recognized.
  static ClientRole fromString(String value) {
    return switch (value) {
      'holder' => ClientRole.holder,
      'insured' => ClientRole.insured,
      _ => throw ArgumentError('Unknown client role'),
    };
  }
}

/// Gender labels are represented by ARB keys, not localized enum values.
enum Gender {
  /// ARB labels are looked up by key so localization stays outside the model.
  male,

  /// ARB labels are looked up by key so localization stays outside the model.
  female,

  /// ARB labels are looked up by key so localization stays outside the model.
  other;

  /// Returns the localization key used to resolve this gender's label.
  String get labelKey => switch (this) {
        Gender.male => 'gender_male',
        Gender.female => 'gender_female',
        Gender.other => 'gender_other',
      };

  /// Returns the stable lowercase representation used in serialized data.
  String get value => name;

  /// Parses a serialized gender or throws if it is not recognized.
  static Gender fromString(String value) {
    return switch (value) {
      'male' => Gender.male,
      'female' => Gender.female,
      'other' => Gender.other,
      _ => throw ArgumentError('Unknown gender'),
    };
  }
}
