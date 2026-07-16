import re

with open('lib/screens/finance_screen.dart', 'r') as f:
    content = f.read()

# 1. Add calculatedCash logic right after transactionsAsync
calculated_cash_logic = """    final transactionsAsync = ref.watch(financeTransactionsProvider);

    double calculatedCash = 0.0;
    if (transactionsAsync.hasValue) {
      final txs = transactionsAsync.value ?? [];
      calculatedCash = txs
          .where((t) => (t['method'] ?? '').toString().toLowerCase() == 'cash')
          .fold<double>(0.0, (sum, t) => sum + (double.tryParse(f"{t['amount']}") ?? 0.0));
    }
"""
content = content.replace("    final transactionsAsync = ref.watch(financeTransactionsProvider);", calculated_cash_logic.replace('f"{', "${"))

# 2. Update KPI hardcoded strings
content = content.replace("const Text(\"Overview of your current financial standing and recent transactions.\", style: TextStyle(color: Colors.grey, fontSize: 16))",
                          "Text(s('finSubtitle'), style: const TextStyle(color: Colors.grey, fontSize: 16))")

content = content.replace("'CURRENT BALANCE'", "s('finCurrentBalance')")
content = content.replace("'+4.2% from last month'", "s('finLastMonth')")
content = content.replace("'TOTAL CASH IN DRAWER'", "s('finTotalCash')")
content = content.replace("'\\$1,200.00'", "'\\$${calculatedCash.toStringAsFixed(2)}'")
content = content.replace("'Last reconciled 2h ago'", "s('finReconciled')")
content = content.replace("actionText: 'Reconcile Now',", "actionText: s('finReconcileNow'),")

# 3. Update Search Hint
content = content.replace("hintText: 'Search transactions...',", "hintText: s('finSearchHint'),")

# 4. Update transaction row text
content = content.replace("Text(isBooking ? 'Booking - ${t['customerName'] ?? 'Walk-in'}' : 'Sub - ${t['customerName'] ?? 'Walk-in'}'",
                          "Text(isBooking ? '${AppStrings.t('dashBookingLabel', isAr)} - ${t['customerName'] ?? 'Walk-in'}' : '${AppStrings.t('finSubscriptions', isAr)} - ${t['customerName'] ?? 'Walk-in'}'")

with open('lib/screens/finance_screen.dart', 'w') as f:
    f.write(content)
