import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/tenant_type.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../providers/pos_provider.dart';
import '../providers/subscription_provider.dart';

class NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NavItem(this.path, this.icon, this.selectedIcon, this.label);
}

List<NavItem> buildNavItems(
  TenantType type,
  String? role,
  Map<String, bool>? permissions,
  bool isAr,
) {
  final items = <NavItem>[];
  bool hasPerm(String key) => permissions?[key] ?? (role == 'Admin');

  if (hasPerm('canAccessDashboard')) {
    items.add(
      NavItem(
        '/dashboard',
        Icons.dashboard_outlined,
        Icons.dashboard,
        AppStrings.t('navDashboard', isAr),
      ),
    );
  }
  if (hasPerm('canAccessCalendar')) {
    items.add(
      NavItem(
        '/calendar',
        Icons.calendar_month_outlined,
        Icons.calendar_month,
        AppStrings.t('navCalendar', isAr),
      ),
    );
  }
  if (hasPerm('canAccessPOS')) {
    final posLabel = type == TenantType.chalet
        ? AppStrings.t('navBookChalet', isAr)
        : AppStrings.t('navPos', isAr);
    items.add(
      NavItem(
        '/pos',
        Icons.point_of_sale_outlined,
        Icons.point_of_sale,
        posLabel,
      ),
    );
  }
  if ((type == TenantType.gym || type == TenantType.pool) &&
      hasPerm('canAccessCustomers')) {
    items.add(
      NavItem(
        '/customers',
        Icons.contacts_outlined,
        Icons.contacts,
        AppStrings.t('navCustomers', isAr),
      ),
    );
  }
  if ((type == TenantType.gym || type == TenantType.pool) &&
      hasPerm('canAccessSubscriptions')) {
    items.add(
      NavItem(
        '/subscriptions',
        Icons.card_membership_outlined,
        Icons.card_membership,
        AppStrings.t('navSubscriptions', isAr),
      ),
    );
    // Check-In: يظهر فقط للمسبح والجيم
    items.add(
      NavItem(
        '/checkin',
        Icons.how_to_reg_outlined,
        Icons.how_to_reg,
        AppStrings.t('navCheckin', isAr),
      ),
    );
  }
  if (hasPerm('canAccessFinance')) {
    items.add(
      NavItem(
        '/finance',
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet,
        AppStrings.t('navFinance', isAr),
      ),
    );
  }
  if (hasPerm('canAccessUsers')) {
    items.add(
      NavItem(
        '/users',
        Icons.people_outline,
        Icons.people,
        AppStrings.t('navUsers', isAr),
      ),
    );
  }
  if (hasPerm('canAccessSettings')) {
    items.add(
      NavItem(
        '/settings',
        Icons.settings_outlined,
        Icons.settings,
        AppStrings.t('navSettings', isAr),
      ),
    );
  }

  return items;
}

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tenantType = authState.tenantType ?? TenantType.pool;
    final role = authState.role;
    final permissions = authState.permissions;
    final isAr = ref.watch(isArabicProvider);

    final bookingsAsync = ref.watch(bookingsProvider);
    final subsAsync = ref.watch(subscriptionProvider);
    final List<Map<String, dynamic>> expiredBookings = [];
    final List<Map<String, dynamic>> expiredSubs = [];
    final now = DateTime.now();

    bool isToday(DateTime dt) => dt.year == now.year && dt.month == now.month && dt.day == now.day;

    bookingsAsync.whenData((bookings) {
      for (final b in bookings) {
        if (b['endTime'] != null) {
          final dt = DateTime.parse(b['endTime']).toLocal();
          if (dt.isBefore(now) && isToday(dt)) {
            expiredBookings.add(b as Map<String, dynamic>);
          }
        }
      }
    });

    subsAsync.whenData((subs) {
      for (final s in subs) {
        if (s['endDate'] != null) {
          final dt = DateTime.parse(s['endDate']).toLocal();
          if (dt.isBefore(now) && isToday(dt)) {
            expiredSubs.add(s as Map<String, dynamic>);
          }
        }
      }
    });

    final hasAlert = expiredBookings.isNotEmpty || expiredSubs.isNotEmpty;

    final navItems = buildNavItems(tenantType, role, permissions, isAr);
    final location = GoRouterState.of(context).uri.path;

    // Bottom Navigation visible only for specific routes
    final bottomNavPaths = [
      '/calendar',
      '/pos',
      '/subscriptions',
      '/customers',
      '/dashboard',
    ];
    final bottomNavItems = navItems
        .where((item) => bottomNavPaths.contains(item.path))
        .take(4)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            constraints.maxWidth < 1024; // lg breakpoint in tailwind

        return Scaffold(
          key: _scaffoldKey,
          drawer: isMobile
              ? _buildMobileDrawer(navItems, location, context, isAr)
              : null,
          body: isMobile
              ? Column(
                  children: [
                    _buildMobileAppBar(hasAlert, context, isAr, expiredBookings, expiredSubs),
                    Expanded(child: widget.child),
                    _buildBottomBar(bottomNavItems, location, context),
                  ],
                )
              : Row(
                  children: [
                    _buildDesktopSidebar(
                      navItems,
                      location,
                      context,
                      tenantType,
                      role,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDesktopAppBar(context, hasAlert, isAr, expiredBookings, expiredSubs),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(
    List<NavItem> items,
    String location,
    BuildContext context,
    TenantType tenantType,
    String? role,
  ) {
    final tenantLabel = tenantType.name;
    final roleLabel = role == 'Admin' ? 'Admin' : 'Employee';
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.water_drop,
                          color: colors.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenantLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Primary CTA
                ElevatedButton.icon(
                  onPressed: () => context.go('/pos'),
                  icon: const Icon(Icons.add_circle),
                  label: const Text('New Booking'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Links
                Expanded(
                  child: ListView(
                    children: items.map((item) {
                      final isSelected = location.startsWith(item.path);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => context.go(item.path),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border(
                                      right: BorderSide(
                                        color: colors.primary,
                                        width: 4,
                                      ),
                                    )
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(
    List<NavItem> items,
    String location,
    BuildContext context,
    bool isAr,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t('appsuptitle', isAr),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Links
              Expanded(
                child: ListView(
                  children: items.map((item) {
                    final isSelected = location.startsWith(item.path);
                    return ListTile(
                      leading: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.path);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, bool isAr, List<Map<String, dynamic>> expiredBookings, List<Map<String, dynamic>> expiredSubs) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isAr ? 'التنبيهات' : 'Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (expiredBookings.isEmpty && expiredSubs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(isAr ? 'لا توجد تنبيهات' : 'No notifications'),
                  ),
                if (expiredBookings.isNotEmpty) ...[
                  Text(isAr ? 'حجوزات منتهية' : 'Expired Bookings', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...expiredBookings.map((b) => ListTile(
                    leading: const Icon(Icons.event_busy, color: Colors.red),
                    title: Text('${b['customerName']}'),
                    subtitle: Text(isAr ? 'انتهى الحجز' : 'Booking expired'),
                  )),
                  const Divider(),
                ],
                if (expiredSubs.isNotEmpty) ...[
                  Text(isAr ? 'اشتراكات منتهية' : 'Expired Subscriptions', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...expiredSubs.map((s) => ListTile(
                    leading: const Icon(Icons.card_membership, color: Colors.orange),
                    title: Text('${s['customerName']}'),
                    subtitle: Text(isAr ? 'انتهى الاشتراك' : 'Subscription expired'),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إغلاق' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, bool hasAlert, bool isAr, List<Map<String, dynamic>> expiredBookings, List<Map<String, dynamic>> expiredSubs) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              // Search
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    // child: TextField(
                    //   decoration: InputDecoration(
                    //     hintText: 'Search transactions, customers...',
                    //     prefixIcon: const Icon(Icons.search),
                    //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(32),
                    //       borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    //     ),
                    //     enabledBorder: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(32),
                    //       borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    //     ),
                    //   ),
                    // ),
                  ),
                ),
              ),
              // Actions
              IconButton(
                icon: Badge(
                  isLabelVisible: hasAlert,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => _showNotifications(context, isAr, expiredBookings, expiredSubs),
              ),
              const SizedBox(width: 8),
              // const CircleAvatar(
              //   radius: 16,
              //   backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAppBar(bool hasAlert, BuildContext context, bool isAr, List<Map<String, dynamic>> expiredBookings, List<Map<String, dynamic>> expiredSubs) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              Expanded(
                child: Text(
                 AppStrings.t ('appTitle', isAr),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: hasAlert,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onPressed: () => _showNotifications(context, isAr, expiredBookings, expiredSubs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    List<NavItem> items,
    String location,
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = location.startsWith(item.path);
                  final color = isSelected
                      ? colors.primary
                      : colors.onSurfaceVariant;

                  return InkWell(
                    onTap: () => context.go(item.path),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: color,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
