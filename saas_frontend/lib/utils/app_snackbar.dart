import 'package:flutter/material.dart';

/// Types of notifications supported by AppSnackBar
enum NotificationType { success, error, info, warning }

/// Centralized utility for showing top-floating, animated, overlay toast notifications.
/// Floats OVER all dialogs, modals, bottom sheets, and app bars.
class AppSnackBar {
  static OverlayEntry? _currentOverlay;

  /// Show a success toast notification from the top
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message: message, type: NotificationType.success);
  }

  /// Show an error toast notification from the top
  static void showError(BuildContext context, String message) {
    _showToast(context, message: message, type: NotificationType.error);
  }

  /// Show an info toast notification from the top
  static void showInfo(BuildContext context, String message) {
    _showToast(context, message: message, type: NotificationType.info);
  }

  /// Show a warning toast notification from the top
  static void showWarning(BuildContext context, String message) {
    _showToast(context, message: message, type: NotificationType.warning);
  }

  /// Show a beautiful success confirmation dialog (ShowDialog)
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'موافق',
  }) async {
    return showDialog(
      context: context,
      builder: (dCtx) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'Cairo',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _showToast(
    BuildContext context, {
    required String message,
    required NotificationType type,
  }) {
    // Dismiss any existing active overlay toast
    dismissCurrent();

    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _TopToastWidget(
          message: message,
          type: type,
          onDismiss: () {
            if (_currentOverlay == entry) {
              entry.remove();
              _currentOverlay = null;
            }
          },
        );
      },
    );

    _currentOverlay = entry;
    overlayState.insert(entry);
  }

  /// Manually dismiss current toast if active
  static void dismissCurrent() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    // Auto-dismiss after 3.2 seconds
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() {
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on Theme (Dark vs Light) & Notification Type
    late Color cardBg;
    late Color borderColor;
    late Color iconBg;
    late Color iconColor;
    late Color textColor;
    late IconData iconData;

    switch (widget.type) {
      case NotificationType.error:
        iconData = Icons.error_outline_rounded;
        if (isDark) {
          cardBg = const Color(0xFF23171B);
          borderColor = const Color(0xFFEF4444);
          iconBg = const Color(0xFF451A1D);
          iconColor = const Color(0xFFF87171);
          textColor = const Color(0xFFFEE2E2);
        } else {
          cardBg = Colors.white;
          borderColor = const Color(0xFFEF4444);
          iconBg = const Color(0xFFFEE2E2);
          iconColor = const Color(0xFFDC2626);
          textColor = const Color(0xFF7F1D1D);
        }
        break;

      case NotificationType.success:
        iconData = Icons.check_circle_outline_rounded;
        if (isDark) {
          cardBg = const Color(0xFF102820);
          borderColor = const Color(0xFF10B981);
          iconBg = const Color(0xFF064E3B);
          iconColor = const Color(0xFF34D399);
          textColor = const Color(0xFFECFDF5);
        } else {
          cardBg = Colors.white;
          borderColor = const Color(0xFF10B981);
          iconBg = const Color(0xFFD1FAE5);
          iconColor = const Color(0xFF059669);
          textColor = const Color(0xFF065F46);
        }
        break;

      case NotificationType.warning:
        iconData = Icons.warning_amber_rounded;
        if (isDark) {
          cardBg = const Color(0xFF2B2111);
          borderColor = const Color(0xFFF59E0B);
          iconBg = const Color(0xFF45300B);
          iconColor = const Color(0xFFFBBF24);
          textColor = const Color(0xFFFEF3C7);
        } else {
          cardBg = Colors.white;
          borderColor = const Color(0xFFF59E0B);
          iconBg = const Color(0xFFFEF3C7);
          iconColor = const Color(0xFFD97706);
          textColor = const Color(0xFF78350F);
        }
        break;

      case NotificationType.info:
        iconData = Icons.info_outline_rounded;
        if (isDark) {
          cardBg = const Color(0xFF132238);
          borderColor = const Color(0xFF3B82F6);
          iconBg = const Color(0xFF1E3A8A);
          iconColor = const Color(0xFF60A5FA);
          textColor = const Color(0xFFEFF6FF);
        } else {
          cardBg = Colors.white;
          borderColor = const Color(0xFF3B82F6);
          iconBg = const Color(0xFFDBEAFE);
          iconColor = const Color(0xFF2563EB);
          textColor = const Color(0xFF1E40AF);
        }
        break;
    }

    return Positioned(
      top: mediaQuery.padding.top + 12,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _dismissWithAnimation,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: textColor.withValues(alpha: 0.6),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
