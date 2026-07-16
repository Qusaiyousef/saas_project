import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/tenant_type.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/shell_screen.dart'; // To get NavItem and buildNavItems

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authProvider);
    final tenantType = authState.tenantType ?? TenantType.pool;
    final role       = authState.role;
    final permissions = authState.permissions;
    final isAr       = ref.watch(isArabicProvider);
    final colors     = Theme.of(context).colorScheme;

    final navItems = buildNavItems(tenantType, role, permissions, isAr);
    final location = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    backgroundImage: const AssetImage('assets/app_icon.png'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    role ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isSelected = location.startsWith(item.path);
                  return ListTile(
                    leading: Icon(isSelected ? item.selectedIcon : item.icon, 
                        color: isSelected ? colors.primary : colors.onSurfaceVariant),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      context.go(item.path);
                    },
                  );
                },
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
