// lib/screens/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/tenant_type.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  List<_NavItem> _buildNavItems(TenantType type, String? role, Map<String, bool>? permissions, bool isAr) {
    final items = <_NavItem>[];

    bool hasPerm(String key) => permissions?[key] ?? (role == 'Admin');

    if (hasPerm('canAccessDashboard')) {
      items.add(_NavItem('/dashboard', Icons.dashboard_outlined, Icons.dashboard,
          AppStrings.t('navDashboard', isAr)));
    }

    if (hasPerm('canAccessCalendar')) {
      items.add(_NavItem('/calendar', Icons.calendar_month_outlined, Icons.calendar_month,
          AppStrings.t('navCalendar', isAr)));
    }

    if (hasPerm('canAccessPOS')) {
      final posLabel = type == TenantType.chalet
          ? AppStrings.t('navBookChalet', isAr)
          : AppStrings.t('navPos', isAr);
      items.add(_NavItem('/pos', Icons.point_of_sale_outlined, Icons.point_of_sale, posLabel));
    }

    if ((type == TenantType.gym || type == TenantType.pool) && hasPerm('canAccessSubscriptions')) {
      items.add(_NavItem('/subscriptions', Icons.card_membership_outlined,
          Icons.card_membership, AppStrings.t('navSubscriptions', isAr)));
    }

    if (hasPerm('canAccessUsers')) {
      items.add(_NavItem('/users', Icons.people_outline, Icons.people,
          AppStrings.t('navUsers', isAr)));
    }
          
    if (hasPerm('canAccessFinance')) {
      items.add(_NavItem('/finance', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet,
          AppStrings.t('navFinance', isAr)));
    }

    if (hasPerm('canAccessCustomers')) {
      items.add(_NavItem('/customers', Icons.contacts_outlined, Icons.contacts,
          AppStrings.t('navCustomers', isAr)));
    }

    if (hasPerm('canAccessSettings')) {
      items.add(_NavItem('/settings', Icons.settings_outlined, Icons.settings,
          AppStrings.t('navSettings', isAr)));
    }

    return items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authProvider);
    final tenantType = authState.tenantType ?? TenantType.pool;
    final role       = authState.role;
    final permissions = authState.permissions;
    final isAr       = ref.watch(isArabicProvider);

    final navItems      = _buildNavItems(tenantType, role, permissions, isAr);
    final location      = GoRouterState.of(context).uri.path;

    int selectedIndex = navItems.indexWhere((n) => location.startsWith(n.path));
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex.clamp(0, navItems.length - 1),
            onDestinationSelected: (index) {
              context.go(navItems[index].path);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _tenantColor(tenantType).withOpacity(0.15),
                    child: Icon(_tenantIcon(tenantType), color: _tenantColor(tenantType)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tenantLabel(tenantType),
                    style: TextStyle(fontWeight: FontWeight.bold, color: _tenantColor(tenantType)),
                  ),
                  Text(
                    role ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            destinations: navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Color _tenantColor(TenantType type) {
    switch (type) {
      case TenantType.pool:   return Colors.blue;
      case TenantType.gym:    return Colors.orange;
      case TenantType.chalet: return Colors.green;
    }
  }

  IconData _tenantIcon(TenantType type) {
    switch (type) {
      case TenantType.pool:   return Icons.pool;
      case TenantType.gym:    return Icons.fitness_center;
      case TenantType.chalet: return Icons.villa;
    }
  }

  String _tenantLabel(TenantType type) {
    switch (type) {
      case TenantType.pool:   return 'Pool';
      case TenantType.gym:    return 'Gym';
      case TenantType.chalet: return 'Chalet';
    }
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);
}
