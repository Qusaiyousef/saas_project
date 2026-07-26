import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';
import '../utils/app_snackbar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_login_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                              AppSnackBar.showInfo(
                                context,
                                selected.first
                                    ? AppStrings.t('langChangedAr', isAr)
                                    : AppStrings.t('langChangedEn', isAr),
                              );
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
                              AppSnackBar.showInfo(
                                context,
                                selected.first == ThemeMode.dark
                                    ? AppStrings.t('darkModeEnabled', isAr)
                                    : AppStrings.t('lightModeEnabled', isAr),
                              );
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fingerprint, color: colors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr ? 'بصمة الدخول السريع' : 'Biometric Quick Login',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'تفعيل بصمة الإبهام/الوجه لتسجيل الدخول الفوري'
                                    : 'Enable fingerprint/face login for instant access',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: (val) async {
                            setState(() => _biometricEnabled = val);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('biometric_login_enabled', val);
                            if (context.mounted) {
                              AppSnackBar.showInfo(
                                context,
                                val
                                    ? (isAr ? 'تم تفعيل الدخول بالبصمة' : 'Biometric Login Enabled')
                                    : (isAr ? 'تم إيقاف الدخول بالبصمة' : 'Biometric Login Disabled'),
                              );
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
