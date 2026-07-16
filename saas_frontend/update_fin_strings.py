import re

with open('lib/l10n/app_strings.dart', 'r') as f:
    content = f.read()

new_strings = """
    // ── Additional Finance Translations ───────────────────────────────────────
    'finSubtitle': {'en': 'Overview of your current financial standing and recent transactions.', 'ar': 'نظرة عامة على وضعك المالي الحالي والمعاملات الأخيرة.'},
    'finCurrentBalance': {'en': 'CURRENT BALANCE', 'ar': 'الرصيد الحالي'},
    'finLastMonth': {'en': '+4.2% from last month', 'ar': '+4.2% عن الشهر الماضي'},
    'finTotalCash': {'en': 'TOTAL CASH IN DRAWER', 'ar': 'إجمالي النقد في الصندوق'},
    'finReconciled': {'en': 'Last reconciled 2h ago', 'ar': 'آخر تسوية منذ ساعتين'},
    'finReconcileNow': {'en': 'Reconcile Now', 'ar': 'تسوية الآن'},
    'finSearchHint': {'en': 'Search transactions...', 'ar': 'ابحث في المعاملات...'},
"""

content = re.sub(r'(\s*};\s*\n\s*static String t\()', new_strings + r'\1', content)

with open('lib/l10n/app_strings.dart', 'w') as f:
    f.write(content)
