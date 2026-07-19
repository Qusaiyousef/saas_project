import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAr = ref.watch(isArabicProvider);
    final s = (String key) => AppStrings.t(key, isAr);

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
                    // Language toggle at top
                    Align(
                      alignment: isAr
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: InkWell(
                        onTap: () => ref.read(localeProvider.notifier).toggle(),
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
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   s('loginDemoLabel'),
                          //   style: const TextStyle(
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 12,
                          //   ),
                          // ),
                          // const SizedBox(height: 4),
                          // const Text(
                          //   '🏊 Pool Admin:   qusai / Admin123!',
                          //   style: TextStyle(fontSize: 11),
                          // ),
                          // const Text(
                          //   '🏊 Pool Emp:     ali / Ali1234!',
                          //   style: TextStyle(fontSize: 11),
                          // ),
                          // const Text(
                          //   '💪 Gym Admin:    gym_admin / Admin123!',
                          //   style: TextStyle(fontSize: 11),
                          // ),
                          // const Text(
                          //   '💪 Gym Emp:      gym_emp / Emp1234!',
                          //   style: TextStyle(fontSize: 11),
                          // ),
                          // const Text(
                          //   '🏡 Chalet Admin: chalet_admin / Admin123!',
                          //   style: TextStyle(fontSize: 11),
                          // ),
                          // const Text(
                          //   '🏡 Chalet Emp:   chalet_emp / Emp1234!',
                          //   style: TextStyle(fontSize: 11),
                          // ),
                        ],
                      ),
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
