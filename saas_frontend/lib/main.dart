import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SaasApp()));
}

class SaasApp extends ConsumerWidget {
  const SaasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale    = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'B2B SaaS Portal',
      debugShowCheckedModeBanner: false,

      // ── Locale & Direction ───────────────────────────────────────────────
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theme ─────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
