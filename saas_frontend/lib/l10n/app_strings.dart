import 'package:flutter/material.dart';

/// Central translation file for all app strings.
/// Usage: context.tr('key')  OR  AppStrings.t('key', isAr)
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    // ── General ──────────────────────────────────────────────────────────────
    'appTitle': {'en': 'Smart Booking System', 'ar': 'نظام الحجوزات الذكي'},
    'cancel': {'en': 'Cancel', 'ar': 'الغاء'},
    'save': {'en': 'Save', 'ar': 'حفظ'},
    'delete': {'en': 'Delete', 'ar': 'حذف'},
    'edit': {'en': 'Edit', 'ar': 'تعديل'},
    'ok': {'en': 'OK', 'ar': 'موافق'},
    'logout': {'en': 'Logout', 'ar': 'تسجيل الخروج'},
    'error': {'en': 'Error', 'ar': 'خطأ'},
    'loading': {'en': 'Loading...', 'ar': 'جاري التحميل...'},
    'required': {'en': 'Required', 'ar': 'مطلوب'},
    'language': {'en': 'العربية', 'ar': 'English'},

    // ── Navigation ───────────────────────────────────────────────────────────
    'navDashboard': {'en': 'Dashboard', 'ar': 'لوحة التحكم'},
    'navCalendar': {'en': 'Calendar', 'ar': 'التقويم'},
    'navPos': {'en': 'POS Entry', 'ar': 'نقطة البيع'},
    'navBookChalet': {'en': 'Book Chalet', 'ar': 'حجز شاليه'},
    'navSubscriptions': {'en': 'Subscriptions', 'ar': 'الاشتراكات'},
    'navUsers': {'en': 'Users', 'ar': 'المستخدمون'},

    // ── Login ─────────────────────────────────────────────────────────────────
    'loginTitle': {'en': 'Smart Booking System', 'ar': 'نظام الحجوزات الذكي'},
    'loginSubtitle': {
      'en': 'Sign in to your account',
      'ar': 'سجل الدخول إلى حسابك',
    },
    'loginField': {
      'en': 'Email or Username',
      'ar': 'البريد الإلكتروني أو اسم المستخدم',
    },
    'loginPassword': {'en': 'Password', 'ar': 'كلمة المرور'},
    'loginButton': {'en': 'Login', 'ar': 'دخول'},
    'loginDemoLabel': {'en': 'Demo Accounts:', 'ar': 'حسابات تجريبية:'},

    // ── Dashboard ─────────────────────────────────────────────────────────────
    'dashTitle': {'en': 'Dashboard', 'ar': 'لوحة التحكم'},
    'dashTotalBookings': {'en': 'Total Bookings', 'ar': 'إجمالي الحجوزات'},
    'dashTodayBookings': {'en': "Today's Bookings", 'ar': 'حجوزات اليوم'},
    'dashTotalRevenue': {'en': 'Total Revenue', 'ar': 'إجمالي الإيرادات'},
    'dashActiveMembers': {'en': 'Active Members', 'ar': 'الأعضاء النشطون'},
    'dashActiveSubs': {
      'en': 'Active Subscriptions',
      'ar': 'الاشتراكات الفعّالة',
    },
    'dashExpiringSoon': {'en': 'Expiring Soon', 'ar': 'تنتهي قريباً'},
    'dashRecentBookings': {'en': 'Recent Bookings', 'ar': 'أحدث الحجوزات'},
    'dashNoBookings': {'en': 'No bookings yet', 'ar': 'لا توجد حجوزات بعد'},
    'dashFullDay': {'en': 'Full Day', 'ar': 'يوم كامل'},
    'dashHourly': {'en': 'Hourly', 'ar': 'بالساعة'},

    // ── Calendar ──────────────────────────────────────────────────────────────
    'calTitle': {'en': 'Bookings Calendar', 'ar': 'تقويم الحجوزات'},
    'calSelectDay': {
      'en': 'Select a day to see bookings',
      'ar': 'اختر يوماً لعرض الحجوزات',
    },
    'calBookingsOn': {'en': 'Bookings on', 'ar': 'الحجوزات في'},
    'calNoBookings': {
      'en': 'No bookings on this day',
      'ar': 'لا توجد حجوزات في هذا اليوم',
    },
    'calFullDayBlock': {'en': 'Full Day Block', 'ar': 'حجز يوم كامل'},
    'calBookings': {'en': 'booking(s)', 'ar': 'حجز'},
    'calFullDay': {'en': 'Full Day', 'ar': 'يوم كامل'},
    'calHourly': {'en': 'Hourly', 'ar': 'بالساعة'},

    // ── POS ───────────────────────────────────────────────────────────────────
    'posTitle': {'en': 'Quick POS Entry', 'ar': 'إدخال سريع - نقطة البيع'},
    'posCustomer': {'en':'Customer','ar':'عميل'},
    'posNewBooking': {
      'en': 'New Booking / Walk-in',
      'ar': 'حجز جديد / زيارة مباشرة',
    },
    'posCustomerName': {
      'en': 'Customer Name (optional)',
      'ar': 'اسم العميل (اختياري)',
    },
    'SelectCustomer': {
      'en': 'Select Customer...',
      'ar': '...بحث عن عميل',
    },
    'posDate': {'en': 'Date:', 'ar': 'التاريخ:'},
    'posChangeDate': {
      'en': 'Tap to change date (pre-booking)',
      'ar': 'اضغط لتغيير التاريخ (حجز مسبق)',
    },
    'posFullDayBlock': {'en': 'Full Day Block', 'ar': 'حجز يوم كامل'},
    'posFullDaySubtitle': {
      'en': 'Reserve the entire day',
      'ar': 'حجز اليوم بالكامل',
    },
    'posStartTime': {'en': 'Start Time:', 'ar': 'وقت البداية:'},
    'posDuration': {'en': 'Duration', 'ar': 'المدة'},
    'posAmountPaid': {'en': 'Amount Paid', 'ar': 'المبلغ المدفوع'},
    'posReserveFullDay': {'en': 'Reserve Full Day', 'ar': 'حجز يوم كامل'},
    'posRecordBooking': {'en': 'Record Booking', 'ar': 'تسجيل الحجز'},
    'posRecentBookings': {
      'en': 'Upcoming & Recent Bookings',
      'ar': 'الحجوزات القادمة والأخيرة',
    },
    'posNoBookings': {'en': 'No bookings yet.', 'ar': 'لا توجد حجوزات بعد.'},
    'posToday': {'en': 'Today', 'ar': 'اليوم'},
    'posTomorrow': {'en': 'Tomorrow', 'ar': 'غداً'},
    'posBookingSuccess': {
      'en': '✅ Booking recorded successfully',
      'ar': '✅ تم تسجيل الحجز بنجاح',
    },
    'posBookingFailed': {'en': 'Booking Failed', 'ar': 'فشل الحجز'},

    // ── Subscriptions ─────────────────────────────────────────────────────────
    'subTitle': {'en': 'Subscriptions', 'ar': 'الاشتراكات'},
    'subAddNew': {'en': 'Add Subscription', 'ar': 'إضافة اشتراك'},
    'subMemberName': {'en': 'Member Name', 'ar': 'اسم العضو'},
    'subPhone': {'en': 'Phone Number', 'ar': 'رقم الهاتف'},
    'subPlan': {'en': 'Plan', 'ar': 'الخطة'},
    'subStartDate': {'en': 'Start Date', 'ar': 'تاريخ البداية'},
    'subEndDate': {'en': 'End Date', 'ar': 'تاريخ الانتهاء'},
    'subStatus': {'en': 'Status', 'ar': 'الحالة'},
    'subActive': {'en': 'Active', 'ar': 'فعّال'},
    'subExpired': {'en': 'Expired', 'ar': 'منتهي'},
    'subNoSubs': {'en': 'No subscriptions yet', 'ar': 'لا توجد اشتراكات بعد'},
    'subSuccessAdd': {
      'en': '✅ Subscription added',
      'ar': '✅ تم إضافة الاشتراك',
    },
    'subSuccessDelete': {
      'en': '✅ Subscription deleted',
      'ar': '✅ تم حذف الاشتراك',
    },

    // ── Users ─────────────────────────────────────────────────────────────────
    'usersTitle': {'en': 'User Management', 'ar': 'إدارة المستخدمين'},
    'usersAddNew': {'en': 'Add User', 'ar': 'إضافة مستخدم'},
    'usersFullName': {'en': 'Full Name', 'ar': 'الاسم الكامل'},
    'usersEmail': {'en': 'Email', 'ar': 'البريد الإلكتروني'},
    'usersPassword': {'en': 'Password', 'ar': 'كلمة المرور'},
    'usersNewPassword': {
      'en': 'New Password (leave empty to keep current)',
      'ar': 'كلمة مرور جديدة (اتركها فارغة للإبقاء على الحالية)',
    },
    'usersRole': {'en': 'Role', 'ar': 'الصلاحية'},
    'usersAdmin': {'en': 'Admin', 'ar': 'مدير'},
    'usersEmployee': {'en': 'Employee', 'ar': 'موظف'},
    'usersNoUsers': {'en': 'No users found.', 'ar': 'لا يوجد مستخدمون.'},
    'usersCreateTitle': {'en': 'Add New User', 'ar': 'إضافة مستخدم جديد'},
    'usersEditTitle': {'en': 'Edit User', 'ar': 'تعديل المستخدم'},
    'usersDeleteTitle': {'en': 'Confirm Delete', 'ar': 'تأكيد الحذف'},
    'usersCannotDelete': {
      'en': 'Cannot Delete User',
      'ar': 'لا يمكن حذف المستخدم',
    },
    'usersPasswordHint': {
      'en': 'Min 6 chars, 1 uppercase, 1 digit, 1 special',
      'ar': '6 أحرف كحد أدنى، حرف كبير، رقم، رمز خاص',
    },
    'usersAdminWarning': {
      'en':
          'Warning: This user is an Admin. You cannot delete yourself or the last admin.',
      'ar': 'تحذير: هذا المستخدم مدير. لا يمكنك حذف نفسك أو آخر مدير.',
    },
    'usersCreated': {
      'en': '✅ User created successfully',
      'ar': '✅ تم إنشاء المستخدم بنجاح',
    },
    'usersUpdated': {
      'en': '✅ User updated successfully',
      'ar': '✅ تم تحديث المستخدم بنجاح',
    },
    'usersDeleted': {'en': '✅ User deleted', 'ar': '✅ تم حذف المستخدم'},
    'usersCannotUndo': {
      'en': 'This action cannot be undone.',
      'ar': 'لا يمكن التراجع عن هذا الإجراء.',
    },
    'usersSaveChanges': {'en': 'Save Changes', 'ar': 'حفظ التغييرات'},
    'usersCreateUser': {'en': 'Create User', 'ar': 'إنشاء مستخدم'},
    'usersAreYouSure': {
      'en': 'Are you sure you want to delete',
      'ar': 'هل أنت متأكد من حذف',
    },
    'usersPagePermissions': {'en': 'Page Permissions', 'ar': 'صلاحيات الصفحات'},
    'usersWarningUsersPageTitle': {'en': 'Grant Users Access?', 'ar': 'منح صلاحية إدارة المستخدمين؟'},
    'usersWarningUsersPageDesc': {
      'en': 'Are you sure you want to grant this user access to the Users page? They will be able to manage other employees.',
      'ar': 'هل أنت متأكد من منح هذا المستخدم صلاحية الدخول لصفحة المستخدمين؟ سيتمكن من إدارة حسابات الموظفين الآخرين.'
    },
    'errorModifyAdmin': {
      'en': 'You do not have permission to modify an Admin account.',
      'ar': 'ليس لديك صلاحية لتعديل حساب مدير.'
    },
    'errorModifyPermissions': {
      'en': 'You do not have permission to modify user permissions.',
      'ar': 'ليس لديك صلاحية لتعديل صلاحيات المستخدمين.'
    },
    'errorDeleteUsers': {
      'en': 'You do not have permission to delete users.',
      'ar': 'ليس لديك صلاحية لحذف المستخدمين.'
    },
    'errorCreateUsers': {
      'en': 'You do not have permission to create users.',
      'ar': 'ليس لديك صلاحية لإنشاء مستخدمين.'
    },

    // ── Finance ───────────────────────────────────────────────────────────────
    'navFinance': {'en': 'Finance', 'ar': 'المالية'},
    'financeTitle': {
      'en': 'Financial Summary & Transactions',
      'ar': 'الملخص المالي والمعاملات',
    },
    'financeTotalRev': {'en': 'Total Revenue', 'ar': 'إجمالي الإيرادات'},
    'financeBookRev': {'en': 'Bookings Revenue', 'ar': 'إيرادات الحجوزات'},
    'financeSubRev': {
      'en': 'Subscriptions Revenue',
      'ar': 'إيرادات الاشتراكات',
    },
    'financeTrans': {'en': 'Transaction History', 'ar': 'سجل المعاملات'},
    'financeNoTrans': {
      'en': 'No transactions recorded yet.',
      'ar': 'لا توجد معاملات مسجلة بعد.',
    },
    'financeDate': {'en': 'Date', 'ar': 'التاريخ'},
    'financeCustomer': {'en': 'Customer Name', 'ar': 'اسم العميل'},
    'financeType': {'en': 'Type', 'ar': 'النوع'},
    'financeDesc': {'en': 'Description', 'ar': 'الوصف'},
    'financeAmount': {'en': 'Amount', 'ar': 'المبلغ'},
    'financeFilterAll': {'en': 'All Transactions', 'ar': 'كل المعاملات'},
    'financeFilterBook': {'en': 'Bookings Only', 'ar': 'الحجوزات فقط'},
    'financeFilterSub': {'en': 'Subscriptions Only', 'ar': 'الاشتراكات فقط'},

    // ── Settings ──────────────────────────────────────────────────────────────
    'navSettings': {'en': 'Settings', 'ar': 'الإعدادات'},
    'settingsTitle': {'en': 'Settings', 'ar': 'الإعدادات'},
    'settingsLanguage': {'en': 'Language', 'ar': 'اللغة'},
    'settingsTheme':    {'en': 'Theme', 'ar': 'المظهر'},
    'settingsDark':     {'en': 'Dark Mode', 'ar': 'الوضع الداكن'},
    'settingsLight':    {'en': 'Light Mode', 'ar': 'الوضع الفاتح'},

    // ── Customers ─────────────────────────────────────────────────────────────
    'navCustomers':     {'en': 'Customers', 'ar': 'العملاء'},
    'customersTitle':   {'en': 'Customers Management', 'ar': 'إدارة العملاء'},
    'customerName':     {'en': 'Name', 'ar': 'الاسم'},
    'customerPhone':    {'en': 'Phone', 'ar': 'رقم الهاتف'},
    'customerAge':      {'en': 'Age', 'ar': 'العمر'},
    'customerDOB':      {'en': 'Date of Birth', 'ar': 'تاريخ الميلاد'},
    'customerBalance':  {'en': 'Remaining Balance', 'ar': 'الرصيد المتبقي'},
    'customerTotalPaid':{'en': 'Total Paid', 'ar': 'إجمالي المدفوعات'},
    'customerAddNew':   {'en': 'New Customer', 'ar': 'إضافة عميل'},
    'customerNoData':   {'en': 'No customers yet.', 'ar': 'لا يوجد عملاء بعد.'},
    'customerDeleteWarning': {'en': 'Are you sure you want to delete this customer? All their records will be affected.', 'ar': 'هل أنت متأكد من حذف هذا العميل؟ ستتأثر جميع سجلاته.'},
    // ── Missing Translations ──────────────────────────────────────────────────
    'notSet': {'en': 'Not Set', 'ar': 'لم يحدد'},
    'payDebt': {'en': 'Pay Debt', 'ar': 'تسديد دفعة'},
    'customerColon': {'en': 'Customer:', 'ar': 'العميل:'},
    'remainingDebt': {'en': 'Remaining Debt:', 'ar': 'الديون المتبقية:'},
    'amountToPayNow': {'en': 'Amount to pay now', 'ar': 'المبلغ المراد سداده الآن'},
    'paymentSuccessful': {'en': 'Payment successful', 'ar': 'تم سداد الدفعة بنجاح'},
    'payBtn': {'en': 'Pay', 'ar': 'دفع'},
    'paymentHistory': {'en': 'Payment History', 'ar': 'سجل الدفعات'},
    'paymentHistoryColon': {'en': 'Payment History:', 'ar': 'سجل الدفعات:'},
    'noPaymentHistory': {'en': 'No payment history found.', 'ar': 'لا يوجد سجل دفعات.'},
    'closeBtn': {'en': 'Close', 'ar': 'إغلاق'},
    'searchNamePhone': {'en': 'Search by name or phone...', 'ar': 'بحث بالاسم أو رقم الهاتف...'},
    'searchName': {'en': 'Search by name...', 'ar': 'بحث بالاسم...'},
    'noResultsFound': {'en': 'No results found.', 'ar': 'لم يتم العثور على نتائج.'},
    
    'walkInCustomer': {'en': 'Walk-in Customer', 'ar': 'عميل مباشر'},
    'newCustomerWalkIn': {'en': 'New Customer / Walk-in', 'ar': 'عميل جديد (أدخل اسمه أدناه)'},
    'subscribedSuffix': {'en': ' (Subscribed)', 'ar': ' (مشترك)'},
    'totalPrice': {'en': 'Total Price', 'ar': 'إجمالي السعر'},
    'totalPriceColon': {'en': 'Total Price:', 'ar': 'إجمالي السعر:'},
    'amountPaidNow': {'en': 'Amount Paid Now', 'ar': 'المبلغ المدفوع الان'},
    
    'searchCustomer': {'en': 'Search Customer', 'ar': 'بحث عن عميل'},
    'pleaseSelectCustomer': {'en': 'Please select or add a new customer', 'ar': 'يرجى اختيار عميل أو إضافة عميل جديد'},
    'daysLeft': {'en': 'Days Left', 'ar': 'الأيام المتبقية'},
    'days': {'en': 'days', 'ar': 'يوم'},
    'inProgress': {'en': 'In Progress', 'ar': 'جارية'},
    'completed': {'en': 'Completed', 'ar': 'مكتمل'},
    'confirmed': {'en': 'Confirmed', 'ar': 'مؤكد'},
    'hourlyBooking': {'en': 'Hourly Booking', 'ar': 'حجز بالساعة'},
    // ── Extra Dashboard & Finance ─────────────────────────────────────────────
    'dashOverview': {'en': 'Overview of your business', 'ar': 'نظرة عامة على عملك'},
    'dashWeeklyTrend': {'en': 'Weekly Revenue Trend', 'ar': 'اتجاه الإيرادات الأسبوعية'},
    'dashRecentActivity': {'en': 'Recent Activity', 'ar': 'النشاط الأخير'},
    'dashViewAll': {'en': 'View All', 'ar': 'عرض الكل'},
    'dashHighDemand': {'en': 'High Demand', 'ar': 'طلب عالٍ'},
    'dashBookingLabel': {'en': 'Booking:', 'ar': 'حجز:'},
    'dashStatusConfirmed': {'en': 'Status: Confirmed', 'ar': 'الحالة: مؤكد'},
    'dashJustNow': {'en': 'Just now', 'ar': 'الآن'},
    
    'finRecentTrans': {'en': 'Recent Transactions', 'ar': 'أحدث المعاملات'},
    'finAllTypes': {'en': 'All Types', 'ar': 'جميع الأنواع'},
    'finBookings': {'en': 'Bookings', 'ar': 'حجوزات'},
    'finSubscriptions': {'en': 'Subscriptions', 'ar': 'اشتراكات'},
    'finNoTrans': {'en': 'No transactions found', 'ar': 'لا توجد معاملات'},
    'finMethod': {'en': 'Method', 'ar': 'الطريقة'},
    'finShowing': {'en': 'Total entries:', 'ar': 'إجمالي المعاملات:'},
    
    'posSubtitle': {'en': 'Manage your Walk-in bookings easily', 'ar': 'إدارة حجوزات نقطة البيع بسهولة'},
    // ── Additional Dashboard Translations ─────────────────────────────────────
    'dashWelcome': {'en': 'Welcome back, ', 'ar': 'مرحباً بك مجدداً، '},
    'dashSubtitle': {'en': "Here's what's happening at AquaFit Pro today.", 'ar': 'إليك ما يحدث في نظامك اليوم.'},
    'dashResources': {'en': 'RESOURCES', 'ar': 'الموارد'},
    'dashOccupancy': {'en': 'OCCUPANCY RATE', 'ar': 'معدل الإشغال'},
    'dashNoActivity': {'en': 'No activity today', 'ar': 'لا يوجد نشاط اليوم'},
    // ── Additional Finance Translations ───────────────────────────────────────
    'finSubtitle': {'en': 'Overview of your current financial standing and recent transactions.', 'ar': 'نظرة عامة على وضعك المالي الحالي والمعاملات الأخيرة.'},
    'finCurrentBalance': {'en': 'CURRENT BALANCE', 'ar': 'الرصيد الحالي'},
    'finLastMonth': {'en': '+4.2% from last month', 'ar': '+4.2% عن الشهر الماضي'},
    'finTotalCash': {'en': 'TOTAL CASH IN DRAWER', 'ar': 'إجمالي النقد في الصندوق'},
    'finReconciled': {'en': 'Last reconciled 2h ago', 'ar': 'آخر تسوية منذ ساعتين'},
    'finReconcileNow': {'en': 'Reconcile Now', 'ar': 'تسوية الآن'},
    'finSearchHint': {'en': 'Search transactions...', 'ar': 'ابحث في المعاملات...'},
    // ____ Additional user management translations 
    'usersSubtitle': {'en': 'Manage employee accounts, roles, and permissions.', 'ar':'إدارة حسابات الموظفين وأدوارهم وصلاحياتهم.'},
     

    // ____ Additional Subscription translations 
    'subSubtitle': {'en': 'Manage active memberships and plans.', 'ar':'إدارة العضويات والخطط النشطة.'},
    'supRecentTrans': {'en': 'All Subscriptions', 'ar':'جميع الاشتراكات'},
    // ____ Additional Customer translations
    'customersSubtitle': {'en': 'Manage customer profiles, balances, and payment history.', 'ar':'إدارة ملفات العملاء، الأرصدة، وسجل الدفعات.'},

    // ____ Additional Calendar translations
    'calSubtitle': {'en': 'View and manage scheduled bookings.', 'ar':'عرض وإدارة الحجوزات المجدولة.'},


    'appsuptitle': {'en': 'Smart Booking', 'ar': ' الحجوزات الذكي'},

    // ── Printing Translations ─────────────────────────────────────────────────
    'printReceipt': {'en': 'Print Receipt', 'ar': 'طباعة الفاتورة'},
    'autoPrint': {'en': 'Auto-print Receipt', 'ar': 'طباعة تلقائية'},
    'receiptTitlePos': {'en': 'POS Receipt', 'ar': 'فاتورة مبيعات'},
    'receiptTitleSub': {'en': 'Subscription Receipt', 'ar': 'فاتورة اشتراك'},

    // ── Check-In ──────────────────────────────────────────────────────────────
    'navCheckin': {'en': 'Check-In', 'ar': 'تسجيل الدخول'},
    'checkinTitle': {'en': 'Member Check-In', 'ar': 'فحص عضوية الأعضاء'},
    'checkinSubtitle': {
      'en': 'Verify membership before entry',
      'ar': 'تحقق من الاشتراك قبل الدخول',
    },
    'checkinByPhone': {'en': 'Search by Phone', 'ar': 'البحث برقم الهاتف'},
    'checkinPhoneHint': {'en': 'Enter phone number', 'ar': 'أدخل رقم الهاتف'},
    'checkinByFingerprint': {'en': 'External Scanner', 'ar': 'جهاز البصمة الخارجي'},
    'checkinFingerprintHint': {
      'en': 'Place finger on scanner, code will appear here',
      'ar': 'ضع الإصبع على الجهاز، سيظهر الكود هنا',
    },
    'checkinBiometric': {'en': 'Phone Fingerprint', 'ar': 'بصمة الهاتف'},
    'checkinBiometricHint': {
      'en': 'Use the phone\'s built-in fingerprint sensor',
      'ar': 'استخدم مستشعر البصمة المدمج في الهاتف',
    },
    'checkinSearch': {'en': 'Search', 'ar': 'بحث'},
    'checkinClear': {'en': 'Clear', 'ar': 'مسح'},
    'checkinNotFound': {'en': 'No member found', 'ar': 'لم يُعثر على عضو'},
    'checkinNoSub': {
      'en': 'No active subscription',
      'ar': 'لا يوجد اشتراك نشط',
    },
    'checkinWelcome': {'en': 'Welcome!', 'ar': 'أهلاً وسهلاً!'},
    'checkinExpired': {'en': 'Subscription Expired', 'ar': 'انتهى الاشتراك'},
    'checkinPendingPayment': {'en': 'Pending Payment', 'ar': 'يوجد رصيد متبقي'},
    'checkinDaysLeft': {'en': 'Days Remaining', 'ar': 'الأيام المتبقية'},
    'checkinEndDate': {'en': 'Expiry Date', 'ar': 'تاريخ الانتهاء'},
    'checkinAmountPaid': {'en': 'Amount Paid', 'ar': 'المبلغ المدفوع'},
    'checkinBalance': {'en': 'Balance Due', 'ar': 'المبلغ المتبقي'},
    'checkinTotal': {'en': 'Total Amount', 'ar': 'إجمالي المبلغ'},
    'checkinBiometricNotAvail': {
      'en': 'Biometric not available on this device',
      'ar': 'البصمة الحيوية غير متاحة على هذا الجهاز',
    },
    'checkinBiometricSuccess': {'en': 'Identity verified!', 'ar': 'تم التحقق من الهوية!'},
    'checkinBiometricFailed': {'en': 'Biometric failed', 'ar': 'فشل التحقق بالبصمة'},
    'checkinEnterPhone': {
      'en': 'Please enter the phone number to continue',
      'ar': 'أدخل رقم الهاتف للمتابعة',
    },
    'checkinLinkFingerprint': {
      'en': 'Link fingerprint to this member',
      'ar': 'ربط البصمة بهذا العضو',
    },
    'checkinFingerprintLinked': {
      'en': 'Fingerprint ID linked successfully!',
      'ar': 'تم ربط البصمة بنجاح!',
    },
    'checkinScannerMode': {'en': 'External Device Mode', 'ar': 'وضع الجهاز الخارجي'},

  };

  static String t(String key, bool isAr) {
    final lang = isAr ? 'ar' : 'en';
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
  }
}

extension AppStringExt on BuildContext {
  // Usage: context.tr('key') — requires reading isArabic from ProviderScope
  // Use the static method AppStrings.t() with isAr bool for simplicity in screens
}
