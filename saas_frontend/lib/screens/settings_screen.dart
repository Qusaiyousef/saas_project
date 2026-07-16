import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isArabicProvider);
    final themeMode = ref.watch(themeProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String s(String key) => AppStrings.t(key, isAr);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s('settingsLanguage'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('English')),
                            ButtonSegment(value: true, label: Text('العربية')),
                          ],
                          selected: {isAr},
                          onSelectionChanged: (Set<bool> selected) {
                            if (selected.first != isAr) {
                              ref.read(localeProvider.notifier).toggle();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s('settingsTheme'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(s('settingsLight')),
                              icon: const Icon(Icons.light_mode),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(s('settingsDark')),
                              icon: const Icon(Icons.dark_mode),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (Set<ThemeMode> selected) {
                            if (selected.first != themeMode) {
                              ref.read(themeProvider.notifier).toggleTheme();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.read(authProvider.notifier).logout(),
                          icon: const Icon(Icons.logout),
                          label: Text(
                            s('logout'),
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: isDark
                                ? colors.errorContainer
                                : Theme.of(context).colorScheme.error,
                            foregroundColor: isDark
                                ? colors.onErrorContainer
                                : Theme.of(context).colorScheme.onError,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
