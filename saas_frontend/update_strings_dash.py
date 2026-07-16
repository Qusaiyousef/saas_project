import re

with open('lib/l10n/app_strings.dart', 'r') as f:
    content = f.read()

new_strings = """
    // ── Additional Dashboard Translations ─────────────────────────────────────
    'dashWelcome': {'en': 'Welcome back, ', 'ar': 'مرحباً بك مجدداً، '},
    'dashSubtitle': {'en': "Here's what's happening at AquaFit Pro today.", 'ar': 'إليك ما يحدث في نظامك اليوم.'},
    'dashTotalRevenue': {'en': 'TOTAL REVENUE', 'ar': 'إجمالي الإيرادات'},
    'dashActiveSubs': {'en': 'ACTIVE SUBSCRIPTIONS', 'ar': 'الاشتراكات النشطة'},
    'dashResources': {'en': 'RESOURCES', 'ar': 'الموارد'},
    'dashTodayBookings': {'en': "TODAY'S BOOKINGS", 'ar': 'حجوزات اليوم'},
    'dashOccupancy': {'en': 'OCCUPANCY RATE', 'ar': 'معدل الإشغال'},
    'dashNoActivity': {'en': 'No activity today', 'ar': 'لا يوجد نشاط اليوم'},
"""

content = re.sub(r'(\s*};\s*\n\s*static String t\()', new_strings + r'\1', content)

with open('lib/l10n/app_strings.dart', 'w') as f:
    f.write(content)
