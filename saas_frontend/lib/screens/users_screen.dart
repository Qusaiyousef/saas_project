import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: Text(s('usersTitle')),
        elevation: 2,
        actions: [
          if (isCurrentUserAdmin)
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.person_add),
              label: Text(s('usersAddNew')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading users: $err')),
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No users found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final role = user['role'] as String? ?? 'Employee';
                  final isAdmin = role == 'Admin';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin ? Colors.blue : Colors.grey,
                      ),
                    ),
                    title: Text(
                      user['fullName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isAdmin
                                  ? Colors.blue
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isCurrentUserAdmin) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: s('edit'),
                            onPressed: () => _showEditDialog(context, ref, user),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red.shade300,
                            ),
                            tooltip: s('delete'),
                            onPressed: () => _confirmDelete(context, ref, user),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
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
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(s('error')),
          ],
        ),
        content: Text(translatedMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('ok')),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final isAr = ref.read(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);

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

    Widget buildPermissionCheckbox(String key, String label, IconData icon, StateSetter setState) {
      return CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueGrey),
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
                    const Icon(Icons.warning_amber, color: Colors.orange),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.blue),
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
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '${s('usersPassword')} *',
                        prefixIcon: const Icon(Icons.lock),
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
                        DropdownMenuItem(value: 'Admin', child: Text(s('usersAdmin'))),
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
                    Text(s('usersPagePermissions'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Column(
                      children: [
                        buildPermissionCheckbox('canAccessDashboard', s('navDashboard'), Icons.dashboard, setState),
                        buildPermissionCheckbox('canAccessCalendar', s('navCalendar'), Icons.calendar_today, setState),
                        buildPermissionCheckbox('canAccessPOS', s('navPos'), Icons.point_of_sale, setState),
                        buildPermissionCheckbox('canAccessSubscriptions', s('navSubscriptions'), Icons.card_membership, setState),
                        buildPermissionCheckbox('canAccessUsers', s('navUsers'), Icons.people, setState),
                        buildPermissionCheckbox('canAccessFinance', s('navFinance'), Icons.attach_money, setState),
                        buildPermissionCheckbox('canAccessCustomers', s('navCustomers'), Icons.groups, setState),
                        buildPermissionCheckbox('canAccessSettings', s('navSettings'), Icons.settings, setState),
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
                            const SnackBar(
                              content: Text('All fields are required'),
                              backgroundColor: Colors.red,
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
                                backgroundColor: Colors.green,
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
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) {
    final isAr = ref.read(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);

    final nameCtrl = TextEditingController(text: user['fullName'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final passCtrl = TextEditingController();
    String selectedRole = user['role'] ?? 'Employee';
    bool loading = false;
    final Map<String, bool> permissions = Map<String, bool>.from(user['permissions'] ?? {
      'canAccessDashboard': selectedRole != 'Employee',
      'canAccessCalendar': true,
      'canAccessPOS': true,
      'canAccessSubscriptions': true,
      'canAccessUsers': selectedRole != 'Employee',
      'canAccessFinance': selectedRole != 'Employee',
      'canAccessCustomers': true,
      'canAccessSettings': true,
    });

    Widget buildPermissionCheckbox(String key, String label, IconData icon, StateSetter setState) {
      return CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueGrey),
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
                    const Icon(Icons.warning_amber, color: Colors.orange),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
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
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: s('usersNewPassword'),
                        prefixIcon: const Icon(Icons.lock),
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
                        DropdownMenuItem(value: 'Admin', child: Text(s('usersAdmin'))),
                      ],
                      onChanged: (val) => setState(() => selectedRole = val!),
                    ),
                    const SizedBox(height: 16),
                    Text(s('usersPagePermissions'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Column(
                      children: [
                        buildPermissionCheckbox('canAccessDashboard', s('navDashboard'), Icons.dashboard, setState),
                        buildPermissionCheckbox('canAccessCalendar', s('navCalendar'), Icons.calendar_today, setState),
                        buildPermissionCheckbox('canAccessPOS', s('navPos'), Icons.point_of_sale, setState),
                        buildPermissionCheckbox('canAccessSubscriptions', s('navSubscriptions'), Icons.card_membership, setState),
                        buildPermissionCheckbox('canAccessUsers', s('navUsers'), Icons.people, setState),
                        buildPermissionCheckbox('canAccessFinance', s('navFinance'), Icons.attach_money, setState),
                        buildPermissionCheckbox('canAccessCustomers', s('navCustomers'), Icons.groups, setState),
                        buildPermissionCheckbox('canAccessSettings', s('navSettings'), Icons.settings, setState),
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
                                backgroundColor: Colors.green,
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
      ),
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
            Icon(Icons.warning, color: isAdmin ? Colors.orange : Colors.red),
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s('usersAdminWarning'),
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              s('usersCannotUndo'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(usersProvider.notifier).deleteUser(user['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s('usersDeleted')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final errorMsg = e.toString().replaceAll('Exception: ', '');
                  showDialog(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.block, color: Colors.red, size: 28),
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
