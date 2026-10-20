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

  /// No description provided for @policy_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get policy_detail_title;

  /// No description provided for @policy_info_section.
  ///
  /// In en, this message translates to:
  /// **'Policy information'**
  String get policy_info_section;

  /// No description provided for @policy_company.
  ///
  /// In en, this message translates to:
  /// **'Insurer'**
  String get policy_company;

  /// No description provided for @policy_no.
  ///
  /// In en, this message translates to:
  /// **'Policy number'**
  String get policy_no;

  /// No description provided for @policy_card_summary.
  ///
  /// In en, this message translates to:
  /// **'{company} · {effectiveDate} · {status}'**
  String policy_card_summary(
    String company,
    String effectiveDate,
    String status,
  );

  /// No description provided for @policy_effective_date.
  ///
  /// In en, this message translates to:
  /// **'Effective date'**
  String get policy_effective_date;

  /// No description provided for @policy_first_premium_date.
  ///
  /// In en, this message translates to:
  /// **'First premium date'**
  String get policy_first_premium_date;

  /// No description provided for @policy_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get policy_currency;

  /// No description provided for @policy_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get policy_status;

  /// No description provided for @policy_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get policy_notes;

  /// No description provided for @policy_plans_section.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get policy_plans_section;

  /// No description provided for @policy_add_plan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get policy_add_plan;

  /// No description provided for @policy_no_plans.
  ///
  /// In en, this message translates to:
  /// **'No plans yet'**
  String get policy_no_plans;

  /// No description provided for @policy_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get policy_edit;

  /// No description provided for @policy_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get policy_archive;

  /// No description provided for @policy_archive_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Archive policy?'**
  String get policy_archive_confirm_title;

  /// No description provided for @policy_archive_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'The policy will be hidden. You can restore it from the Archive.'**
  String get policy_archive_confirm_body;

  /// No description provided for @policy_archive_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get policy_archive_confirm_action;

  /// No description provided for @policy_archived_snack.
  ///
  /// In en, this message translates to:
  /// **'Policy archived'**
  String get policy_archived_snack;

  /// No description provided for @policy_form_title_new.
  ///
  /// In en, this message translates to:
  /// **'New policy'**
  String get policy_form_title_new;

  /// No description provided for @policy_form_title_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit policy'**
  String get policy_form_title_edit;

  /// No description provided for @policy_form_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get policy_form_save;

  /// No description provided for @policy_form_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get policy_form_saving;

  /// No description provided for @policy_form_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get policy_form_cancel;

  /// No description provided for @policy_form_saved.
  ///
  /// In en, this message translates to:
  /// **'Policy saved'**
  String get policy_form_saved;

  /// No description provided for @policy_form_error_company_required.
  ///
  /// In en, this message translates to:
  /// **'Insurer is required'**
  String get policy_form_error_company_required;

  /// No description provided for @policy_form_error_policy_no_required.
  ///
  /// In en, this message translates to:
  /// **'Policy number is required'**
  String get policy_form_error_policy_no_required;

  /// No description provided for @policy_form_error_currency_invalid.
  ///
  /// In en, this message translates to:
  /// **'Currency must be 3 uppercase letters'**
  String get policy_form_error_currency_invalid;

  /// No description provided for @policy_form_error_dates.
  ///
  /// In en, this message translates to:
  /// **'First premium date must be on or after effective date'**
  String get policy_form_error_dates;

  /// No description provided for @policy_form_error_save.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {message}'**
  String policy_form_error_save(String message);

  /// No description provided for @policy_not_found.
  ///
  /// In en, this message translates to:
  /// **'Policy not found'**
  String get policy_not_found;

  /// No description provided for @plan_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan_detail_title;

  /// No description provided for @plan_card_summary.
  ///
  /// In en, this message translates to:
  /// **'{category} · {coverage}'**
  String plan_card_summary(String category, String coverage);

  /// No description provided for @plan_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get plan_category;

  /// No description provided for @plan_name.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get plan_name;

  /// No description provided for @plan_coverage_amount.
  ///
  /// In en, this message translates to:
  /// **'Coverage amount'**
  String get plan_coverage_amount;

  /// No description provided for @plan_payment_term.
  ///
  /// In en, this message translates to:
  /// **'Payment term'**
  String get plan_payment_term;

  /// No description provided for @plan_coverage_period.
  ///
  /// In en, this message translates to:
  /// **'Coverage period'**
  String get plan_coverage_period;

  /// No description provided for @plan_deductible.
  ///
  /// In en, this message translates to:
  /// **'Deductible'**
  String get plan_deductible;

  /// No description provided for @plan_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get plan_notes;

  /// No description provided for @plan_add_rider.
  ///
  /// In en, this message translates to:
  /// **'Add rider'**
  String get plan_add_rider;

  /// No description provided for @plan_riders_section.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get plan_riders_section;

  /// No description provided for @plan_no_riders.
  ///
  /// In en, this message translates to:
  /// **'No riders'**
  String get plan_no_riders;

  /// No description provided for @plan_remove_rider.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get plan_remove_rider;

  /// No description provided for @plan_archive_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Archive plan?'**
  String get plan_archive_confirm_title;

  /// No description provided for @plan_archive_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'The plan will be hidden. You can restore it from the Archive.'**
  String get plan_archive_confirm_body;

  /// No description provided for @plan_archive_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get plan_archive_confirm_action;

  /// No description provided for @plan_archived_snack.
  ///
  /// In en, this message translates to:
  /// **'Plan archived'**
  String get plan_archived_snack;

  /// No description provided for @accessibility_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get accessibility_delete;

  /// No description provided for @accessibility_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get accessibility_restore;

  /// No description provided for @plan_form_title_new.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get plan_form_title_new;

  /// No description provided for @plan_form_title_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get plan_form_title_edit;

  /// No description provided for @plan_form_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get plan_form_save;

  /// No description provided for @plan_form_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get plan_form_saving;

  /// No description provided for @plan_form_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get plan_form_cancel;

  /// No description provided for @plan_form_saved.
  ///
  /// In en, this message translates to:
  /// **'Plan saved'**
  String get plan_form_saved;

  /// No description provided for @plan_form_error_category_required.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get plan_form_error_category_required;

  /// No description provided for @plan_form_error_coverage_invalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be zero or greater'**
  String get plan_form_error_coverage_invalid;

  /// No description provided for @plan_form_error_name_required.
  ///
  /// In en, this message translates to:
  /// **'Plan name is required'**
  String get plan_form_error_name_required;

  /// No description provided for @plan_form_error_save.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {message}'**
  String plan_form_error_save(String message);

  /// No description provided for @plan_form_error_partial_save.
  ///
  /// In en, this message translates to:
  /// **'The plan was saved, but some rider changes may not have been saved. Please review the plan before continuing.'**
  String get plan_form_error_partial_save;

  /// No description provided for @plan_not_found.
  ///
  /// In en, this message translates to:
  /// **'Plan not found'**
  String get plan_not_found;

  /// No description provided for @rider_form_title.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get rider_form_title;

  /// No description provided for @rider_name.
  ///
  /// In en, this message translates to:
  /// **'Rider name'**
  String get rider_name;

  /// No description provided for @rider_coverage_amount.
  ///
  /// In en, this message translates to:
  /// **'Coverage amount'**
  String get rider_coverage_amount;

  /// No description provided for @rider_payment_term.
  ///
  /// In en, this message translates to:
  /// **'Payment term'**
  String get rider_payment_term;

  /// No description provided for @rider_deductible.
  ///
  /// In en, this message translates to:
  /// **'Deductible'**
  String get rider_deductible;

  /// No description provided for @rider_waiting_period.
  ///
  /// In en, this message translates to:
  /// **'Waiting period'**
  String get rider_waiting_period;

  /// No description provided for @rider_error_name_required.
  ///
  /// In en, this message translates to:
  /// **'Rider name is required'**
  String get rider_error_name_required;

  /// No description provided for @currency_hkd.
  ///
  /// In en, this message translates to:
  /// **'HKD'**
  String get currency_hkd;

  /// No description provided for @currency_usd.
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get currency_usd;

  /// No description provided for @currency_cny.
  ///
  /// In en, this message translates to:
  /// **'CNY'**
  String get currency_cny;

  /// No description provided for @currency_eur.
  ///
  /// In en, this message translates to:
  /// **'EUR'**
  String get currency_eur;

  /// No description provided for @currency_gbp.
  ///
  /// In en, this message translates to:
  /// **'GBP'**
  String get currency_gbp;

  /// No description provided for @currency_jpy.
  ///
  /// In en, this message translates to:
  /// **'JPY'**
  String get currency_jpy;

  /// No description provided for @currency_sgd.
  ///
  /// In en, this message translates to:
  /// **'SGD'**
  String get currency_sgd;

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

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get home_title;

  /// No description provided for @home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get home_search_hint;

  /// No description provided for @home_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get home_filter_all;

  /// No description provided for @home_filter_holder.
  ///
  /// In en, this message translates to:
  /// **'Policy holder'**
  String get home_filter_holder;

  /// No description provided for @home_filter_insured.
  ///
  /// In en, this message translates to:
  /// **'Insured'**
  String get home_filter_insured;

  /// No description provided for @home_add_client.
  ///
  /// In en, this message translates to:
  /// **'Add client'**
  String get home_add_client;

  /// No description provided for @home_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No clients yet'**
  String get home_empty_title;

  /// No description provided for @home_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first client'**
  String get home_empty_subtitle;

  /// No description provided for @home_policy_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No policies} =1{1 policy} other{{count} policies}}'**
  String home_policy_count(int count);

  /// No description provided for @home_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load clients: {message}'**
  String home_load_error(String message);

  /// No description provided for @home_no_match.
  ///
  /// In en, this message translates to:
  /// **'No matching clients'**
  String get home_no_match;

  /// No description provided for @home_detail_prompt.
  ///
  /// In en, this message translates to:
  /// **'Select a client to view their details'**
  String get home_detail_prompt;

  /// No description provided for @home_open_details.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get home_open_details;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get nav_archive;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @client_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client_detail_title;

  /// No description provided for @client_info_section.
  ///
  /// In en, this message translates to:
  /// **'Client information'**
  String get client_info_section;

  /// No description provided for @client_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get client_name;

  /// No description provided for @client_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get client_role;

  /// No description provided for @client_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get client_gender;

  /// No description provided for @client_dob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get client_dob;

  /// No description provided for @client_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get client_phone;

  /// No description provided for @client_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get client_email;

  /// No description provided for @client_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get client_notes;

  /// No description provided for @client_policies_section.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get client_policies_section;

  /// No description provided for @client_reviews_section.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get client_reviews_section;

  /// No description provided for @client_no_reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get client_no_reviews;

  /// No description provided for @client_add_policy.
  ///
  /// In en, this message translates to:
  /// **'Add policy'**
  String get client_add_policy;

  /// No description provided for @client_no_policies.
  ///
  /// In en, this message translates to:
  /// **'No policies yet'**
  String get client_no_policies;

  /// No description provided for @client_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get client_edit;

  /// No description provided for @client_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get client_archive;

  /// No description provided for @client_archive_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Archive client?'**
  String get client_archive_confirm_title;

  /// No description provided for @client_archive_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'The client will be hidden from the list. You can restore it from the Archive.'**
  String get client_archive_confirm_body;

  /// No description provided for @client_archive_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get client_archive_confirm_action;

  /// No description provided for @client_archive_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get client_archive_cancel;

  /// No description provided for @client_archive_error.
  ///
  /// In en, this message translates to:
  /// **'The client could not be archived. Please try again.'**
  String get client_archive_error;

  /// No description provided for @client_archived_snack.
  ///
  /// In en, this message translates to:
  /// **'Client archived'**
  String get client_archived_snack;

  /// No description provided for @lock_app.
  ///
  /// In en, this message translates to:
  /// **'Lock app'**
  String get lock_app;

  /// No description provided for @search_field_label.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get search_field_label;

  /// No description provided for @client_form_title_new.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get client_form_title_new;

  /// No description provided for @client_form_title_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit client'**
  String get client_form_title_edit;

  /// No description provided for @client_form_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get client_form_save;

  /// No description provided for @client_form_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get client_form_saving;

  /// No description provided for @client_form_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get client_form_cancel;

  /// No description provided for @client_form_error_name_required.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get client_form_error_name_required;

  /// No description provided for @client_form_error_dob_required.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get client_form_error_dob_required;

  /// No description provided for @client_form_error_save.
  ///
  /// In en, this message translates to:
  /// **'The client could not be saved. Please try again.'**
  String get client_form_error_save;

  /// No description provided for @client_form_saved.
  ///
  /// In en, this message translates to:
  /// **'Client saved'**
  String get client_form_saved;

  /// No description provided for @client_not_found.
  ///
  /// In en, this message translates to:
  /// **'Client not found'**
  String get client_not_found;

  /// No description provided for @archive_title.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive_title;

  /// No description provided for @archive_tab_clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get archive_tab_clients;

  /// No description provided for @archive_tab_policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get archive_tab_policies;

  /// No description provided for @archive_tab_plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get archive_tab_plans;

  /// No description provided for @archive_empty_clients.
  ///
  /// In en, this message translates to:
  /// **'No archived clients'**
  String get archive_empty_clients;

  /// No description provided for @archive_empty_policies.
  ///
  /// In en, this message translates to:
  /// **'No archived policies'**
  String get archive_empty_policies;

  /// No description provided for @archive_empty_plans.
  ///
  /// In en, this message translates to:
  /// **'No archived plans'**
  String get archive_empty_plans;

  /// No description provided for @archive_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get archive_restore;

  /// No description provided for @archive_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get archive_delete;

  /// No description provided for @archive_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Record restored'**
  String get archive_restore_success;

  /// No description provided for @archive_delete_success.
  ///
  /// In en, this message translates to:
  /// **'Record permanently deleted'**
  String get archive_delete_success;

  /// No description provided for @archive_archived_on.
  ///
  /// In en, this message translates to:
  /// **'Archived on {date}'**
  String archive_archived_on(String date);

  /// No description provided for @archive_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete?'**
  String get archive_delete_confirm_title;

  /// No description provided for @archive_delete_confirm_body_1.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the record and all related data. This cannot be undone.'**
  String get archive_delete_confirm_body_1;

  /// No description provided for @archive_delete_confirm_body_2.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure? This is your last chance to cancel.'**
  String get archive_delete_confirm_body_2;

  /// No description provided for @archive_delete_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get archive_delete_confirm_action;

  /// No description provided for @archive_delete_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get archive_delete_cancel;

  /// No description provided for @archive_delete_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get archive_delete_continue;

  /// No description provided for @archive_delete_final.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get archive_delete_final;

  /// No description provided for @archive_restore_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Restore record?'**
  String get archive_restore_confirm_title;

  /// No description provided for @archive_restore_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'The record will reappear in the main list.'**
  String get archive_restore_confirm_body;

  /// No description provided for @archive_restore_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get archive_restore_confirm_action;

  /// No description provided for @archive_error_restore.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore: {message}'**
  String archive_error_restore(String message);

  /// No description provided for @archive_error_delete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {message}'**
  String archive_error_delete(String message);

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Settings coming soon'**
  String get settings_coming_soon;

  /// No description provided for @settings_coming_soon_body.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in a future update.'**
  String get settings_coming_soon_body;

  /// No description provided for @settings_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settings_logout;

  /// No description provided for @settings_logout_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get settings_logout_confirm_title;

  /// No description provided for @settings_logout_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'You will need your passphrase to sign in again.'**
  String get settings_logout_confirm_body;

  /// No description provided for @settings_logout_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settings_logout_confirm_action;

  /// No description provided for @settings_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_general;

  /// No description provided for @settings_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_security;

  /// No description provided for @settings_backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settings_backup;

  /// No description provided for @settings_audit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get settings_audit;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_danger.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settings_danger;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_language_english;

  /// No description provided for @settings_language_traditional_chinese.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get settings_language_traditional_chinese;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_theme_system;

  /// No description provided for @settings_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_theme_light;

  /// No description provided for @settings_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_theme_dark;

  /// No description provided for @settings_auto_lock.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get settings_auto_lock;

  /// No description provided for @settings_minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String settings_minutes(int minutes);

  /// No description provided for @settings_biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get settings_biometric;

  /// No description provided for @settings_biometric_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get settings_biometric_unavailable;

  /// No description provided for @settings_biometric_reason.
  ///
  /// In en, this message translates to:
  /// **'Confirm biometric unlock for this app'**
  String get settings_biometric_reason;

  /// No description provided for @settings_change_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Change passphrase'**
  String get settings_change_passphrase;

  /// No description provided for @settings_change_passphrase_guidance.
  ///
  /// In en, this message translates to:
  /// **'This operation is coming in a future update. Use your Recovery Key to reset your passphrase.'**
  String get settings_change_passphrase_guidance;

  /// No description provided for @settings_regenerate_recovery.
  ///
  /// In en, this message translates to:
  /// **'Regenerate recovery key'**
  String get settings_regenerate_recovery;

  /// No description provided for @settings_max_attempts.
  ///
  /// In en, this message translates to:
  /// **'Max failed attempts'**
  String get settings_max_attempts;

  /// No description provided for @settings_max_attempts_preference_only.
  ///
  /// In en, this message translates to:
  /// **'Saved preference only; login enforcement is unchanged.'**
  String get settings_max_attempts_preference_only;

  /// No description provided for @settings_attempts.
  ///
  /// In en, this message translates to:
  /// **'{attempts} attempts'**
  String settings_attempts(int attempts);

  /// No description provided for @settings_auto_backup.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup'**
  String get settings_auto_backup;

  /// No description provided for @settings_auto_backup_note.
  ///
  /// In en, this message translates to:
  /// **'Frequency is saved; scheduled backups are not active yet.'**
  String get settings_auto_backup_note;

  /// No description provided for @settings_backup_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settings_backup_off;

  /// No description provided for @settings_backup_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get settings_backup_daily;

  /// No description provided for @settings_backup_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get settings_backup_weekly;

  /// No description provided for @settings_backup_folder.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get settings_backup_folder;

  /// No description provided for @settings_backup_folder_default.
  ///
  /// In en, this message translates to:
  /// **'Default location'**
  String get settings_backup_folder_default;

  /// No description provided for @settings_backup_now.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get settings_backup_now;

  /// No description provided for @settings_backup_coming.
  ///
  /// In en, this message translates to:
  /// **'Backup feature coming in next update'**
  String get settings_backup_coming;

  /// No description provided for @settings_view_audit.
  ///
  /// In en, this message translates to:
  /// **'View audit log'**
  String get settings_view_audit;

  /// No description provided for @settings_audit_retention.
  ///
  /// In en, this message translates to:
  /// **'Audit retention'**
  String get settings_audit_retention;

  /// No description provided for @settings_audit_retention_value.
  ///
  /// In en, this message translates to:
  /// **'2 years'**
  String get settings_audit_retention_value;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;

  /// No description provided for @settings_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settings_privacy_policy;

  /// No description provided for @settings_privacy_policy_body.
  ///
  /// In en, this message translates to:
  /// **'This application stores all data locally on your device. No data is sent to any server. Encryption keys are stored in your device\'s secure storage. Backups are encrypted with a passphrase you choose.'**
  String get settings_privacy_policy_body;

  /// No description provided for @settings_reset_app.
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get settings_reset_app;

  /// No description provided for @settings_coming_soon_title.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settings_coming_soon_title;

  /// No description provided for @audit_log_title.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get audit_log_title;

  /// No description provided for @audit_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get audit_filter_all;

  /// No description provided for @audit_filter_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get audit_filter_from;

  /// No description provided for @audit_filter_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get audit_filter_to;

  /// No description provided for @audit_filter_any_date.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get audit_filter_any_date;

  /// No description provided for @audit_filter_date_range.
  ///
  /// In en, this message translates to:
  /// **'{from} — {to}'**
  String audit_filter_date_range(String from, String to);

  /// No description provided for @audit_filter_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get audit_filter_clear;

  /// No description provided for @audit_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify chain'**
  String get audit_verify;

  /// No description provided for @audit_chain_unverified.
  ///
  /// In en, this message translates to:
  /// **'Chain not verified — tap ✓ to verify'**
  String get audit_chain_unverified;

  /// No description provided for @audit_chain_valid.
  ///
  /// In en, this message translates to:
  /// **'Chain verified ({count} entries)'**
  String audit_chain_valid(int count);

  /// No description provided for @audit_chain_broken.
  ///
  /// In en, this message translates to:
  /// **'Chain broken at index {index}: {reason}'**
  String audit_chain_broken(int index, String reason);

  /// No description provided for @audit_verify_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the audit chain.'**
  String get audit_verify_error;

  /// No description provided for @audit_empty.
  ///
  /// In en, this message translates to:
  /// **'No audit entries match the filters'**
  String get audit_empty;

  /// No description provided for @audit_load_more.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get audit_load_more;

  /// No description provided for @audit_entry_details.
  ///
  /// In en, this message translates to:
  /// **'Entry details'**
  String get audit_entry_details;

  /// No description provided for @audit_copy_json.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get audit_copy_json;

  /// No description provided for @audit_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get audit_copied;

  /// No description provided for @audit_event_type.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get audit_event_type;

  /// No description provided for @audit_timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get audit_timestamp;

  /// No description provided for @audit_entity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get audit_entity;

  /// No description provided for @audit_entity_id.
  ///
  /// In en, this message translates to:
  /// **'Entity ID'**
  String get audit_entity_id;

  /// No description provided for @audit_entity_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get audit_entity_none;

  /// No description provided for @audit_metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get audit_metadata;

  /// No description provided for @audit_prev_hash.
  ///
  /// In en, this message translates to:
  /// **'Previous hash'**
  String get audit_prev_hash;

  /// No description provided for @audit_entry_hash.
  ///
  /// In en, this message translates to:
  /// **'Entry hash'**
  String get audit_entry_hash;

  /// No description provided for @audit_event_app_setup.
  ///
  /// In en, this message translates to:
  /// **'App setup'**
  String get audit_event_app_setup;

  /// No description provided for @audit_event_login_success.
  ///
  /// In en, this message translates to:
  /// **'Login success'**
  String get audit_event_login_success;

  /// No description provided for @audit_event_login_fail.
  ///
  /// In en, this message translates to:
  /// **'Login failure'**
  String get audit_event_login_fail;

  /// No description provided for @audit_event_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get audit_event_logout;

  /// No description provided for @audit_event_auto_lock.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get audit_event_auto_lock;

  /// No description provided for @audit_event_recovery_used.
  ///
  /// In en, this message translates to:
  /// **'Recovery key used'**
  String get audit_event_recovery_used;

  /// No description provided for @audit_event_recovery_key_rotated.
  ///
  /// In en, this message translates to:
  /// **'Recovery key rotated'**
  String get audit_event_recovery_key_rotated;

  /// No description provided for @audit_event_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get audit_event_create;

  /// No description provided for @audit_event_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get audit_event_update;

  /// No description provided for @audit_event_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get audit_event_archive;

  /// No description provided for @audit_event_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get audit_event_restore;

  /// No description provided for @audit_event_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get audit_event_delete;

  /// No description provided for @audit_event_export_pdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get audit_event_export_pdf;

  /// No description provided for @audit_event_backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get audit_event_backup;

  /// No description provided for @audit_event_restore_db.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get audit_event_restore_db;

  /// No description provided for @audit_event_migration.
  ///
  /// In en, this message translates to:
  /// **'Migration'**
  String get audit_event_migration;

  /// No description provided for @audit_event_purge.
  ///
  /// In en, this message translates to:
  /// **'Purge'**
  String get audit_event_purge;

  /// No description provided for @action_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get action_retry;

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

  /// No description provided for @backup_title.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup_title;

  /// No description provided for @backup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an encrypted backup of your data'**
  String get backup_subtitle;

  /// No description provided for @backup_info_card_title.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup'**
  String get backup_info_card_title;

  /// No description provided for @backup_info_card_body.
  ///
  /// In en, this message translates to:
  /// **'Backups are encrypted with a passphrase you choose. Store this passphrase securely — without it, the backup cannot be restored.'**
  String get backup_info_card_body;

  /// No description provided for @backup_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Backup passphrase'**
  String get backup_passphrase;

  /// No description provided for @backup_confirm_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Confirm backup passphrase'**
  String get backup_confirm_passphrase;

  /// No description provided for @backup_passphrase_hint.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters'**
  String get backup_passphrase_hint;

  /// No description provided for @backup_choose_destination.
  ///
  /// In en, this message translates to:
  /// **'Choose destination'**
  String get backup_choose_destination;

  /// No description provided for @backup_destination_selected.
  ///
  /// In en, this message translates to:
  /// **'Destination: {path}'**
  String backup_destination_selected(String path);

  /// No description provided for @backup_create.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backup_create;

  /// No description provided for @backup_creating.
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get backup_creating;

  /// No description provided for @backup_success_title.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backup_success_title;

  /// No description provided for @backup_success_body.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to: {path}'**
  String backup_success_body(String path);

  /// No description provided for @backup_error.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Please try again.'**
  String get backup_error;

  /// No description provided for @backup_open_folder.
  ///
  /// In en, this message translates to:
  /// **'Show saved location'**
  String get backup_open_folder;

  /// No description provided for @backup_last_backup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backup_last_backup(String date);

  /// No description provided for @backup_last_backup_size.
  ///
  /// In en, this message translates to:
  /// **'Backup size: {size} bytes'**
  String backup_last_backup_size(String size);

  /// No description provided for @backup_never.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backup_never;

  /// No description provided for @backup_password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passphrases do not match'**
  String get backup_password_mismatch;

  /// No description provided for @backup_destination_required.
  ///
  /// In en, this message translates to:
  /// **'Choose a destination to continue'**
  String get backup_destination_required;

  /// No description provided for @restore_title.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore_title;

  /// No description provided for @restore_warning.
  ///
  /// In en, this message translates to:
  /// **'Restore will overwrite ALL current data. A pre-restore backup will be created automatically.'**
  String get restore_warning;

  /// No description provided for @restore_select_file.
  ///
  /// In en, this message translates to:
  /// **'Select backup file'**
  String get restore_select_file;

  /// No description provided for @restore_file_selected.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String restore_file_selected(String name);

  /// No description provided for @restore_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Backup passphrase'**
  String get restore_passphrase;

  /// No description provided for @restore_confirm_checkbox.
  ///
  /// In en, this message translates to:
  /// **'I understand that restoring will overwrite my current data'**
  String get restore_confirm_checkbox;

  /// No description provided for @restore_action.
  ///
  /// In en, this message translates to:
  /// **'Restore now'**
  String get restore_action;

  /// No description provided for @restore_restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get restore_restoring;

  /// No description provided for @restore_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get restore_confirm_title;

  /// No description provided for @restore_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'Your current data will be replaced. A pre-restore backup will be saved first. Continue?'**
  String get restore_confirm_body;

  /// No description provided for @restore_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore_confirm_action;

  /// No description provided for @restore_success_title.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restore_success_title;

  /// No description provided for @restore_success_body.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. Please sign in again.'**
  String get restore_success_body;

  /// No description provided for @restore_error.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Check the backup and passphrase, then try again.'**
  String get restore_error;

  /// No description provided for @restore_error_closed.
  ///
  /// In en, this message translates to:
  /// **'Please close any other instance of the app before restoring.'**
  String get restore_error_closed;

  /// No description provided for @restore_file_required.
  ///
  /// In en, this message translates to:
  /// **'Select a backup file to continue'**
  String get restore_file_required;

  /// No description provided for @settings_restore_backup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get settings_restore_backup;

  /// No description provided for @export_pdf_title.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get export_pdf_title;

  /// No description provided for @export_pdf_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select clients to export'**
  String get export_pdf_subtitle;

  /// No description provided for @export_pdf_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get export_pdf_select_all;

  /// No description provided for @export_pdf_no_selection.
  ///
  /// In en, this message translates to:
  /// **'Select at least one client'**
  String get export_pdf_no_selection;

  /// No description provided for @export_pdf_language.
  ///
  /// In en, this message translates to:
  /// **'PDF language'**
  String get export_pdf_language;

  /// No description provided for @export_pdf_language_follow.
  ///
  /// In en, this message translates to:
  /// **'Follow app'**
  String get export_pdf_language_follow;

  /// No description provided for @export_pdf_allow_print.
  ///
  /// In en, this message translates to:
  /// **'Allow printing'**
  String get export_pdf_allow_print;

  /// No description provided for @export_pdf_password.
  ///
  /// In en, this message translates to:
  /// **'PDF password'**
  String get export_pdf_password;

  /// No description provided for @export_pdf_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm PDF password'**
  String get export_pdf_confirm_password;

  /// No description provided for @export_pdf_password_hint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get export_pdf_password_hint;

  /// No description provided for @export_pdf_password_policy_note.
  ///
  /// In en, this message translates to:
  /// **'PDF password length is separate from your sign-in passphrase policy.'**
  String get export_pdf_password_policy_note;

  /// No description provided for @export_pdf_password_warning_title.
  ///
  /// In en, this message translates to:
  /// **'PDF password protection unavailable'**
  String get export_pdf_password_warning_title;

  /// No description provided for @export_pdf_password_warning_body.
  ///
  /// In en, this message translates to:
  /// **'This version cannot encrypt PDF files or restrict copying and printing. The exported file will contain sensitive client information and will NOT be password-protected. Continue only if you can store it securely.'**
  String get export_pdf_password_warning_body;

  /// No description provided for @export_pdf_password_warning_continue.
  ///
  /// In en, this message translates to:
  /// **'Export unprotected PDF'**
  String get export_pdf_password_warning_continue;

  /// No description provided for @export_pdf_export.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get export_pdf_export;

  /// No description provided for @export_pdf_exporting.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get export_pdf_exporting;

  /// No description provided for @export_pdf_success_title.
  ///
  /// In en, this message translates to:
  /// **'PDF exported'**
  String get export_pdf_success_title;

  /// No description provided for @export_pdf_success_body.
  ///
  /// In en, this message translates to:
  /// **'The PDF is not password-protected. Keep the file secure: {path}'**
  String export_pdf_success_body(String path);

  /// No description provided for @export_pdf_error.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get export_pdf_error;

  /// No description provided for @export_pdf_open_file.
  ///
  /// In en, this message translates to:
  /// **'Share or open PDF'**
  String get export_pdf_open_file;

  /// No description provided for @export_pdf_empty_clients.
  ///
  /// In en, this message translates to:
  /// **'No active clients to export'**
  String get export_pdf_empty_clients;

  /// No description provided for @pdf_doc_title.
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy Overview'**
  String get pdf_doc_title;

  /// No description provided for @pdf_generated_on.
  ///
  /// In en, this message translates to:
  /// **'Generated on {date}'**
  String pdf_generated_on(String date);

  /// No description provided for @pdf_page.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pdf_page(int current, int total);

  /// No description provided for @pdf_section_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get pdf_section_client;

  /// No description provided for @pdf_section_policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get pdf_section_policies;

  /// No description provided for @pdf_section_plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get pdf_section_plans;

  /// No description provided for @pdf_section_riders.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get pdf_section_riders;

  /// No description provided for @pdf_policy_title.
  ///
  /// In en, this message translates to:
  /// **'Policy: {number}'**
  String pdf_policy_title(String number);

  /// No description provided for @pdf_plan_title.
  ///
  /// In en, this message translates to:
  /// **'Plan: {name}'**
  String pdf_plan_title(String name);

  /// No description provided for @pdf_rider_title.
  ///
  /// In en, this message translates to:
  /// **'Rider: {name}'**
  String pdf_rider_title(String name);

  /// No description provided for @pdf_not_available.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get pdf_not_available;

  /// No description provided for @pdf_footer.
  ///
  /// In en, this message translates to:
  /// **'Generated on {date} · Page {current} of {total}'**
  String pdf_footer(String date, int current, int total);
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
