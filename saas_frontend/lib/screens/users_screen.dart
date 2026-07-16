import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import '../models/tenant_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/users_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final isAr = ref.watch(isArabicProvider);
    final authState = ref.watch(authProvider);
    final isCurrentUserAdmin = authState.role == 'Admin';
    String s(String key) => AppStrings.t(key, isAr);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from shell
      appBar: MediaQuery.of(context).size.width < 1024
          ? AppBar(
              title: Text(s('usersTitle')),
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
              // Page Header
              if (MediaQuery.of(context).size.width >= 1024)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s('usersTitle'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(s("usersSubtitle"),
                           
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (isCurrentUserAdmin)
                        ElevatedButton.icon(
                          onPressed: () => _showCreateDialog(context, ref),
                          icon: const Icon(Icons.person_add),
                          label: Text(s('usersAddNew')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Users List Container
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: usersAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Error loading users: $err',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                        data: (users) {
                          if (users.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(48),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No users found.',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final role =
                                  user['role'] as String? ?? 'Employee';
                              final isAdmin = role == 'Admin';

                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor
                                      .withValues(alpha: 0.2),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isAdmin
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withValues(alpha: 0.15)
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.15),
                                    child: Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                      color: isAdmin
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  title: Text(
                                    user['fullName'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      user['email'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? Theme.of(context).colorScheme.primary
                                                    .withValues(alpha: 0.1)
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isAdmin
                                                ? Theme.of(context).colorScheme.primary
                                                      .withValues(alpha: 0.3)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          role,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isAdmin
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      if (isCurrentUserAdmin) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          tooltip: s('edit'),
                                          onPressed: () => _showEditDialog(
                                            context,
                                            ref,
                                            user,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                          tooltip: s('delete'),
                                          onPressed: () => _confirmDelete(
                                            context,
                                            ref,
                                            user,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, WidgetRef ref, String errorMsg) {
    final isAr = ref.read(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);

    String translatedMsg = errorMsg.replaceAll('Exception: ', '');
    if (translatedMsg.contains('modify an Admin account')) {
      translatedMsg = s('errorModifyAdmin');
    } else if (translatedMsg.contains('modify user permissions')) {
      translatedMsg = s('errorModifyPermissions');
    } else if (translatedMsg.contains('delete users')) {
      translatedMsg = s('errorDeleteUsers');
    } else if (translatedMsg.contains('create users')) {
      translatedMsg = s('errorCreateUsers');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(s('error')),
          ],
        ),
        content: Text(translatedMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s('ok'))),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final isAr = ref.read(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);
    final isChalet = ref.read(authProvider).tenantType == TenantType.chalet;

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    String selectedRole = 'Employee';
    bool loading = false;
    final permissions = {
      'canAccessDashboard': false,
      'canAccessCalendar': true,
      'canAccessPOS': true,
      'canAccessSubscriptions': true,
      'canAccessUsers': false,
      'canAccessFinance': false,
      'canAccessCustomers': true,
      'canAccessSettings': true,
    };

    if (isChalet) {
      permissions['canAccessSubscriptions'] = false;
      permissions['canAccessCustomers'] = false;
    }

    Widget buildPermissionCheckbox(
      String key,
      String label,
      IconData icon,
      StateSetter setState,
    ) {
      return CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        value: permissions[key] ?? false,
        onChanged: (val) async {
          if (key == 'canAccessUsers' && val == true) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s('usersWarningUsersPageTitle'))),
                  ],
                ),
                content: Text(s('usersWarningUsersPageDesc')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(s('cancel')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(s('ok')),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }
          setState(() {
            permissions[key] = val ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        bool obscurePass = true;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(s('usersCreateTitle')),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8), // Prevent outline cropping
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${s('usersFullName')} *',
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: '${s('usersEmail')} *',
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: '${s('usersPassword')} *',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePass = !obscurePass),
                        ),
                        border: const OutlineInputBorder(),
                        helperText: s('usersPasswordHint'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: s('usersRole'),
                        prefixIcon: const Icon(Icons.security),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Employee',
                          child: Text(s('usersEmployee')),
                        ),
                        DropdownMenuItem(
                          value: 'Admin',
                          child: Text(s('usersAdmin')),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedRole = val!;
                          if (val == 'Admin') {
                            permissions['canAccessDashboard'] = true;
                            permissions['canAccessUsers'] = true;
                            permissions['canAccessFinance'] = true;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s('usersPagePermissions'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Column(
                      children: [
                        buildPermissionCheckbox(
                          'canAccessDashboard',
                          s('navDashboard'),
                          Icons.dashboard,
                          setState,
                        ),
                        buildPermissionCheckbox(
                          'canAccessCalendar',
                          s('navCalendar'),
                          Icons.calendar_today,
                          setState,
                        ),
                        buildPermissionCheckbox(
                          'canAccessPOS',
                          s('navPos'),
                          Icons.point_of_sale,
                          setState,
                        ),
                        if (!isChalet)
                          buildPermissionCheckbox(
                            'canAccessSubscriptions',
                            s('navSubscriptions'),
                            Icons.card_membership,
                            setState,
                          ),
                        buildPermissionCheckbox(
                          'canAccessUsers',
                          s('navUsers'),
                          Icons.people,
                          setState,
                        ),
                        buildPermissionCheckbox(
                          'canAccessFinance',
                          s('navFinance'),
                          Icons.attach_money,
                          setState,
                        ),
                        if (!isChalet)
                          buildPermissionCheckbox(
                            'canAccessCustomers',
                            s('navCustomers'),
                            Icons.groups,
                            setState,
                          ),

                        buildPermissionCheckbox(
                          'canAccessSettings',
                          s('navSettings'),
                          Icons.settings,
                          setState,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty ||
                            passCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('All fields are required'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                          return;
                        }
                        setState(() => loading = true);
                        try {
                          await ref
                              .read(usersProvider.notifier)
                              .createUser(
                                email: emailCtrl.text.trim(),
                                fullName: nameCtrl.text.trim(),
                                password: passCtrl.text,
                                role: selectedRole,
                                permissions: permissions,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s('usersCreated')),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => loading = false);
                          if (context.mounted) {
                            _showErrorDialog(context, ref, e.toString());
                          }
                        }
                      },
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(s('usersCreateUser')),
              ),
            ],
          );
        },
      );
    },
  );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) {
    final isAr = ref.read(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);
    final isChalet = ref.read(authProvider).tenantType == TenantType.chalet;

    final nameCtrl = TextEditingController(text: user['fullName'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final passCtrl = TextEditingController();

    String selectedRole = user['role'] ?? 'Employee';
    bool loading = false;
    final Map<String, bool> permissions = Map<String, bool>.from(
      user['permissions'] ??
          {
            'canAccessDashboard': selectedRole != 'Employee',
            'canAccessCalendar': true,
            'canAccessPOS': true,
            'canAccessSubscriptions': true,
            'canAccessUsers': selectedRole != 'Employee',
            'canAccessFinance': selectedRole != 'Employee',
            'canAccessCustomers': true,
            'canAccessSettings': true,
          },
    );

    if (isChalet) {
      permissions['canAccessSubscriptions'] = false;
      permissions['canAccessCustomers'] = false;
    }

    Widget buildPermissionCheckbox(
      String key,
      String label,
      IconData icon,
      StateSetter setState,
    ) {
      return CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        value: permissions[key] ?? false,
        onChanged: (val) async {
          if (key == 'canAccessUsers' && val == true) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s('usersWarningUsersPageTitle'))),
                  ],
                ),
                content: Text(s('usersWarningUsersPageDesc')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(s('cancel')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(s('ok')),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }
          setState(() {
            permissions[key] = val ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        bool obscurePass = true;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(s('usersEditTitle')),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8), // Prevent outline cropping
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: s('usersFullName'),
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: s('usersEmail'),
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: s('usersNewPassword'),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePass = !obscurePass),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: s('usersRole'),
                        prefixIcon: const Icon(Icons.security),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Employee',
                          child: Text(s('usersEmployee')),
                        ),
                        DropdownMenuItem(
                          value: 'Admin',
                          child: Text(s('usersAdmin')),
                        ),
                      ],
                      onChanged: (val) => setState(() => selectedRole = val!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s('usersPagePermissions'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Column(
                      children: [
                        buildPermissionCheckbox(
                          'canAccessDashboard',
                          s('navDashboard'),
                          Icons.dashboard,
                          setState,
                        ),
                        buildPermissionCheckbox(
                          'canAccessCalendar',
                          s('navCalendar'),
                          Icons.calendar_today,
                          setState,
                        ),
                        buildPermissionCheckbox(
                          'canAccessPOS',
                          s('navPos'),
                          Icons.point_of_sale,
                          setState,
                        ),
                        if (!isChalet)
                          buildPermissionCheckbox(
                            'canAccessSubscriptions',
                            s('navSubscriptions'),
                            Icons.card_membership,
                            setState,
                          ),
                        buildPermissionCheckbox(
                          'canAccessUsers',
                          s('navUsers'),
                          Icons.people,
                          setState,
                        ),
                        buildPermissionCheckbox(
                          'canAccessFinance',
                          s('navFinance'),
                          Icons.attach_money,
                          setState,
                        ),
                        if (!isChalet)
                          buildPermissionCheckbox(
                            'canAccessCustomers',
                            s('navCustomers'),
                            Icons.groups,
                            setState,
                          ),
                        buildPermissionCheckbox(
                          'canAccessSettings',
                          s('navSettings'),
                          Icons.settings,
                          setState,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s('cancel')),
              ),
              ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() => loading = true);
                        try {
                          await ref
                              .read(usersProvider.notifier)
                              .updateUser(
                                id: user['id'],
                                email: emailCtrl.text.trim(),
                                fullName: nameCtrl.text.trim(),
                                password: passCtrl.text.isNotEmpty
                                    ? passCtrl.text
                                    : null,
                                role: selectedRole,
                                permissions: permissions,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s('usersUpdated')),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => loading = false);
                          if (context.mounted) {
                            _showErrorDialog(context, ref, e.toString());
                          }
                        }
                      },
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(s('usersSaveChanges')),
              ),
            ],
          );
        },
      );
    },
  );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) {
    final isAdmin = (user['role'] as String?) == 'Admin';
    final isAr = ref.read(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: isAdmin
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(s('usersDeleteTitle')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s('usersAreYouSure')} "${user['fullName']}"?'),
            const SizedBox(height: 8),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s('usersAdminWarning'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              s('usersCannotUndo'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(usersProvider.notifier).deleteUser(user['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s('usersDeleted')),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final errorMsg = e.toString().replaceAll('Exception: ', '');
                  showDialog(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            Icons.block,
                            color: Theme.of(context).colorScheme.error,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text('Cannot Delete User'),
                        ],
                      ),
                      content: Text(
                        errorMsg,
                        style: const TextStyle(fontSize: 15),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
