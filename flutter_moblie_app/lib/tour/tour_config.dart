import 'package:flutter/material.dart';

/// Defines a single step in the onboarding tour.
class TourStep {
  final String id;
  final GlobalKey key;
  final String title;
  final String description;
  final String screen;

  const TourStep({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.screen,
  });
}

/// Central registry of all onboarding tour steps, organized by screen.
///
/// GlobalKeys are declared here so they can be imported and attached
/// to the corresponding widgets across the app.
class TourConfig {
  TourConfig._();

  // ──────────────────────────────────────────────────────────────────────────
  // HOME SCREEN (Patient) — categoriesScreen / HomeScreen
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey homeMenuKey = GlobalKey(debugLabel: 'tour_home_menu');
  static final GlobalKey homeCityDropdownKey =
      GlobalKey(debugLabel: 'tour_home_city_dropdown');
  static final GlobalKey homeChatBannerKey =
      GlobalKey(debugLabel: 'tour_home_chat_banner');
  static final GlobalKey homeCategoriesGridKey =
      GlobalKey(debugLabel: 'tour_home_categories_grid');
  static final GlobalKey homePromoBannerKey =
      GlobalKey(debugLabel: 'tour_home_promo_banner');

  // ──────────────────────────────────────────────────────────────────────────
  // HOME DRAWER (Patient)
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey drawerHomeKey =
      GlobalKey(debugLabel: 'tour_drawer_home');
  static final GlobalKey drawerChatKey =
      GlobalKey(debugLabel: 'tour_drawer_chat');
  static final GlobalKey drawerDarkModeKey =
      GlobalKey(debugLabel: 'tour_drawer_dark_mode');
  static final GlobalKey drawerLanguageKey =
      GlobalKey(debugLabel: 'tour_drawer_language');
  static final GlobalKey drawerTermsKey =
      GlobalKey(debugLabel: 'tour_drawer_terms');
  static final GlobalKey drawerPrivacyKey =
      GlobalKey(debugLabel: 'tour_drawer_privacy');
  static final GlobalKey drawerHelpKey =
      GlobalKey(debugLabel: 'tour_drawer_help');
  static final GlobalKey drawerLoginKey =
      GlobalKey(debugLabel: 'tour_drawer_login');

  // ──────────────────────────────────────────────────────────────────────────
  // LOGIN SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey loginEmailFieldKey =
      GlobalKey(debugLabel: 'tour_login_email');
  static final GlobalKey loginPasswordFieldKey =
      GlobalKey(debugLabel: 'tour_login_password');
  static final GlobalKey loginButtonKey =
      GlobalKey(debugLabel: 'tour_login_button');
  static final GlobalKey loginForgotPasswordKey =
      GlobalKey(debugLabel: 'tour_login_forgot_password');
  static final GlobalKey loginSignUpLinkKey =
      GlobalKey(debugLabel: 'tour_login_signup_link');
  static final GlobalKey loginBackToHomeKey =
      GlobalKey(debugLabel: 'tour_login_back_home');

  // ──────────────────────────────────────────────────────────────────────────────
  // SIGN UP SCREEN
  // ──────────────────────────────────────────────────────────────────────────────
  static final GlobalKey signUpNameFieldKey =
      GlobalKey(debugLabel: 'tour_signup_name');
  static final GlobalKey signUpEmailFieldKey =
      GlobalKey(debugLabel: 'tour_signup_email');
  static final GlobalKey signUpPhoneFieldKey =
      GlobalKey(debugLabel: 'tour_signup_phone');
  static final GlobalKey signUpCollegeDropdownKey =
      GlobalKey(debugLabel: 'tour_signup_college');
  static final GlobalKey signUpGovernorateDropdownKey =
      GlobalKey(debugLabel: 'tour_signup_governorate');
  static final GlobalKey signUpSpecialtyDropdownKey =
      GlobalKey(debugLabel: 'tour_signup_specialty');
  static final GlobalKey signUpPasswordFieldKey =
      GlobalKey(debugLabel: 'tour_signup_password');
  static final GlobalKey signUpButtonKey =
      GlobalKey(debugLabel: 'tour_signup_button');
  static final GlobalKey signUpLoginLinkKey =
      GlobalKey(debugLabel: 'tour_signup_login_link');
  // ──────────────────────────────────────────────────────────────────────────
  // DOCTOR HOME SCREEN (Authenticated)
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey doctorHomeMenuKey =
      GlobalKey(debugLabel: 'tour_doctor_home_menu');
  static final GlobalKey doctorHomeNotificationsKey =
      GlobalKey(debugLabel: 'tour_doctor_home_notifications');
  static final GlobalKey doctorHomePendingKey =
      GlobalKey(debugLabel: 'tour_doctor_home_pending');
  static final GlobalKey doctorHomeConfirmedKey =
      GlobalKey(debugLabel: 'tour_doctor_home_confirmed');

  // ──────────────────────────────────────────────────────────────────────────
  // DOCTOR DRAWER
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey doctorDrawerHomeKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_home');
  static final GlobalKey doctorDrawerAddCaseKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_add_case');
  static final GlobalKey doctorDrawerProfileKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_profile');
  static final GlobalKey doctorDrawerUpcomingKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_upcoming');
  static final GlobalKey doctorDrawerHistoryKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_history');
  static final GlobalKey doctorDrawerConfirmedKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_confirmed');
  static final GlobalKey doctorDrawerRequestsKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_requests');
  static final GlobalKey doctorDrawerDarkModeKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_dark_mode');
  static final GlobalKey doctorDrawerLanguageKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_language');
  static final GlobalKey doctorDrawerAboutKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_about');
  static final GlobalKey doctorDrawerTermsKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_terms');
  static final GlobalKey doctorDrawerPrivacyKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_privacy');
  static final GlobalKey doctorDrawerHelpKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_help');
  static final GlobalKey doctorDrawerLogoutKey =
      GlobalKey(debugLabel: 'tour_doctor_drawer_logout');

  // ─── MY REQUESTS SCREEN ──────────────────────────────────────────
  static final GlobalKey myRequestsTitleKey =
      GlobalKey(debugLabel: 'tour_my_requests_title');
  static final GlobalKey myRequestsCardKey =
      GlobalKey(debugLabel: 'tour_my_requests_card');
  static final GlobalKey myRequestsEditKey =
      GlobalKey(debugLabel: 'tour_my_requests_edit');
  static final GlobalKey myRequestsDeleteKey =
      GlobalKey(debugLabel: 'tour_my_requests_delete');

  // ─── ADD CASE REQUEST SCREEN ─────────────────────────────────────
  static final GlobalKey addCaseInfoKey =
      GlobalKey(debugLabel: 'tour_add_case_info');
  static final GlobalKey addCaseDateTimeKey =
      GlobalKey(debugLabel: 'tour_add_case_datetime');
  static final GlobalKey addCaseDescriptionKey =
      GlobalKey(debugLabel: 'tour_add_case_description');
  static final GlobalKey addCaseSubmitKey =
      GlobalKey(debugLabel: 'tour_add_case_submit');

  // ──────────────────────────────────────────────────────────────────────────
  // CHAT SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey chatBackButtonKey =
      GlobalKey(debugLabel: 'tour_chat_back');
  static final GlobalKey chatInputFieldKey =
      GlobalKey(debugLabel: 'tour_chat_input');

  // ──────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey notifFilterKey =
      GlobalKey(debugLabel: 'tour_notif_filter');

  // ──────────────────────────────────────────────────────────────────────────
  // CATEGORY DOCTORS SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  static final GlobalKey categoryFabKey =
      GlobalKey(debugLabel: 'tour_category_fab');

  // ──────────────────────────────────────────────────────────────────────────
  // ALL STEPS — keyed by screen name for easy lookup
  // ──────────────────────────────────────────────────────────────────────────

  static List<TourStep> get allSteps => [
        // ─── HOME SCREEN ─────────────────────────────────────────────
        TourStep(
          id: 'home_menu',
          key: homeMenuKey,
          title: 'القائمة الرئيسية',
          description: 'اضغط هنا لفتح القائمة الجانبية والوصول للإعدادات',
          screen: 'home',
        ),
        TourStep(
          id: 'home_promo_banner',
          key: homePromoBannerKey,
          title: 'بانر الحجز',
          description: 'تعرّف على خدمات الحجز مع أفضل أطباء الأسنان',
          screen: 'home',
        ),
        TourStep(
          id: 'home_city_dropdown',
          key: homeCityDropdownKey,
          title: 'اختيار المحافظة',
          description: 'اختر محافظتك لعرض الأطباء القريبين منك',
          screen: 'home',
        ),
        TourStep(
          id: 'home_chat_banner',
          key: homeChatBannerKey,
          title: 'مساعد ثوثة الذكي',
          description:
              'لا تعرف ماذا تحتاج؟ اضغط هنا للتحدث مع المساعد الذكي',
          screen: 'home',
        ),
        TourStep(
          id: 'home_categories_grid',
          key: homeCategoriesGridKey,
          title: 'الخدمات المتاحة',
          description: 'اختر التخصص المطلوب لعرض الأطباء وحجز موعد',
          screen: 'home',
        ),

        // ─── HOME DRAWER ─────────────────────────────────────────────
        TourStep(
          id: 'drawer_home',
          key: drawerHomeKey,
          title: 'الرئيسية',
          description: 'ارجع لصفحة التصفح الرئيسية',
          screen: 'home_drawer',
        ),
        TourStep(
          id: 'drawer_chat',
          key: drawerChatKey,
          title: 'مساعد ثوثة',
          description: 'تحدث مع المساعد الذكي للحصول على توصيات',
          screen: 'home_drawer',
        ),

        TourStep(
          id: 'drawer_language',
          key: drawerLanguageKey,
          title: 'تغيير اللغة',
          description: 'بدّل بين العربية والإنجليزية',
          screen: 'home_drawer',
        ),

        TourStep(
          id: 'drawer_login',
          key: drawerLoginKey,
          title: 'تسجيل الدخول',
          description: 'سجّل دخولك كطبيب لإدارة حجوزاتك',
          screen: 'home_drawer',
        ),



        // ─── DOCTOR HOME ─────────────────────────────────────────────
        TourStep(
          id: 'doctor_home_menu',
          key: doctorHomeMenuKey,
          title: 'القائمة',
          description: 'افتح القائمة الجانبية لإدارة حسابك وحجوزاتك',
          screen: 'doctor_home',
        ),
        TourStep(
          id: 'doctor_home_notifications',
          key: doctorHomeNotificationsKey,
          title: 'الإشعارات',
          description: 'اضغط لعرض إشعارات الحجوزات الجديدة',
          screen: 'doctor_home',
        ),
        TourStep(
          id: 'doctor_home_pending',
          key: doctorHomePendingKey,
          title: 'الحجوزات المعلّقة',
          description: 'حجوزات تحتاج قبولك أو رفضك',
          screen: 'doctor_home',
        ),
        TourStep(
          id: 'doctor_home_confirmed',
          key: doctorHomeConfirmedKey,
          title: 'الحالات المؤكدة',
          description: 'الحجوزات التي تم قبولها وتأكيدها',
          screen: 'doctor_home',
        ),

        // ─── DOCTOR DRAWER ───────────────────────────────────────────
        TourStep(
          id: 'doctor_drawer_home',
          key: doctorDrawerHomeKey,
          title: 'الرئيسية',
          description: 'ارجع للصفحة الرئيسية لعرض حجوزاتك',
          screen: 'doctor_drawer',
        ),
        TourStep(
          id: 'doctor_drawer_add_case',
          key: doctorDrawerAddCaseKey,
          title: 'إضافة حالة جديدة',
          description: 'أنشئ حالة جديدة ليراها المرضى ويحجزوا',
          screen: 'doctor_drawer',
        ),
        TourStep(
          id: 'doctor_drawer_profile',
          key: doctorDrawerProfileKey,
          title: 'الملف الشخصي',
          description: 'عدّل بيانات ملفك الشخصي والصورة',
          screen: 'doctor_drawer',
        ),
        TourStep(
          id: 'doctor_drawer_upcoming',
          key: doctorDrawerUpcomingKey,
          title: 'الحجوزات القادمة',
          description: 'اعرض جميع حجوزاتك القادمة',
          screen: 'doctor_drawer',
        ),
        TourStep(
          id: 'doctor_drawer_history',
          key: doctorDrawerHistoryKey,
          title: 'سجل الحجوزات',
          description: 'راجع تاريخ حجوزاتك السابقة',
          screen: 'doctor_drawer',
        ),
        TourStep(
          id: 'doctor_drawer_confirmed',
          key: doctorDrawerConfirmedKey,
          title: 'الحجوزات المؤكدة',
          description: 'اعرض الحجوزات التي تم تأكيدها وقبولها',
          screen: 'doctor_drawer',
        ),
        TourStep(
          id: 'doctor_drawer_requests',
          key: doctorDrawerRequestsKey,
          title: 'طلباتي',
          description: 'أدِر طلبات الحالات التي نشرتها',
          screen: 'doctor_drawer',
        ),

        // ─── MY REQUESTS SCREEN ──────────────────────────────────────
        TourStep(
          id: 'my_requests_title',
          key: myRequestsTitleKey,
          title: 'طلباتي',
          description: 'هنا تجد جميع طلبات الحالات التي قمت بنشرها',
          screen: 'my_requests',
        ),
        TourStep(
          id: 'my_requests_card',
          key: myRequestsCardKey,
          title: 'بيانات الطلب',
          description: 'تظهر هنا تفاصيل الحالة والجامعة والموعد المحدد',
          screen: 'my_requests',
        ),
        TourStep(
          id: 'my_requests_edit',
          key: myRequestsEditKey,
          title: 'تعديل الطلب',
          description: 'يمكنك تعديل تفاصيل الحالة أو الموعد في أي وقت',
          screen: 'my_requests',
        ),
        TourStep(
          id: 'my_requests_delete',
          key: myRequestsDeleteKey,
          title: 'حذف الطلب',
          description: 'إذا لم تعد الحالة متاحة، يمكنك حذفها من هنا',
          screen: 'my_requests',
        ),

        // ─── ADD CASE REQUEST SCREEN ─────────────────────────────────
        TourStep(
          id: 'add_case_info',
          key: addCaseInfoKey,
          title: 'بياناتك الشخصية',
          description: 'يتم ملء اسمك وتخصصك تلقائياً من ملفك الشخصي',
          screen: 'add_case',
        ),
        TourStep(
          id: 'add_case_datetime',
          key: addCaseDateTimeKey,
          title: 'تحديد الموعد',
          description: 'اختر التاريخ والوقت المناسبين لاستقبال الحالة',
          screen: 'add_case',
        ),
        TourStep(
          id: 'add_case_description',
          key: addCaseDescriptionKey,
          title: 'وصف الحالة',
          description: 'أضف أي تفاصيل إضافية تساعد المريض على فهم الحالة',
          screen: 'add_case',
        ),
        TourStep(
          id: 'add_case_submit',
          key: addCaseSubmitKey,
          title: 'نشر الطلب',
          description: 'اضغط هنا ليتم نشر الحالة وتظهر للمرضى في التطبيق',
          screen: 'add_case',
        ),




        // ─── CHAT SCREEN ─────────────────────────────────────────────
        TourStep(
          id: 'chat_back',
          key: chatBackButtonKey,
          title: 'الرجوع',
          description: 'اضغط للعودة للصفحة السابقة',
          screen: 'chat',
        ),
        TourStep(
          id: 'chat_input',
          key: chatInputFieldKey,
          title: 'حقل الرسائل',
          description: 'اكتب رسالتك هنا للتحدث مع المساعد الذكي',
          screen: 'chat',
        ),

        // ─── NOTIFICATIONS SCREEN ────────────────────────────────────
        TourStep(
          id: 'notif_filter',
          key: notifFilterKey,
          title: 'تصفية الإشعارات',
          description: 'فلتر لعرض الإشعارات غير المقروءة فقط',
          screen: 'notifications',
        ),

        // ─── CATEGORY DOCTORS SCREEN ─────────────────────────────────
        TourStep(
          id: 'category_fab',
          key: categoryFabKey,
          title: 'نشر حالة جديدة',
          description: 'اضغط لنشر حالة جديدة في هذا التخصص',
          screen: 'category_doctors',
        ),
      ];

  /// Returns only the steps belonging to [screenName].
  static List<TourStep> stepsForScreen(String screenName) =>
      allSteps.where((s) => s.screen == screenName).toList();
}
