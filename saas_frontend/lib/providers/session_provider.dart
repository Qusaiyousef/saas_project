import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../utils/app_snackbar.dart';

const String _keyLastActive = 'session_last_active_ms';
const int _timeoutMs = 30 * 60 * 1000; // 30 minutes

class SessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    _touchActivity();
    return true; // true = session active, false = session expired
  }

  Future<void> _touchActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<bool> checkAndVerifySession(BuildContext context, bool isAr) async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(_keyLastActive) ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastActive < _timeoutMs) {
      // الجلسة نشطة → تحديث وقت الأثر فقط
      await _touchActivity();
      return true;
    }

    // الجلسة انتهت (مرت 30 دقيقة أو أكثر) → إظهار نافذة البصمة لتجديد الجلسة
    final renewed = await _showBiometricRenewalDialog(context, isAr);
    if (renewed) {
      await _touchActivity();
      return true;
    }
    return false;
  }

  Future<bool> _showBiometricRenewalDialog(BuildContext context, bool isAr) async {
    bool authenticated = false;
    final localAuth = LocalAuthentication();

    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();

      if (canCheck && isSupported) {
        authenticated = await localAuth.authenticate(
          localizedReason: isAr
              ? 'انتهت جلسة العمل لدواعي الأمان. ضع بصمتك لتجديد الجلسة والاستمرار'
              : 'Session expired for security. Place fingerprint to renew session and continue',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      }
    } catch (_) {}

    if (authenticated) {
      if (context.mounted) {
        AppSnackBar.showSuccess(
          context,
          isAr ? 'تم تجديد الجلسة بنجاح!' : 'Session renewed successfully!',
        );
      }
      return true;
    }

    // إذا فشلت البصمة أو غير مدعومة → نتيح إدخال كلمة المرور لتجديد الجلسة بدون خروج
    if (!context.mounted) return false;

    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.orange),
            const SizedBox(width: 8),
            Text(isAr ? 'تجديد جلسة العمل' : 'Renew Work Session'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr
                  ? 'انتهت فترة الجلسة (30 دقيقة من عدم النشاط). يرجى البصمة أو تأكيد كلمة المرور لتجديد الجلسة'
                  : 'Session period expired (30m inactivity). Please verify fingerprint or password to renew.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: isAr ? 'كلمة المرور' : 'Password',
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t('cancel', isAr)),
          ),
          FilledButton(
            onPressed: () {
              if (passwordController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(isAr ? 'تجديد الجلسة' : 'Renew Session'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, bool>(() {
  return SessionNotifier();
});
