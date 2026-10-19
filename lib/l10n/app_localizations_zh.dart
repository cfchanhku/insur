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
}
