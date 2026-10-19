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

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

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
  String get login_biometric => '使用生物辨識解鎖';

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
  String get archive_title => '封存';

  @override
  String get settings_title => '設定';

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
}
