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

  @override
  String get policy_status_active => 'Active';

  @override
  String get policy_status_lapsed => 'Lapsed';

  @override
  String get policy_status_surrendered => 'Surrendered';

  @override
  String get plan_category_life => 'Life';

  @override
  String get plan_category_ci => 'Critical Illness';

  @override
  String get plan_category_hospital => 'Hospital';

  @override
  String get plan_category_accident => 'Accident';

  @override
  String get plan_category_savings => 'Savings';

  @override
  String get plan_category_other => 'Other';

  @override
  String get splash_loading => 'Loading...';

  @override
  String get setup_title => 'Setup';

  @override
  String get setup_subtitle => 'Create a passphrase to protect your data';

  @override
  String get setup_passphrase => 'Passphrase';

  @override
  String get setup_confirm_passphrase => 'Confirm passphrase';

  @override
  String get setup_passphrase_hint => 'At least 12 characters';

  @override
  String get setup_passphrase_mismatch => 'Passphrases do not match';

  @override
  String get setup_passphrase_too_short =>
      'Passphrase must be at least 12 characters';

  @override
  String get setup_create => 'Create';

  @override
  String get setup_creating => 'Creating...';

  @override
  String get setup_error => 'Setup could not be completed. Please try again.';

  @override
  String get recovery_key_dialog_title => 'Your Recovery Key';

  @override
  String get recovery_key_dialog_body =>
      'This is the ONLY way to recover your data if you forget your passphrase.\n\nPrint it. Store it offline. Never share it.\n\nWe cannot recover your data without it.';

  @override
  String get recovery_key_dialog_copy => 'Copy';

  @override
  String get recovery_key_copied => 'Recovery key copied to clipboard.';

  @override
  String get recovery_key_dialog_confirm => 'I have printed and stored it';

  @override
  String get login_title => 'Sign In';

  @override
  String get login_subtitle => 'Enter your passphrase to unlock';

  @override
  String get login_passphrase => 'Passphrase';

  @override
  String get login_sign_in => 'Sign In';

  @override
  String get login_signing_in => 'Signing in...';

  @override
  String get login_biometric => 'Unlock with biometric';

  @override
  String login_error(int attempts) {
    return 'Incorrect passphrase. $attempts attempts remaining.';
  }

  @override
  String get login_forgot => 'Forgot passphrase?';

  @override
  String get lock_title => 'Locked';

  @override
  String get lock_subtitle => 'Enter your passphrase to unlock';

  @override
  String get lock_unlock => 'Unlock';

  @override
  String get home_welcome => 'Welcome';

  @override
  String get home_coming_soon => 'Home screen coming soon';

  @override
  String home_state(String state) {
    return 'State: $state';
  }

  @override
  String get home_lock => 'Lock';

  @override
  String get home_logout => 'Log out';

  @override
  String get home_title => 'Clients';

  @override
  String get home_search_hint => 'Search clients';

  @override
  String get home_filter_all => 'All';

  @override
  String get home_filter_holder => 'Policy holder';

  @override
  String get home_filter_insured => 'Insured';

  @override
  String get home_add_client => 'Add client';

  @override
  String get home_empty_title => 'No clients yet';

  @override
  String get home_empty_subtitle => 'Tap + to add your first client';

  @override
  String home_policy_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count policies',
      one: '1 policy',
      zero: 'No policies',
    );
    return '$_temp0';
  }

  @override
  String home_load_error(String message) {
    return 'Failed to load clients: $message';
  }

  @override
  String get home_no_match => 'No matching clients';

  @override
  String get home_detail_prompt => 'Select a client to view their details';

  @override
  String get home_open_details => 'Open details';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_archive => 'Archive';

  @override
  String get nav_settings => 'Settings';

  @override
  String get client_detail_title => 'Client';

  @override
  String get client_info_section => 'Client information';

  @override
  String get client_name => 'Name';

  @override
  String get client_role => 'Role';

  @override
  String get client_gender => 'Gender';

  @override
  String get client_dob => 'Date of birth';

  @override
  String get client_phone => 'Phone';

  @override
  String get client_email => 'Email';

  @override
  String get client_notes => 'Notes';

  @override
  String get client_policies_section => 'Policies';

  @override
  String get client_reviews_section => 'Reviews';

  @override
  String get client_no_reviews => 'No reviews yet';

  @override
  String get client_add_policy => 'Add policy';

  @override
  String get client_no_policies => 'No policies yet';

  @override
  String get client_edit => 'Edit';

  @override
  String get client_archive => 'Archive';

  @override
  String get client_archive_confirm_title => 'Archive client?';

  @override
  String get client_archive_confirm_body =>
      'The client will be hidden from the list. You can restore it from the Archive.';

  @override
  String get client_archive_confirm_action => 'Archive';

  @override
  String get client_archive_cancel => 'Cancel';

  @override
  String get client_archive_error =>
      'The client could not be archived. Please try again.';

  @override
  String get client_form_title_new => 'New client';

  @override
  String get client_form_title_edit => 'Edit client';

  @override
  String get client_form_save => 'Save';

  @override
  String get client_form_saving => 'Saving...';

  @override
  String get client_form_cancel => 'Cancel';

  @override
  String get client_form_error_name_required => 'Name is required';

  @override
  String get client_form_error_dob_required => 'Date of birth is required';

  @override
  String get client_form_error_save =>
      'The client could not be saved. Please try again.';

  @override
  String get client_form_saved => 'Client saved';

  @override
  String get client_not_found => 'Client not found';

  @override
  String get archive_title => 'Archive';

  @override
  String get settings_title => 'Settings';

  @override
  String get action_retry => 'Retry';

  @override
  String get error_generic => 'An error occurred. Please try again.';

  @override
  String get recovery_title => 'Recovery';

  @override
  String get coming_soon => 'Coming soon';

  @override
  String get key_state_uninitialized => 'not set up';

  @override
  String get key_state_locked => 'locked';

  @override
  String get key_state_unlocked => 'unlocked';
}
