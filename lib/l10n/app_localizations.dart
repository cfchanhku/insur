import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy Manager'**
  String get app_title;

  /// No description provided for @app_tagline.
  ///
  /// In en, this message translates to:
  /// **'Your insurance information, securely on this device.'**
  String get app_tagline;

  /// No description provided for @action_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get action_next;

  /// No description provided for @action_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get action_back;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get action_save;

  /// No description provided for @client_role_holder.
  ///
  /// In en, this message translates to:
  /// **'Policy holder'**
  String get client_role_holder;

  /// No description provided for @client_role_insured.
  ///
  /// In en, this message translates to:
  /// **'Insured'**
  String get client_role_insured;

  /// No description provided for @gender_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get gender_male;

  /// No description provided for @gender_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get gender_female;

  /// No description provided for @gender_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get gender_other;

  /// No description provided for @policy_status_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get policy_status_active;

  /// No description provided for @policy_status_lapsed.
  ///
  /// In en, this message translates to:
  /// **'Lapsed'**
  String get policy_status_lapsed;

  /// No description provided for @policy_status_surrendered.
  ///
  /// In en, this message translates to:
  /// **'Surrendered'**
  String get policy_status_surrendered;

  /// No description provided for @plan_category_life.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get plan_category_life;

  /// No description provided for @plan_category_ci.
  ///
  /// In en, this message translates to:
  /// **'Critical Illness'**
  String get plan_category_ci;

  /// No description provided for @plan_category_hospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get plan_category_hospital;

  /// No description provided for @plan_category_accident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get plan_category_accident;

  /// No description provided for @plan_category_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get plan_category_savings;

  /// No description provided for @plan_category_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get plan_category_other;

  /// No description provided for @splash_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splash_loading;

  /// No description provided for @setup_title.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup_title;

  /// No description provided for @setup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a passphrase to protect your data'**
  String get setup_subtitle;

  /// No description provided for @setup_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get setup_passphrase;

  /// No description provided for @setup_confirm_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Confirm passphrase'**
  String get setup_confirm_passphrase;

  /// No description provided for @setup_passphrase_hint.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters'**
  String get setup_passphrase_hint;

  /// No description provided for @setup_passphrase_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passphrases do not match'**
  String get setup_passphrase_mismatch;

  /// No description provided for @setup_passphrase_too_short.
  ///
  /// In en, this message translates to:
  /// **'Passphrase must be at least 12 characters'**
  String get setup_passphrase_too_short;

  /// No description provided for @setup_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get setup_create;

  /// No description provided for @setup_creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get setup_creating;

  /// No description provided for @setup_error.
  ///
  /// In en, this message translates to:
  /// **'Setup could not be completed. Please try again.'**
  String get setup_error;

  /// No description provided for @recovery_key_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Your Recovery Key'**
  String get recovery_key_dialog_title;

  /// No description provided for @recovery_key_dialog_body.
  ///
  /// In en, this message translates to:
  /// **'This is the ONLY way to recover your data if you forget your passphrase.\n\nPrint it. Store it offline. Never share it.\n\nWe cannot recover your data without it.'**
  String get recovery_key_dialog_body;

  /// No description provided for @recovery_key_dialog_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get recovery_key_dialog_copy;

  /// No description provided for @recovery_key_copied.
  ///
  /// In en, this message translates to:
  /// **'Recovery key copied to clipboard.'**
  String get recovery_key_copied;

  /// No description provided for @recovery_key_dialog_confirm.
  ///
  /// In en, this message translates to:
  /// **'I have printed and stored it'**
  String get recovery_key_dialog_confirm;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_title;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your passphrase to unlock'**
  String get login_subtitle;

  /// No description provided for @login_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get login_passphrase;

  /// No description provided for @login_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_sign_in;

  /// No description provided for @login_signing_in.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get login_signing_in;

  /// No description provided for @login_biometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometric'**
  String get login_biometric;

  /// No description provided for @login_error.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passphrase. {attempts} attempts remaining.'**
  String login_error(int attempts);

  /// No description provided for @login_forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot passphrase?'**
  String get login_forgot;

  /// No description provided for @lock_title.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lock_title;

  /// No description provided for @lock_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your passphrase to unlock'**
  String get lock_subtitle;

  /// No description provided for @lock_unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lock_unlock;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get home_welcome;

  /// No description provided for @home_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Home screen coming soon'**
  String get home_coming_soon;

  /// No description provided for @home_state.
  ///
  /// In en, this message translates to:
  /// **'State: {state}'**
  String home_state(String state);

  /// No description provided for @home_lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get home_lock;

  /// No description provided for @home_logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get home_logout;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get error_generic;

  /// No description provided for @recovery_title.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recovery_title;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get coming_soon;

  /// No description provided for @key_state_uninitialized.
  ///
  /// In en, this message translates to:
  /// **'not set up'**
  String get key_state_uninitialized;

  /// No description provided for @key_state_locked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get key_state_locked;

  /// No description provided for @key_state_unlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get key_state_unlocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
