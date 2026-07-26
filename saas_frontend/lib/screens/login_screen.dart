import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../utils/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: "qusai");
  final _passwordController = TextEditingController(text: "Admin123!");
  bool _obscurePassword = true;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canBiometricLogin = false;
  String? _savedUsername;
  String? _savedPassword;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
    _checkSavedBiometricAuth();
  }

  Future<void> _checkSavedBiometricAuth() async {
    if (kIsWeb) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('saved_auth_username');
      final savedPass = prefs.getString('saved_auth_password');
      final isEnabled = prefs.getBool('biometric_login_enabled') ?? false;

      if (canCheck && isDeviceSupported) {
        setState(() {
          _canBiometricLogin = true;
          _savedUsername = savedUser;
          _savedPassword = savedPass;
        });

        // فتح نافذة البصمة تلقائياً فقط إذا كانت مفعّلة في الإعدادات وهنالك بيانات سابقة
        if (isEnabled && savedUser != null && savedPass != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final isAr = ref.read(isArabicProvider);
              _loginWithBiometrics(isAr);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loginWithBiometrics(bool isAr) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_login_enabled') ?? false;

    if (!isEnabled) {
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          isAr
              ? 'يرجى تفعيل خيار البصمة من صفحة الإعدادات أولاً بعد تسجيل الدخول.'
              : 'Please enable Biometric Login in Settings first after logging in.',
        );
      }
      return;
    }

    if (_savedUsername == null || _savedPassword == null) {
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          isAr
              ? 'يرجى تسجيل الدخول يدويًا مرة واحدة لحفظ البصمة.'
              : 'Please log in manually once to save biometric credentials.',
        );
      }
      return;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: isAr
            ? 'استخدم البصمة لتسجيل الدخول السريع'
            : 'Use fingerprint to log in quickly',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        await ref.read(authProvider.notifier).login(_savedUsername!, _savedPassword!);
        final currentAuth = ref.read(authProvider);
        if (currentAuth.isAuthenticated && context.mounted) {
          if (currentAuth.role == 'Employee') {
            context.go('/calendar');
          } else {
            context.go('/dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          isAr ? 'فشلت المصادقة بالبصمة' : 'Biometric authentication failed',
        );
      }
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_auth_username', username);
      await prefs.setString('saved_auth_password', password);
    } catch (_) {}
  }

  void _showServerSetupDialog() {
    String s(String key) => AppStrings.t(key, ref.read(isArabicProvider));
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s('serverSetup')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: s('enterServerCode'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final code = controller.text.trim();
                  if (code.isEmpty) return;

                  final decodedUrl = utf8.decode(base64Decode(code));
                  if (!decodedUrl.startsWith('http'))
                    throw Exception('Invalid');

                  await ref.read(apiUrlProvider.notifier).updateUrl(decodedUrl);

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppSnackBar.showSuccess(context, s('serverUpdated'));
                  }
                } catch (e) {
                  AppSnackBar.showError(context, s('invalidCode'));
                }
              },
              child: Text(s('save')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAr = ref.watch(isArabicProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    String s(String key) => AppStrings.t(key, isAr);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AppSnackBar.showError(context, next.error!);
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 24, vertical: 24)
                : EdgeInsets.zero,
            child: Container(
              width: isMobile ? double.infinity : 420,
              padding: EdgeInsets.all(isMobile ? 0 : 32),
              decoration: isMobile
                  ? null
                  : BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.07),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Server setup & Language toggle at top
                    Row(
                      mainAxisAlignment: isAr
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.dns_rounded),
                          tooltip: s('serverSetup'),
                          onPressed: _showServerSetupDialog,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              ref.read(localeProvider.notifier).toggle(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s('language'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Image.asset(
                        'assets/app_icon.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      s('loginTitle'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s('loginSubtitle'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: s('loginField'),
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) async {
                        if (authState.isLoading) return;
                        await ref
                            .read(authProvider.notifier)
                            .login(
                              _emailController.text,
                              _passwordController.text,
                            );
                        final currentAuth = ref.read(authProvider);
                        if (currentAuth.isAuthenticated && context.mounted) {
                          if (currentAuth.role == 'Employee') {
                            context.go('/calendar');
                          } else {
                            context.go('/dashboard');
                          }
                        }
                      },
                      decoration: InputDecoration(
                        labelText: s('loginPassword'),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: _passwordController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.fingerprint,
                                  color: Colors.teal,
                                ),
                                tooltip: isAr ? 'البصمة' : 'Biometric',
                                onPressed: () => _loginWithBiometrics(isAr),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                              final currentAuth = ref.read(authProvider);
                              if (currentAuth.isAuthenticated &&
                                  context.mounted) {
                                await _saveCredentials(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                                if (currentAuth.role == 'Employee') {
                                  context.go('/calendar');
                                } else {
                                  context.go('/dashboard');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator()
                          : Text(s('loginButton')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
