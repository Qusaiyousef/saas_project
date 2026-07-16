import re

with open('lib/screens/dashboard_screen.dart', 'r') as f:
    content = f.read()

# Update _buildChartCard definition and call sites
content = content.replace("Widget _buildChartCard(BuildContext context)", "Widget _buildChartCard(BuildContext context, bool isAr)")
content = content.replace("_buildChartCard(context)", "_buildChartCard(context, isAr)")

# Update _buildRecentActivity definition and call sites
content = content.replace("Widget _buildRecentActivity(BuildContext context)", "Widget _buildRecentActivity(BuildContext context, bool isAr)")
content = content.replace("_buildRecentActivity(context)", "_buildRecentActivity(context, isAr)")

# Remove const from Row/Column containing AppStrings.t
content = content.replace("const Row(\n                  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                  children: [\n                    Text(AppStrings.t('dashWeeklyTrend'",
                          "Row(\n                  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                  children: [\n                    Text(AppStrings.t('dashWeeklyTrend'")

content = content.replace("const Row(\n                  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                  children: [\n                    Text(AppStrings.t('dashRecentActivity'",
                          "Row(\n                  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                  children: [\n                    Text(AppStrings.t('dashRecentActivity'")

# Also fix `const TextStyle` inside the text which could be causing "Method invocation is not a constant expression"
# If the Text widget is not const, its style can be const, which is fine. But let's just make sure there's no `const` before `Text` 
content = re.sub(r'const\s+(Text\(AppStrings\.t)', r'\1', content)

with open('lib/screens/dashboard_screen.dart', 'w') as f:
    f.write(content)
