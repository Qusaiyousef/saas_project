import re

with open('lib/screens/dashboard_screen.dart', 'r') as f:
    content = f.read()

replacements = {
    r"Text\(\s*'Welcome back, \$\{authState\.role \?\? \"Admin\"\}',\s*style: const TextStyle\(fontSize: 32, fontWeight: FontWeight\.bold\),\s*\)": r"Text('${AppStrings.t('dashWelcome', isAr)}${authState.role ?? \"Admin\"}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))",
    r"const Text\(\s*\"Here's what's happening at AquaFit Pro today\.\",\s*style: TextStyle\(fontSize: 16, color: Colors\.grey\),\s*\)": r"Text(AppStrings.t('dashSubtitle', isAr), style: const TextStyle(fontSize: 16, color: Colors.grey))",
    r"'TOTAL REVENUE'": r"AppStrings.t('dashTotalRevenue', isAr)",
    r"'ACTIVE SUBSCRIPTIONS'": r"AppStrings.t('dashActiveSubs', isAr)",
    r"'RESOURCES'": r"AppStrings.t('dashResources', isAr)",
    r"\"TODAY'S BOOKINGS\"": r"AppStrings.t('dashTodayBookings', isAr)",
    r"'OCCUPANCY RATE'": r"AppStrings.t('dashOccupancy', isAr)",
    r"Text\(\"No activity today\", style: TextStyle\(color: Colors\.grey\)\)": r"Text(AppStrings.t('dashNoActivity', isAr), style: const TextStyle(color: Colors.grey))"
}

for k, v in replacements.items():
    content = re.sub(k, v, content)

with open('lib/screens/dashboard_screen.dart', 'w') as f:
    f.write(content)
