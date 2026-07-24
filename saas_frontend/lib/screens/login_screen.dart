import 'package:flutter/material.dart';
import 'dart:convert';
import '../widgets/app_drawer.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: "qusai");
  final _passwordController = TextEditingController(text: "Admin123!");
  bool _obscurePassword = true;

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s('serverUpdated')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s('invalidCode')),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
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
    String s(String key) => AppStrings.t(key, isAr);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
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
                        suffixIcon: IconButton(
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
        ],
      ),
    );
  }
}
