// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Insurance Policy Manager';

  @override
  String get app_tagline =>
      'Your insurance information, securely on this device.';

  @override
  String get action_next => 'Next';

  @override
  String get action_back => 'Back';

  @override
  String get action_cancel => 'Cancel';

  @override
  String get action_save => 'Save';

  @override
  String get client_role_holder => 'Policy holder';

  @override
  String get client_role_insured => 'Insured';

  @override
  String get gender_male => 'Male';

  @override
  String get gender_female => 'Female';

  @override
  String get gender_other => 'Other';
}
