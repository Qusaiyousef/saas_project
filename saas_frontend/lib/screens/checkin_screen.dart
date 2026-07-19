import 'dart:async';
import 'dart:ui' as dart_ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/checkin_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _scannerController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _scannerFocus = FocusNode();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late TabController _tabController;
  bool _biometricAvailable = false;
  bool _checkingBiometric = false;

  // لمنع التكرار عند استقبال كود الجهاز الخارجي
  Timer? _scannerDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kIsWeb ? 2 : 3, vsync: this);
    if (!kIsWeb) _checkBiometricAvailability();

    // الاستماع للمسح من الجهاز الخارجي (تعمل مثل keyboard input)
    _scannerController.addListener(_onScannerInput);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _scannerController.dispose();
    _phoneFocus.dispose();
    _scannerFocus.dispose();
    _scannerDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final deviceSupport = await _localAuth.isDeviceSupported();
      if (mounted) setState(() => _biometricAvailable = available && deviceSupport);
    } catch (_) {
      if (mounted) setState(() => _biometricAvailable = false);
    }
  }

  void _onScannerInput() {
    _scannerDebounce?.cancel();
    // نتأخر 500ms بعد آخر حرف → إذا توقف الجهاز عن الإرسال نبحث
    _scannerDebounce = Timer(const Duration(milliseconds: 500), () {
      final code = _scannerController.text.trim();
      if (code.isNotEmpty) {
        ref.read(checkInProvider.notifier).searchByFingerprintId(code);
      }
    });
  }

  Future<void> _authenticateBiometric() async {
    final isAr = ref.read(isArabicProvider);
    if (!_biometricAvailable) {
      _showSnack(AppStrings.t('checkinBiometricNotAvail', isAr), isError: true);
      return;
    }

    setState(() => _checkingBiometric = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: isAr
            ? 'ضع إصبعك للتحقق من هويتك'
            : 'Place your finger to verify your identity',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        // البصمة تحقق من هوية الشخص → نحتاج رقم هاتفه لربطه بالعميل
        _showPhoneInputDialog(isAr);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(AppStrings.t('checkinBiometricFailed', isAr), isError: true);
      }
    } finally {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  void _showPhoneInputDialog(bool isAr) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('checkinBiometricSuccess', isAr)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(AppStrings.t('checkinEnterPhone', isAr)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: AppStrings.t('checkinPhoneHint', isAr),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('cancel', isAr)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(checkInProvider.notifier).searchByPhone(controller.text);
            },
            child: Text(AppStrings.t('checkinSearch', isAr)),
          ),
        ],
      ),
    );
  }

  void _showLinkFingerprintDialog(bool isAr, String customerId) {
    final controller = TextEditingController();
    final scanFocus = FocusNode();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('checkinLinkFingerprint', isAr)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'اطلب من العضو وضع إصبعه على الجهاز الخارجي، سيظهر الكود هنا تلقائياً'
                  : 'Ask member to place finger on external scanner. Code will appear automatically.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              focusNode: scanFocus,
              decoration: InputDecoration(
                hintText: isAr ? 'كود البصمة' : 'Fingerprint Code',
                prefixIcon: const Icon(Icons.qr_code_scanner),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('cancel', isAr)),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await ref
                  .read(checkInProvider.notifier)
                  .linkFingerprintId(customerId, code);
              if (mounted) {
                _showSnack(
                  ok
                      ? AppStrings.t('checkinFingerprintLinked', isAr)
                      : AppStrings.t('error', isAr),
                  isError: !ok,
                );
              }
            },
            child: Text(AppStrings.t('save', isAr)),
          ),
        ],
      ),
    );
    // نفعّل focus على حقل الإدخال تلقائياً لاستقبال كود الجهاز
    Future.delayed(const Duration(milliseconds: 300), () => scanFocus.requestFocus());
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(isArabicProvider);
    final state = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? dart_ui.TextDirection.rtl : dart_ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Inherit from shell
        appBar: MediaQuery.of(context).size.width < 1024
            ? AppBar(
                title: Text(AppStrings.t('checkinTitle', isAr)),
                backgroundColor: Colors.transparent,
                elevation: 0,
              )
            : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header (Desktop) ──────────────────────────────────────────
                if (MediaQuery.of(context).size.width >= 1024)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t('checkinTitle', isAr),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppStrings.t('checkinSubtitle', isAr),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Input Tabs ─────────────────────────────────────────────────
                _buildInputCard(context, isAr, theme, state),

                // ── Result Card ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildResultSection(context, isAr, theme, state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── بطاقة الإدخال مع الـ Tabs ─────────────────────────────────────────────
  Widget _buildInputCard(
      BuildContext context, bool isAr, ThemeData theme, CheckInState state) {
    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                icon: const Icon(Icons.phone_android, size: 20),
                text: AppStrings.t('checkinByPhone', isAr),
              ),
              Tab(
                icon: const Icon(Icons.usb, size: 20),
                text: AppStrings.t('checkinByFingerprint', isAr),
              ),
              if (!kIsWeb)
                Tab(
                  icon: const Icon(Icons.fingerprint, size: 20),
                  text: AppStrings.t('checkinBiometric', isAr),
                ),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          SizedBox(
            height: 140,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPhoneTab(isAr, theme, state),
                _buildScannerTab(isAr, theme, state),
                if (!kIsWeb) _buildBiometricTab(isAr, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 1: رقم الهاتف
  Widget _buildPhoneTab(bool isAr, ThemeData theme, CheckInState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) =>
                  ref.read(checkInProvider.notifier).searchByPhone(v),
              decoration: InputDecoration(
                labelText: AppStrings.t('checkinByPhone', isAr),
                hintText: AppStrings.t('checkinPhoneHint', isAr),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: state.isLoading
                    ? null
                    : () => ref
                        .read(checkInProvider.notifier)
                        .searchByPhone(_phoneController.text),
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(isAr ? Icons.search : Icons.search),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  _phoneController.clear();
                  ref.read(checkInProvider.notifier).clear();
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(AppStrings.t('checkinClear', isAr),
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tab 2: جهاز البصمة الخارجي
  Widget _buildScannerTab(bool isAr, ThemeData theme, CheckInState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.t('checkinScannerMode', isAr),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _scannerController,
            focusNode: _scannerFocus,
            decoration: InputDecoration(
              hintText: AppStrings.t('checkinFingerprintHint', isAr),
              prefixIcon: const Icon(Icons.fingerprint),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              suffixIcon: state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _scannerController.clear();
                        ref.read(checkInProvider.notifier).clear();
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 3: بصمة الهاتف (موبايل فقط)
  Widget _buildBiometricTab(bool isAr, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _biometricAvailable
            ? _checkingBiometric
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(isAr ? 'جاري التحقق...' : 'Verifying...'),
                    ],
                  )
                : GestureDetector(
                    onTap: _authenticateBiometric,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.t('checkinBiometric', isAr),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint,
                      size: 36, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.t('checkinBiometricNotAvail', isAr),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
      ),
    );
  }

  // ── قسم النتيجة ───────────────────────────────────────────────────────────
  Widget _buildResultSection(
      BuildContext context, bool isAr, ThemeData theme, CheckInState state) {
    if (state.isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator()));
    }

    if (!state.searched) {
      return _buildEmptyState(isAr, theme);
    }

    if (state.result == null) {
      return _buildNotFoundCard(isAr, theme);
    }

    return _buildResultCard(context, isAr, theme, state.result!);
  }

  Widget _buildEmptyState(bool isAr, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.how_to_reg_outlined,
              size: 72, color: theme.colorScheme.outline.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            isAr
                ? 'ابحث عن عضو للتحقق من اشتراكه'
                : 'Search for a member to check their subscription',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundCard(bool isAr, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.person_search,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              AppStrings.t('checkinNotFound', isAr),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'لا يوجد عضو مسجل بهذه البيانات'
                  : 'No member registered with this data',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      BuildContext context, bool isAr, ThemeData theme, CheckInResult result) {
    // تحديد الحالة واللون
    final level = result.statusLevel;
    final Color cardColor;
    final Color textColor;
    final IconData statusIcon;
    final String statusLabel;

    switch (level) {
      case 0:
        cardColor = const Color(0xFF1B5E20);
        textColor = Colors.white;
        statusIcon = Icons.check_circle;
        statusLabel = AppStrings.t('checkinWelcome', isAr);
        break;
      case 1:
        cardColor = const Color(0xFFF57F17);
        textColor = Colors.white;
        statusIcon = Icons.warning_rounded;
        statusLabel = AppStrings.t('checkinPendingPayment', isAr);
        break;
      default:
        cardColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        statusIcon = Icons.cancel;
        statusLabel = result.subscription == null
            ? AppStrings.t('checkinNoSub', isAr)
            : AppStrings.t('checkinExpired', isAr);
    }

    return Column(
      children: [
        // ── البطاقة الرئيسية ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // أيقونة الحالة
                Icon(statusIcon, size: 64, color: textColor),
                const SizedBox(height: 12),

                // اسم العضو
                Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // حالة الاشتراك
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),

                if (result.subscription != null) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 12),

                  // تفاصيل الاشتراك
                  _buildDetailRow(
                    isAr,
                    textColor,
                    Icons.calendar_today,
                    AppStrings.t('checkinEndDate', isAr),
                    DateFormat('yyyy/MM/dd').format(
                        result.subscription!.endDate.toLocal()),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    isAr,
                    textColor,
                    Icons.hourglass_bottom,
                    AppStrings.t('checkinDaysLeft', isAr),
                    '${result.subscription!.daysRemaining} ${isAr ? 'يوم' : 'days'}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    isAr,
                    textColor,
                    Icons.payments,
                    AppStrings.t('checkinAmountPaid', isAr),
                    '\$${result.subscription!.amountPaid.toStringAsFixed(2)}',
                  ),
                  if (result.subscription!.balance > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      isAr,
                      textColor,
                      Icons.money_off,
                      AppStrings.t('checkinBalance', isAr),
                      '\$${result.subscription!.balance.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── زر ربط البصمة الخارجية ────────────────────────────────────────
        if (result.fingerprintId == null || result.fingerprintId!.isEmpty)
          OutlinedButton.icon(
            onPressed: () =>
                _showLinkFingerprintDialog(isAr, result.id),
            icon: const Icon(Icons.link),
            label: Text(AppStrings.t('checkinLinkFingerprint', isAr)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                isAr
                    ? 'البصمة مربوطة: ${result.fingerprintId}'
                    : 'Fingerprint linked: ${result.fingerprintId}',
                style: const TextStyle(color: Colors.green),
              ),
              TextButton(
                onPressed: () => _showLinkFingerprintDialog(isAr, result.id),
                child: Text(isAr ? 'تحديث' : 'Update',
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    bool isAr,
    Color textColor,
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: textColor.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: textColor.withOpacity(0.85), fontSize: 13)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            fontSize: highlight ? 15 : 13,
          ),
        ),
      ],
    );
  }
}
