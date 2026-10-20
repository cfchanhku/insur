// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => '保險保單管理';

  @override
  String get app_tagline => '保險資料安全地儲存於此裝置。';

  @override
  String get action_next => '下一步';

  @override
  String get action_back => '返回';

  @override
  String get action_cancel => '取消';

  @override
  String get action_save => '儲存';

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
  String get policy_detail_title => 'Policy';

  @override
  String get policy_info_section => 'Policy information';

  @override
  String get policy_company => 'Insurer';

  @override
  String get policy_no => 'Policy number';

  @override
  String policy_card_summary(
    String company,
    String effectiveDate,
    String status,
  ) {
    return '$company · $effectiveDate · $status';
  }

  @override
  String get policy_effective_date => 'Effective date';

  @override
  String get policy_first_premium_date => 'First premium date';

  @override
  String get policy_currency => 'Currency';

  @override
  String get policy_status => 'Status';

  @override
  String get policy_notes => 'Notes';

  @override
  String get policy_plans_section => 'Plans';

  @override
  String get policy_add_plan => 'Add plan';

  @override
  String get policy_no_plans => 'No plans yet';

  @override
  String get policy_edit => 'Edit';

  @override
  String get policy_archive => 'Archive';

  @override
  String get policy_archive_confirm_title => 'Archive policy?';

  @override
  String get policy_archive_confirm_body =>
      'The policy will be hidden. You can restore it from the Archive.';

  @override
  String get policy_archive_confirm_action => 'Archive';

  @override
  String get policy_archived_snack => 'Policy archived';

  @override
  String get policy_form_title_new => 'New policy';

  @override
  String get policy_form_title_edit => 'Edit policy';

  @override
  String get policy_form_save => 'Save';

  @override
  String get policy_form_saving => 'Saving...';

  @override
  String get policy_form_cancel => 'Cancel';

  @override
  String get policy_form_saved => 'Policy saved';

  @override
  String get policy_form_error_company_required => 'Insurer is required';

  @override
  String get policy_form_error_policy_no_required =>
      'Policy number is required';

  @override
  String get policy_form_error_currency_invalid =>
      'Currency must be 3 uppercase letters';

  @override
  String get policy_form_error_dates =>
      'First premium date must be on or after effective date';

  @override
  String policy_form_error_save(String message) {
    return 'Failed to save: $message';
  }

  @override
  String get policy_not_found => 'Policy not found';

  @override
  String get plan_detail_title => 'Plan';

  @override
  String plan_card_summary(String category, String coverage) {
    return '$category · $coverage';
  }

  @override
  String get plan_category => 'Category';

  @override
  String get plan_name => 'Plan name';

  @override
  String get plan_coverage_amount => 'Coverage amount';

  @override
  String get plan_payment_term => 'Payment term';

  @override
  String get plan_coverage_period => 'Coverage period';

  @override
  String get plan_deductible => 'Deductible';

  @override
  String get plan_notes => 'Notes';

  @override
  String get plan_add_rider => 'Add rider';

  @override
  String get plan_riders_section => 'Riders';

  @override
  String get plan_no_riders => 'No riders';

  @override
  String get plan_remove_rider => 'Remove';

  @override
  String get plan_archive_confirm_title => 'Archive plan?';

  @override
  String get plan_archive_confirm_body =>
      'The plan will be hidden. You can restore it from the Archive.';

  @override
  String get plan_archive_confirm_action => 'Archive';

  @override
  String get plan_archived_snack => 'Plan archived';

  @override
  String get accessibility_delete => 'Delete permanently';

  @override
  String get accessibility_restore => 'Restore';

  @override
  String get plan_form_title_new => 'New plan';

  @override
  String get plan_form_title_edit => 'Edit plan';

  @override
  String get plan_form_save => 'Save';

  @override
  String get plan_form_saving => 'Saving...';

  @override
  String get plan_form_cancel => 'Cancel';

  @override
  String get plan_form_saved => 'Plan saved';

  @override
  String get plan_form_error_category_required => 'Category is required';

  @override
  String get plan_form_error_coverage_invalid =>
      'Amount must be zero or greater';

  @override
  String get plan_form_error_name_required => 'Plan name is required';

  @override
  String plan_form_error_save(String message) {
    return 'Failed to save: $message';
  }

  @override
  String get plan_form_error_partial_save =>
      'The plan was saved, but some rider changes may not have been saved. Please review the plan before continuing.';

  @override
  String get plan_not_found => 'Plan not found';

  @override
  String get rider_form_title => 'Rider';

  @override
  String get rider_name => 'Rider name';

  @override
  String get rider_coverage_amount => 'Coverage amount';

  @override
  String get rider_payment_term => 'Payment term';

  @override
  String get rider_deductible => 'Deductible';

  @override
  String get rider_waiting_period => 'Waiting period';

  @override
  String get rider_error_name_required => 'Rider name is required';

  @override
  String get currency_hkd => 'HKD';

  @override
  String get currency_usd => 'USD';

  @override
  String get currency_cny => 'CNY';

  @override
  String get currency_eur => 'EUR';

  @override
  String get currency_gbp => 'GBP';

  @override
  String get currency_jpy => 'JPY';

  @override
  String get currency_sgd => 'SGD';

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
  String get setupStepPassphrase => 'Passphrase';

  @override
  String get setupStepRecovery => 'Recovery key';

  @override
  String get setupStepBiometric => 'Biometric enrollment';

  @override
  String setupStepOf(int current, int total) {
    return 'Step $current of $total';
  }

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
  String get setup_recovery_confirmation =>
      'Enter your recovery key to confirm';

  @override
  String get setup_recovery_confirm => 'Confirm recovery key';

  @override
  String get setup_biometric_prompt =>
      'Enroll biometrics for future use. Biometric unlock is not available yet; you can manage enrollment later in Settings.';

  @override
  String get setup_enable_biometric => 'Enroll biometrics';

  @override
  String get setup_skip_biometric => 'Skip for now';

  @override
  String get recovery_invalid_key =>
      'That recovery key is invalid. Check it and try again.';

  @override
  String get recovery_set_new_passphrase =>
      'Set a new passphrase to finish recovering your vault.';

  @override
  String get recovery_enter_key =>
      'Enter your offline recovery key to unlock your vault.';

  @override
  String get recovery_key_label => 'Recovery key';

  @override
  String get recovery_working => 'Please wait...';

  @override
  String get recovery_reset_passphrase => 'Save new passphrase';

  @override
  String get recovery_continue => 'Continue';

  @override
  String get recovery_reset_required =>
      'A new passphrase is required after recovery. Use your recovery key to continue.';

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
  String get client_archived_snack => 'Client archived';

  @override
  String get lock_app => 'Lock app';

  @override
  String get search_field_label => 'Search clients';

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
  String get archive_tab_clients => 'Clients';

  @override
  String get archive_tab_policies => 'Policies';

  @override
  String get archive_tab_plans => 'Plans';

  @override
  String get archive_empty_clients => 'No archived clients';

  @override
  String get archive_empty_policies => 'No archived policies';

  @override
  String get archive_empty_plans => 'No archived plans';

  @override
  String get archive_restore => 'Restore';

  @override
  String get archive_delete => 'Delete permanently';

  @override
  String get archive_restore_success => 'Record restored';

  @override
  String get archive_delete_success => 'Record permanently deleted';

  @override
  String archive_archived_on(String date) {
    return 'Archived on $date';
  }

  @override
  String get archive_delete_confirm_title => 'Permanently delete?';

  @override
  String get archive_delete_confirm_body_1 =>
      'This will permanently delete the record and all related data. This cannot be undone.';

  @override
  String get archive_delete_confirm_body_2 =>
      'Are you absolutely sure? This is your last chance to cancel.';

  @override
  String get archive_delete_confirm_action => 'Delete permanently';

  @override
  String get archive_delete_cancel => 'Cancel';

  @override
  String get archive_delete_continue => 'Continue';

  @override
  String get archive_delete_final => 'Delete';

  @override
  String get archive_restore_confirm_title => 'Restore record?';

  @override
  String get archive_restore_confirm_body =>
      'The record will reappear in the main list.';

  @override
  String get archive_restore_confirm_action => 'Restore';

  @override
  String archive_error_restore(String message) {
    return 'Failed to restore: $message';
  }

  @override
  String archive_error_delete(String message) {
    return 'Failed to delete: $message';
  }

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_coming_soon => 'Settings coming soon';

  @override
  String get settings_coming_soon_body =>
      'This feature will be available in a future update.';

  @override
  String get settings_logout => 'Logout';

  @override
  String get settings_logout_confirm_title => 'Logout?';

  @override
  String get settings_logout_confirm_body =>
      'You will need your passphrase to sign in again.';

  @override
  String get settings_logout_confirm_action => 'Logout';

  @override
  String get settings_general => 'General';

  @override
  String get settings_security => 'Security';

  @override
  String get settings_backup => 'Backup';

  @override
  String get settings_audit => 'Audit';

  @override
  String get settings_about => 'About';

  @override
  String get settings_danger => 'Danger zone';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_language_english => 'English';

  @override
  String get settings_language_traditional_chinese => '繁體中文';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_auto_lock => 'Auto-lock';

  @override
  String settings_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get settings_biometric => 'Biometric enrollment';

  @override
  String get settings_biometric_unavailable => 'Not available on this device';

  @override
  String get settings_biometric_reason =>
      'Confirm biometric enrollment for this app';

  @override
  String get biometricUnlockDeferred =>
      'Enrollment is saved, but biometric unlock is not available yet.';

  @override
  String get settings_change_passphrase => 'Change passphrase';

  @override
  String get settings_regenerate_recovery => 'Regenerate recovery key';

  @override
  String get settings_current_passphrase => 'Current passphrase';

  @override
  String get settings_new_passphrase => 'New passphrase';

  @override
  String get settings_passphrase_save => 'Change passphrase';

  @override
  String get settings_passphrase_changed => 'Passphrase changed.';

  @override
  String get settings_passphrase_change_failed =>
      'Could not change the passphrase. Check your current passphrase and try again.';

  @override
  String get settings_recovery_regenerate_action => 'Regenerate';

  @override
  String get settings_recovery_regenerate_failed =>
      'Could not regenerate the recovery key. Check your passphrase and try again.';

  @override
  String get settings_max_attempts => 'Max failed attempts';

  @override
  String get settings_max_attempts_preference_only =>
      'Saved preference only; login enforcement is unchanged.';

  @override
  String settings_attempts(int attempts) {
    return '$attempts attempts';
  }

  @override
  String get settings_auto_backup => 'Auto-backup';

  @override
  String get settings_auto_backup_note =>
      'Frequency is saved; scheduled backups are not active yet.';

  @override
  String get settings_backup_off => 'Off';

  @override
  String get settings_backup_daily => 'Daily';

  @override
  String get settings_backup_weekly => 'Weekly';

  @override
  String get settings_backup_folder => 'Backup folder';

  @override
  String get settings_backup_folder_default => 'Default location';

  @override
  String get settings_backup_now => 'Backup now';

  @override
  String get settings_backup_coming => 'Backup feature coming in next update';

  @override
  String get settings_view_audit => 'View audit log';

  @override
  String get settings_audit_retention => 'Audit retention';

  @override
  String get settings_audit_retention_value => '2 years';

  @override
  String get settings_version => 'Version';

  @override
  String get settings_privacy_policy => 'Privacy policy';

  @override
  String get settings_privacy_policy_body =>
      'This application stores all data locally on your device. No data is sent to any server. Encryption keys are stored in your device\'s secure storage. Backups are encrypted with a passphrase you choose.';

  @override
  String get settings_reset_app => 'Reset app';

  @override
  String get settings_coming_soon_title => 'Coming soon';

  @override
  String get audit_log_title => 'Audit log';

  @override
  String get audit_filter_all => 'All events';

  @override
  String get audit_filter_from => 'From';

  @override
  String get audit_filter_to => 'To';

  @override
  String get audit_filter_any_date => 'Any date';

  @override
  String audit_filter_date_range(String from, String to) {
    return '$from — $to';
  }

  @override
  String get audit_filter_clear => 'Clear filters';

  @override
  String get audit_verify => 'Verify chain';

  @override
  String get audit_chain_unverified => 'Chain not verified — tap ✓ to verify';

  @override
  String audit_chain_valid(int count) {
    return 'Chain verified ($count entries)';
  }

  @override
  String audit_chain_broken(int index, String reason) {
    return 'Chain broken at index $index: $reason';
  }

  @override
  String get audit_verify_error => 'Unable to verify the audit chain.';

  @override
  String get audit_empty => 'No audit entries match the filters';

  @override
  String get audit_load_more => 'Load more';

  @override
  String get audit_entry_details => 'Entry details';

  @override
  String get audit_copy_json => 'Copy JSON';

  @override
  String get audit_copied => 'Copied to clipboard';

  @override
  String get audit_event_type => 'Event type';

  @override
  String get audit_timestamp => 'Timestamp';

  @override
  String get audit_entity => 'Entity';

  @override
  String get audit_entity_id => 'Entity ID';

  @override
  String get audit_entity_none => 'None';

  @override
  String get audit_metadata => 'Metadata';

  @override
  String get audit_prev_hash => 'Previous hash';

  @override
  String get audit_entry_hash => 'Entry hash';

  @override
  String get audit_event_app_setup => 'App setup';

  @override
  String get audit_event_login_success => 'Login success';

  @override
  String get audit_event_login_fail => 'Login failure';

  @override
  String get audit_event_logout => 'Logout';

  @override
  String get audit_event_auto_lock => 'Auto-lock';

  @override
  String get audit_event_recovery_used => 'Recovery key used';

  @override
  String get audit_event_recovery_key_rotated => 'Recovery key rotated';

  @override
  String get audit_event_passphrase_changed => 'Passphrase changed';

  @override
  String get audit_event_create => 'Create';

  @override
  String get audit_event_update => 'Update';

  @override
  String get audit_event_archive => 'Archive';

  @override
  String get audit_event_restore => 'Restore';

  @override
  String get audit_event_delete => 'Delete';

  @override
  String get audit_event_export_pdf => 'Export PDF';

  @override
  String get audit_event_backup => 'Backup';

  @override
  String get audit_event_restore_db => 'Restore from backup';

  @override
  String get audit_event_migration => 'Migration';

  @override
  String get audit_event_purge => 'Purge';

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

  @override
  String get backup_title => 'Backup';

  @override
  String get backup_subtitle => 'Create an encrypted backup of your data';

  @override
  String get backup_info_card_title => 'Encrypted backup';

  @override
  String get backup_info_card_body =>
      'Backups are encrypted with a passphrase you choose. Store this passphrase securely — without it, the backup cannot be restored.';

  @override
  String get backup_passphrase => 'Backup passphrase';

  @override
  String get backup_confirm_passphrase => 'Confirm backup passphrase';

  @override
  String get backup_passphrase_hint => 'At least 12 characters';

  @override
  String get backup_choose_destination => 'Choose destination';

  @override
  String backup_destination_selected(String path) {
    return 'Destination: $path';
  }

  @override
  String get backup_create => 'Create backup';

  @override
  String get backup_creating => 'Creating backup...';

  @override
  String get backup_success_title => 'Backup created';

  @override
  String backup_success_body(String path) {
    return 'Backup saved to: $path';
  }

  @override
  String get backup_error => 'Backup failed. Please try again.';

  @override
  String get backup_open_folder => 'Show saved location';

  @override
  String backup_last_backup(String date) {
    return 'Last backup: $date';
  }

  @override
  String backup_last_backup_size(String size) {
    return 'Backup size: $size bytes';
  }

  @override
  String get backup_never => 'No backups yet';

  @override
  String get backup_password_mismatch => 'Passphrases do not match';

  @override
  String get backup_destination_required => 'Choose a destination to continue';

  @override
  String get restore_title => 'Restore';

  @override
  String get restore_warning =>
      'Restore will overwrite ALL current data. A pre-restore backup will be created automatically.';

  @override
  String get restore_select_file => 'Select backup file';

  @override
  String restore_file_selected(String name) {
    return 'File: $name';
  }

  @override
  String get restore_passphrase => 'Backup passphrase';

  @override
  String get restore_confirm_checkbox =>
      'I understand that restoring will overwrite my current data';

  @override
  String get restore_action => 'Restore now';

  @override
  String get restore_restoring => 'Restoring...';

  @override
  String get restore_confirm_title => 'Restore from backup?';

  @override
  String get restore_confirm_body =>
      'Your current data will be replaced. A pre-restore backup will be saved first. Continue?';

  @override
  String get restore_confirm_action => 'Restore';

  @override
  String get restore_success_title => 'Restore complete';

  @override
  String get restore_success_body =>
      'Your data has been restored. Please sign in again.';

  @override
  String get restore_error =>
      'Restore failed. Check the backup and passphrase, then try again.';

  @override
  String get restore_error_closed =>
      'Please close any other instance of the app before restoring.';

  @override
  String get restore_file_required => 'Select a backup file to continue';

  @override
  String get settings_restore_backup => 'Restore from backup';

  @override
  String get export_pdf_title => 'Export PDF';

  @override
  String get export_pdf_subtitle => 'Select clients to export';

  @override
  String get export_pdf_select_all => 'Select all';

  @override
  String get export_pdf_no_selection => 'Select at least one client';

  @override
  String get export_pdf_language => 'PDF language';

  @override
  String get export_pdf_language_follow => 'Follow app';

  @override
  String get export_pdf_allow_print => 'Allow printing';

  @override
  String get export_pdf_password => 'PDF password';

  @override
  String get export_pdf_confirm_password => 'Confirm PDF password';

  @override
  String get export_pdf_password_hint =>
      'At least 8 characters. Required to open the AES-256 encrypted PDF.';

  @override
  String get export_pdf_password_policy_note =>
      'PDF password length is separate from your sign-in passphrase policy.';

  @override
  String get export_pdf_encryption_info =>
      'The PDF is encrypted with AES-256 and requires this password to open. Copying and editing are restricted; accessibility access remains enabled. Printing follows the setting below.';

  @override
  String get export_pdf_export => 'Export PDF';

  @override
  String get export_pdf_exporting => 'Generating PDF...';

  @override
  String get export_pdf_success_title => 'PDF exported';

  @override
  String export_pdf_success_body(String path) {
    return 'The PDF is password-protected. Keep the password separate from the file. Saved to: $path';
  }

  @override
  String get export_pdf_encryption_error =>
      'The PDF could not be encrypted, so no unprotected PDF was exported.';

  @override
  String get export_pdf_error => 'Export failed. Please try again.';

  @override
  String get export_pdf_open_file => 'Share or open PDF';

  @override
  String get export_pdf_empty_clients => 'No active clients to export';

  @override
  String get pdf_doc_title => 'Insurance Policy Overview';

  @override
  String pdf_generated_on(String date) {
    return 'Generated on $date';
  }

  @override
  String pdf_page(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get pdf_section_client => 'Client';

  @override
  String get pdf_section_policies => 'Policies';

  @override
  String get pdf_section_plans => 'Plans';

  @override
  String get pdf_section_riders => 'Riders';

  @override
  String pdf_policy_title(String number) {
    return 'Policy: $number';
  }

  @override
  String pdf_plan_title(String name) {
    return 'Plan: $name';
  }

  @override
  String pdf_rider_title(String name) {
    return 'Rider: $name';
  }

  @override
  String get pdf_not_available => '—';

  @override
  String pdf_footer(String date, int current, int total) {
    return 'Generated on $date · Page $current of $total';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get app_title => '保單管理系統';

  @override
  String get app_tagline => '保險資料安全地儲存於此裝置。';

  @override
  String get action_next => '下一步';

  @override
  String get action_back => '返回';

  @override
  String get action_cancel => '取消';

  @override
  String get action_save => '儲存';

  @override
  String get client_role_holder => '保單持有人';

  @override
  String get client_role_insured => '受保人';

  @override
  String get gender_male => '男';

  @override
  String get gender_female => '女';

  @override
  String get gender_other => '其他';

  @override
  String get policy_status_active => '生效中';

  @override
  String get policy_status_lapsed => '失效';

  @override
  String get policy_status_surrendered => '退保';

  @override
  String get plan_category_life => '壽險';

  @override
  String get plan_category_ci => '危疾';

  @override
  String get plan_category_hospital => '住院';

  @override
  String get plan_category_accident => '意外';

  @override
  String get plan_category_savings => '儲蓄';

  @override
  String get plan_category_other => '其他';

  @override
  String get policy_detail_title => '保單';

  @override
  String get policy_info_section => '保單資料';

  @override
  String get policy_company => '承保公司';

  @override
  String get policy_no => '保單編號';

  @override
  String policy_card_summary(
    String company,
    String effectiveDate,
    String status,
  ) {
    return '$company · $effectiveDate · $status';
  }

  @override
  String get policy_effective_date => '生效日期';

  @override
  String get policy_first_premium_date => '首期保費日';

  @override
  String get policy_currency => '貨幣';

  @override
  String get policy_status => '狀態';

  @override
  String get policy_notes => '備註';

  @override
  String get policy_plans_section => '計劃';

  @override
  String get policy_add_plan => '新增計劃';

  @override
  String get policy_no_plans => '尚無計劃';

  @override
  String get policy_edit => '編輯';

  @override
  String get policy_archive => '封存';

  @override
  String get policy_archive_confirm_title => '封存保單？';

  @override
  String get policy_archive_confirm_body => '此保單將被隱藏。您可從封存區還原。';

  @override
  String get policy_archive_confirm_action => '封存';

  @override
  String get policy_archived_snack => '保單已封存';

  @override
  String get policy_form_title_new => '新增保單';

  @override
  String get policy_form_title_edit => '編輯保單';

  @override
  String get policy_form_save => '儲存';

  @override
  String get policy_form_saving => '儲存中...';

  @override
  String get policy_form_cancel => '取消';

  @override
  String get policy_form_saved => '保單已儲存';

  @override
  String get policy_form_error_company_required => '承保公司為必填';

  @override
  String get policy_form_error_policy_no_required => '保單編號為必填';

  @override
  String get policy_form_error_currency_invalid => '貨幣須為 3 個大寫字母';

  @override
  String get policy_form_error_dates => '首期保費日不得早於生效日期';

  @override
  String policy_form_error_save(String message) {
    return '儲存失敗：$message';
  }

  @override
  String get policy_not_found => '找不到保單';

  @override
  String get plan_detail_title => '計劃';

  @override
  String plan_card_summary(String category, String coverage) {
    return '$category · $coverage';
  }

  @override
  String get plan_category => '類別';

  @override
  String get plan_name => '計劃名稱';

  @override
  String get plan_coverage_amount => '保障額';

  @override
  String get plan_payment_term => '供款期';

  @override
  String get plan_coverage_period => '保障期';

  @override
  String get plan_deductible => '自負額';

  @override
  String get plan_notes => '備註';

  @override
  String get plan_add_rider => '新增附加保障';

  @override
  String get plan_riders_section => '附加保障';

  @override
  String get plan_no_riders => '尚無附加保障';

  @override
  String get plan_remove_rider => '移除';

  @override
  String get plan_archive_confirm_title => '封存計劃？';

  @override
  String get plan_archive_confirm_body => '此計劃將被隱藏。您可從封存區還原。';

  @override
  String get plan_archive_confirm_action => '封存';

  @override
  String get plan_archived_snack => '計劃已封存';

  @override
  String get accessibility_delete => '永久刪除';

  @override
  String get accessibility_restore => '還原';

  @override
  String get plan_form_title_new => '新增計劃';

  @override
  String get plan_form_title_edit => '編輯計劃';

  @override
  String get plan_form_save => '儲存';

  @override
  String get plan_form_saving => '儲存中...';

  @override
  String get plan_form_cancel => '取消';

  @override
  String get plan_form_saved => '計劃已儲存';

  @override
  String get plan_form_error_category_required => '類別為必填';

  @override
  String get plan_form_error_coverage_invalid => '金額必須為零或以上';

  @override
  String get plan_form_error_name_required => '計劃名稱為必填';

  @override
  String plan_form_error_save(String message) {
    return '儲存失敗：$message';
  }

  @override
  String get plan_form_error_partial_save => '計劃已儲存，但部分附加保障變更可能未儲存。請檢查計劃。';

  @override
  String get plan_not_found => '找不到計劃';

  @override
  String get rider_form_title => '附加保障';

  @override
  String get rider_name => '保障名稱';

  @override
  String get rider_coverage_amount => '保障額';

  @override
  String get rider_payment_term => '供款期';

  @override
  String get rider_deductible => '自負額';

  @override
  String get rider_waiting_period => '等候期';

  @override
  String get rider_error_name_required => '保障名稱為必填';

  @override
  String get currency_hkd => 'HKD';

  @override
  String get currency_usd => 'USD';

  @override
  String get currency_cny => 'CNY';

  @override
  String get currency_eur => 'EUR';

  @override
  String get currency_gbp => 'GBP';

  @override
  String get currency_jpy => 'JPY';

  @override
  String get currency_sgd => 'SGD';

  @override
  String get splash_loading => '載入中...';

  @override
  String get setup_title => '設定';

  @override
  String get setup_subtitle => '建立密碼以保護您的資料';

  @override
  String get setup_passphrase => '密碼';

  @override
  String get setup_confirm_passphrase => '確認密碼';

  @override
  String get setup_passphrase_hint => '至少 12 個字元';

  @override
  String get setup_passphrase_mismatch => '兩次輸入的密碼不一致';

  @override
  String get setup_passphrase_too_short => '密碼至少需要 12 個字元';

  @override
  String get setup_create => '建立';

  @override
  String get setup_creating => '建立中...';

  @override
  String get setup_error => '無法完成設定，請再試一次。';

  @override
  String get setupStepPassphrase => '密碼';

  @override
  String get setupStepRecovery => '復原金鑰';

  @override
  String get setupStepBiometric => '生物辨識登記';

  @override
  String setupStepOf(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get recovery_key_dialog_title => '您的復原金鑰';

  @override
  String get recovery_key_dialog_body =>
      '若您忘記密碼，這是唯一能復原資料的方法。\n\n請列印並離線保存。切勿分享。\n\n沒有此金鑰，我們無法為您復原資料。';

  @override
  String get recovery_key_dialog_copy => '複製';

  @override
  String get recovery_key_copied => '復原金鑰已複製到剪貼簿。';

  @override
  String get recovery_key_dialog_confirm => '我已列印並保存';

  @override
  String get setup_recovery_confirmation => '輸入復原金鑰以確認';

  @override
  String get setup_recovery_confirm => '確認復原金鑰';

  @override
  String get setup_biometric_prompt =>
      '登記生物辨識以供日後使用。目前尚未提供生物辨識解鎖；您也可以稍後在設定中管理登記。';

  @override
  String get setup_enable_biometric => '登記生物辨識';

  @override
  String get setup_skip_biometric => '暫時略過';

  @override
  String get recovery_invalid_key => '復原金鑰無效。請檢查後再試。';

  @override
  String get recovery_set_new_passphrase => '設定新密碼以完成資料庫復原。';

  @override
  String get recovery_enter_key => '輸入離線復原金鑰以解鎖資料庫。';

  @override
  String get recovery_key_label => '復原金鑰';

  @override
  String get recovery_working => '請稍候...';

  @override
  String get recovery_reset_passphrase => '儲存新密碼';

  @override
  String get recovery_continue => '繼續';

  @override
  String get recovery_reset_required => '復原後必須設定新密碼。請使用復原金鑰繼續。';

  @override
  String get login_title => '登入';

  @override
  String get login_subtitle => '輸入密碼以解鎖';

  @override
  String get login_passphrase => '密碼';

  @override
  String get login_sign_in => '登入';

  @override
  String get login_signing_in => '登入中...';

  @override
  String login_error(int attempts) {
    return '密碼錯誤。剩餘 $attempts 次嘗試。';
  }

  @override
  String get login_forgot => '忘記密碼？';

  @override
  String get lock_title => '已鎖定';

  @override
  String get lock_subtitle => '輸入密碼以解鎖';

  @override
  String get lock_unlock => '解鎖';

  @override
  String get home_welcome => '歡迎';

  @override
  String get home_coming_soon => '主畫面即將推出';

  @override
  String home_state(String state) {
    return '狀態：$state';
  }

  @override
  String get home_lock => '鎖定';

  @override
  String get home_logout => '登出';

  @override
  String get home_title => '客戶';

  @override
  String get home_search_hint => '搜尋客戶';

  @override
  String get home_filter_all => '全部';

  @override
  String get home_filter_holder => '保單持有人';

  @override
  String get home_filter_insured => '受保人';

  @override
  String get home_add_client => '新增客戶';

  @override
  String get home_empty_title => '尚無客戶';

  @override
  String get home_empty_subtitle => '點擊 + 新增第一位客戶';

  @override
  String home_policy_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 張保單',
      one: '1 張保單',
      zero: '無保單',
    );
    return '$_temp0';
  }

  @override
  String home_load_error(String message) {
    return '載入客戶失敗：$message';
  }

  @override
  String get home_no_match => '沒有符合的客戶';

  @override
  String get home_detail_prompt => '選擇客戶以查看資料';

  @override
  String get home_open_details => '查看資料';

  @override
  String get nav_home => '首頁';

  @override
  String get nav_archive => '封存';

  @override
  String get nav_settings => '設定';

  @override
  String get client_detail_title => '客戶';

  @override
  String get client_info_section => '客戶資料';

  @override
  String get client_name => '姓名';

  @override
  String get client_role => '身份';

  @override
  String get client_gender => '性別';

  @override
  String get client_dob => '出生日期';

  @override
  String get client_phone => '電話';

  @override
  String get client_email => '電郵';

  @override
  String get client_notes => '備註';

  @override
  String get client_policies_section => '保單';

  @override
  String get client_reviews_section => '保單檢視';

  @override
  String get client_no_reviews => '尚無檢視記錄';

  @override
  String get client_add_policy => '新增保單';

  @override
  String get client_no_policies => '尚無保單';

  @override
  String get client_edit => '編輯';

  @override
  String get client_archive => '封存';

  @override
  String get client_archive_confirm_title => '封存客戶？';

  @override
  String get client_archive_confirm_body => '此客戶將從清單中隱藏。您可從封存區還原。';

  @override
  String get client_archive_confirm_action => '封存';

  @override
  String get client_archive_cancel => '取消';

  @override
  String get client_archive_error => '無法封存客戶，請再試一次。';

  @override
  String get client_archived_snack => '客戶已封存';

  @override
  String get lock_app => '鎖定應用程式';

  @override
  String get search_field_label => '搜尋客戶';

  @override
  String get client_form_title_new => '新增客戶';

  @override
  String get client_form_title_edit => '編輯客戶';

  @override
  String get client_form_save => '儲存';

  @override
  String get client_form_saving => '儲存中...';

  @override
  String get client_form_cancel => '取消';

  @override
  String get client_form_error_name_required => '姓名為必填';

  @override
  String get client_form_error_dob_required => '出生日期為必填';

  @override
  String get client_form_error_save => '無法儲存客戶，請再試一次。';

  @override
  String get client_form_saved => '客戶已儲存';

  @override
  String get client_not_found => '找不到客戶';

  @override
  String get archive_title => '封存區';

  @override
  String get archive_tab_clients => '客戶';

  @override
  String get archive_tab_policies => '保單';

  @override
  String get archive_tab_plans => '計劃';

  @override
  String get archive_empty_clients => '尚無封存的客戶';

  @override
  String get archive_empty_policies => '尚無封存的保單';

  @override
  String get archive_empty_plans => '尚無封存的計劃';

  @override
  String get archive_restore => '還原';

  @override
  String get archive_delete => '永久刪除';

  @override
  String get archive_restore_success => '已還原';

  @override
  String get archive_delete_success => '已永久刪除';

  @override
  String archive_archived_on(String date) {
    return '封存於 $date';
  }

  @override
  String get archive_delete_confirm_title => '確定永久刪除？';

  @override
  String get archive_delete_confirm_body_1 => '此操作將永久刪除記錄及所有相關資料，且無法復原。';

  @override
  String get archive_delete_confirm_body_2 => '您確定要繼續？這是最後的取消機會。';

  @override
  String get archive_delete_confirm_action => '永久刪除';

  @override
  String get archive_delete_cancel => '取消';

  @override
  String get archive_delete_continue => '繼續';

  @override
  String get archive_delete_final => '刪除';

  @override
  String get archive_restore_confirm_title => '還原記錄？';

  @override
  String get archive_restore_confirm_body => '記錄將重新出現在主清單中。';

  @override
  String get archive_restore_confirm_action => '還原';

  @override
  String archive_error_restore(String message) {
    return '還原失敗：$message';
  }

  @override
  String archive_error_delete(String message) {
    return '刪除失敗：$message';
  }

  @override
  String get settings_title => '設定';

  @override
  String get settings_coming_soon => '設定即將推出';

  @override
  String get settings_coming_soon_body => '此功能將於未來更新提供。';

  @override
  String get settings_logout => '登出';

  @override
  String get settings_logout_confirm_title => '確定登出？';

  @override
  String get settings_logout_confirm_body => '您將需要密碼才能再次登入。';

  @override
  String get settings_logout_confirm_action => '登出';

  @override
  String get settings_general => '一般';

  @override
  String get settings_security => '安全性';

  @override
  String get settings_backup => '備份';

  @override
  String get settings_audit => '稽核';

  @override
  String get settings_about => '關於';

  @override
  String get settings_danger => '危險區域';

  @override
  String get settings_language => '語言';

  @override
  String get settings_language_english => 'English';

  @override
  String get settings_language_traditional_chinese => '繁體中文';

  @override
  String get settings_theme => '主題';

  @override
  String get settings_theme_system => '跟隨系統';

  @override
  String get settings_theme_light => '淺色';

  @override
  String get settings_theme_dark => '深色';

  @override
  String get settings_auto_lock => '自動鎖定';

  @override
  String settings_minutes(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get settings_biometric => '生物辨識登記';

  @override
  String get settings_biometric_unavailable => '此裝置不支援';

  @override
  String get settings_biometric_reason => '請確認為此應用程式登記生物辨識';

  @override
  String get biometricUnlockDeferred => '已儲存登記狀態，但目前尚未提供生物辨識解鎖。';

  @override
  String get settings_change_passphrase => '更改密碼';

  @override
  String get settings_regenerate_recovery => '重新產生復原金鑰';

  @override
  String get settings_current_passphrase => '目前密碼';

  @override
  String get settings_new_passphrase => '新密碼';

  @override
  String get settings_passphrase_save => '更改密碼';

  @override
  String get settings_passphrase_changed => '密碼已更改。';

  @override
  String get settings_passphrase_change_failed => '無法更改密碼。請檢查目前密碼後再試。';

  @override
  String get settings_recovery_regenerate_action => '重新產生';

  @override
  String get settings_recovery_regenerate_failed => '無法重新產生復原金鑰。請檢查密碼後再試。';

  @override
  String get settings_max_attempts => '最大失敗次數';

  @override
  String get settings_max_attempts_preference_only => '只儲存偏好設定；登入限制維持不變。';

  @override
  String settings_attempts(int attempts) {
    return '$attempts 次';
  }

  @override
  String get settings_auto_backup => '自動備份';

  @override
  String get settings_auto_backup_note => '已儲存頻率設定；自動排程備份尚未啟用。';

  @override
  String get settings_backup_off => '關閉';

  @override
  String get settings_backup_daily => '每日';

  @override
  String get settings_backup_weekly => '每週';

  @override
  String get settings_backup_folder => '備份資料夾';

  @override
  String get settings_backup_folder_default => '預設位置';

  @override
  String get settings_backup_now => '立即備份';

  @override
  String get settings_backup_coming => '備份功能將於下次更新推出';

  @override
  String get settings_view_audit => '檢視稽核記錄';

  @override
  String get settings_audit_retention => '稽核記錄保留';

  @override
  String get settings_audit_retention_value => '2 年';

  @override
  String get settings_version => '版本';

  @override
  String get settings_privacy_policy => '隱私政策';

  @override
  String get settings_privacy_policy_body =>
      '本應用程式將所有資料儲存在您的裝置本機。不會傳送任何資料到伺服器。加密金鑰儲存在裝置的安全儲存區。備份以您選擇的密碼加密。';

  @override
  String get settings_reset_app => '重設應用程式';

  @override
  String get settings_coming_soon_title => '即將推出';

  @override
  String get audit_log_title => '稽核記錄';

  @override
  String get audit_filter_all => '所有事件';

  @override
  String get audit_filter_from => '從';

  @override
  String get audit_filter_to => '至';

  @override
  String get audit_filter_any_date => '任何日期';

  @override
  String audit_filter_date_range(String from, String to) {
    return '$from — $to';
  }

  @override
  String get audit_filter_clear => '清除篩選';

  @override
  String get audit_verify => '驗證鏈結';

  @override
  String get audit_chain_unverified => '尚未驗證 — 點擊 ✓ 驗證';

  @override
  String audit_chain_valid(int count) {
    return '鏈結驗證成功（$count 筆）';
  }

  @override
  String audit_chain_broken(int index, String reason) {
    return '鏈結於第 $index 筆中斷：$reason';
  }

  @override
  String get audit_verify_error => '無法驗證稽核鏈結。';

  @override
  String get audit_empty => '沒有符合篩選條件的記錄';

  @override
  String get audit_load_more => '載入更多';

  @override
  String get audit_entry_details => '記錄詳情';

  @override
  String get audit_copy_json => '複製 JSON';

  @override
  String get audit_copied => '已複製';

  @override
  String get audit_event_type => '事件類型';

  @override
  String get audit_timestamp => '時間';

  @override
  String get audit_entity => '實體';

  @override
  String get audit_entity_id => '實體 ID';

  @override
  String get audit_entity_none => '無';

  @override
  String get audit_metadata => '中繼資料';

  @override
  String get audit_prev_hash => '前一雜湊';

  @override
  String get audit_entry_hash => '項目雜湊';

  @override
  String get audit_event_app_setup => '應用程式設定';

  @override
  String get audit_event_login_success => '登入成功';

  @override
  String get audit_event_login_fail => '登入失敗';

  @override
  String get audit_event_logout => '登出';

  @override
  String get audit_event_auto_lock => '自動鎖定';

  @override
  String get audit_event_recovery_used => '使用復原金鑰';

  @override
  String get audit_event_recovery_key_rotated => '復原金鑰已更新';

  @override
  String get audit_event_passphrase_changed => '密碼已更改';

  @override
  String get audit_event_create => '建立';

  @override
  String get audit_event_update => '更新';

  @override
  String get audit_event_archive => '封存';

  @override
  String get audit_event_restore => '還原';

  @override
  String get audit_event_delete => '刪除';

  @override
  String get audit_event_export_pdf => '匯出 PDF';

  @override
  String get audit_event_backup => '備份';

  @override
  String get audit_event_restore_db => '從備份還原';

  @override
  String get audit_event_migration => '資料庫遷移';

  @override
  String get audit_event_purge => '清理';

  @override
  String get action_retry => '重試';

  @override
  String get error_generic => '發生錯誤，請再試一次。';

  @override
  String get recovery_title => '復原';

  @override
  String get coming_soon => '即將推出';

  @override
  String get key_state_uninitialized => '尚未設定';

  @override
  String get key_state_locked => '已鎖定';

  @override
  String get key_state_unlocked => '已解鎖';

  @override
  String get backup_title => '備份';

  @override
  String get backup_subtitle => '建立資料的加密備份';

  @override
  String get backup_info_card_title => '加密備份';

  @override
  String get backup_info_card_body => '備份以您選擇的密碼加密。請妥善保存此密碼——沒有它，備份將無法還原。';

  @override
  String get backup_passphrase => '備份密碼';

  @override
  String get backup_confirm_passphrase => '確認備份密碼';

  @override
  String get backup_passphrase_hint => '至少 12 個字元';

  @override
  String get backup_choose_destination => '選擇目的地';

  @override
  String backup_destination_selected(String path) {
    return '目的地：$path';
  }

  @override
  String get backup_create => '建立備份';

  @override
  String get backup_creating => '建立中...';

  @override
  String get backup_success_title => '備份已建立';

  @override
  String backup_success_body(String path) {
    return '備份已儲存至：$path';
  }

  @override
  String get backup_error => '備份失敗，請再試一次。';

  @override
  String get backup_open_folder => '查看儲存位置';

  @override
  String backup_last_backup(String date) {
    return '上次備份：$date';
  }

  @override
  String backup_last_backup_size(String size) {
    return '備份大小：$size 位元組';
  }

  @override
  String get backup_never => '尚無備份';

  @override
  String get backup_password_mismatch => '兩次輸入的密碼不一致';

  @override
  String get backup_destination_required => '請先選擇目的地';

  @override
  String get restore_title => '還原';

  @override
  String get restore_warning => '還原將覆寫目前所有資料。系統會先自動建立還原前備份。';

  @override
  String get restore_select_file => '選擇備份檔案';

  @override
  String restore_file_selected(String name) {
    return '檔案：$name';
  }

  @override
  String get restore_passphrase => '備份密碼';

  @override
  String get restore_confirm_checkbox => '我了解還原將覆寫目前資料';

  @override
  String get restore_action => '立即還原';

  @override
  String get restore_restoring => '還原中...';

  @override
  String get restore_confirm_title => '從備份還原？';

  @override
  String get restore_confirm_body => '目前資料將被取代，系統會先儲存還原前備份。是否繼續？';

  @override
  String get restore_confirm_action => '還原';

  @override
  String get restore_success_title => '還原完成';

  @override
  String get restore_success_body => '資料已還原。請重新登入。';

  @override
  String get restore_error => '還原失敗。請檢查備份檔案及密碼，然後再試。';

  @override
  String get restore_error_closed => '請先關閉任何其他應用程式實例。';

  @override
  String get restore_file_required => '請先選擇備份檔案';

  @override
  String get settings_restore_backup => '從備份還原';

  @override
  String get export_pdf_title => '匯出 PDF';

  @override
  String get export_pdf_subtitle => '選擇要匯出的客戶';

  @override
  String get export_pdf_select_all => '全選';

  @override
  String get export_pdf_no_selection => '請至少選擇一位客戶';

  @override
  String get export_pdf_language => 'PDF 語言';

  @override
  String get export_pdf_language_follow => '跟隨應用程式';

  @override
  String get export_pdf_allow_print => '允許列印';

  @override
  String get export_pdf_password => 'PDF 密碼';

  @override
  String get export_pdf_confirm_password => '確認 PDF 密碼';

  @override
  String get export_pdf_password_hint => '至少 8 個字元。開啟 AES-256 加密 PDF 時必須輸入此密碼。';

  @override
  String get export_pdf_password_policy_note => 'PDF 密碼長度與登入密碼政策分開。';

  @override
  String get export_pdf_encryption_info =>
      'PDF 使用 AES-256 加密，開啟時必須輸入此密碼。複製及編輯功能受到限制；仍允許輔助工具存取。列印權限依下方設定。';

  @override
  String get export_pdf_export => '匯出 PDF';

  @override
  String get export_pdf_exporting => '正在產生 PDF...';

  @override
  String get export_pdf_success_title => 'PDF 已匯出';

  @override
  String export_pdf_success_body(String path) {
    return 'PDF 已受密碼保護。請將密碼與檔案分開保存。已儲存至：$path';
  }

  @override
  String get export_pdf_encryption_error => '無法加密 PDF，因此未匯出未受保護的檔案。';

  @override
  String get export_pdf_error => '匯出失敗，請再試一次。';

  @override
  String get export_pdf_open_file => '分享或開啟 PDF';

  @override
  String get export_pdf_empty_clients => '沒有可供匯出的有效客戶';

  @override
  String get pdf_doc_title => '保險保障總覽';

  @override
  String pdf_generated_on(String date) {
    return '產生於 $date';
  }

  @override
  String pdf_page(int current, int total) {
    return '第 $current / $total 頁';
  }

  @override
  String get pdf_section_client => '客戶';

  @override
  String get pdf_section_policies => '保單';

  @override
  String get pdf_section_plans => '計劃';

  @override
  String get pdf_section_riders => '附加保障';

  @override
  String pdf_policy_title(String number) {
    return '保單：$number';
  }

  @override
  String pdf_plan_title(String name) {
    return '計劃：$name';
  }

  @override
  String pdf_rider_title(String name) {
    return '附加保障：$name';
  }

  @override
  String get pdf_not_available => '—';

  @override
  String pdf_footer(String date, int current, int total) {
    return '產生於 $date · 第 $current / $total 頁';
  }
}
