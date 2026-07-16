import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/customers_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import 'package:intl/intl.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  int? _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return null;
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return null;

    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref, bool isAr) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime? selectedDob;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final dobStr = selectedDob != null
              ? DateFormat('yyyy-MM-dd').format(selectedDob!)
              : (AppStrings.t('notSet', isAr));

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(AppStrings.t('customerAddNew', isAr)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('customerName', isAr),
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('customerPhone', isAr),
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    leading: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(AppStrings.t('customerDOB', isAr)),
                    subtitle: Text(
                      dobStr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDob = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.t('cancel', isAr)),
              ),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;
                        setState(() => isLoading = true);
                        try {
                          await ref
                              .read(customersProvider.notifier)
                              .addCustomer(
                                nameController.text.trim(),
                                phoneController.text.trim(),
                                selectedDob,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(AppStrings.t('save', isAr)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPayDebtDialog(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
    Map<String, dynamic> c,
  ) {
    final amountController = TextEditingController();
    bool isPaying = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(AppStrings.t('payDebt', isAr)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppStrings.t('customerColon', isAr)} ${c['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.t('remainingDebt', isAr)} \$${((c['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.t('amountToPayNow', isAr),
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.t('cancel', isAr)),
              ),
              ElevatedButton.icon(
                onPressed: isPaying
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) return;

                        setState(() => isPaying = true);
                        try {
                          await ref
                              .read(paymentsProvider.notifier)
                              .addPayment(
                                c['id'],
                                null,
                                null,
                                amount,
                                'Debt payment',
                              );
                          ref.invalidate(customersProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.t('paymentSuccessful', isAr),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isPaying = false);
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                icon: isPaying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(AppStrings.t('payBtn', isAr)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentHistory(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
    String customerId,
    String customerName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${AppStrings.t('paymentHistoryColon', isAr)} $customerName',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: ref
                .read(paymentsProvider.notifier)
                .getCustomerPayments(customerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                );
              }
              final payments = snapshot.data ?? [];
              if (payments.isEmpty) {
                return Text(AppStrings.t('noPaymentHistory', isAr));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final date = DateTime.parse(p['paymentDate']).toLocal();
                  return ListTile(
                    leading: Icon(
                      Icons.payment,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('\$${p['amount']}'),
                    subtitle: Text(
                      '${date.toString().split('.')[0]}\n${p['notes'] ?? ''}',
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('closeBtn', isAr)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final isAr = ref.watch(isArabicProvider);
    final s = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from shell
      appBar: MediaQuery.of(context).size.width < 1024
          ? AppBar(
              title: Text(AppStrings.t('customersTitle', isAr)),
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
                            AppStrings.t('customersTitle', isAr),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            s('customersSubtitle'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddCustomerDialog(context, ref, isAr),
                        icon: const Icon(Icons.add),
                        label: Text(AppStrings.t('customerAddNew', isAr)),
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

              // Data Table Container
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header & Search
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'All Customers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: AppStrings.t(
                                      'searchNamePhone',
                                      isAr,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                    ),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                  ),
                                  onChanged: (val) => setState(
                                    () => _searchQuery = val.toLowerCase(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Table
                        SizedBox(
                          height: 600,
                          child: customersAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, stack) => Center(
                              child: Text(
                                '${AppStrings.t('error', isAr)}: $err',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            data: (customers) {
                              if (customers.isEmpty) {
                                return Center(
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
                                      const SizedBox(height: 16),
                                      Text(
                                        AppStrings.t('customerNoData', isAr),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final filteredCustomers = customers.where((c) {
                                final name = (c['name'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final phone = (c['phone'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return name.contains(_searchQuery) ||
                                    phone.contains(_searchQuery);
                              }).toList();

                              if (filteredCustomers.isEmpty) {
                                return Center(
                                  child: Text(
                                    AppStrings.t('noResultsFound', isAr),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }

                              return DataTable2(
                                columnSpacing: 16,
                                horizontalMargin: 24,
                                minWidth: 900,
                                headingRowColor: WidgetStateProperty.all(
                                  Theme.of(
                                    context,
                                  ).cardColor.withValues(alpha: 0.5),
                                ),
                                dataRowColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.hovered))
                                    return Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.05);
                                  return null;
                                }),
                                dividerThickness: 0.5,
                                columns: [
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('customerName', isAr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    size: ColumnSize.L,
                                  ),
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('customerPhone', isAr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    size: ColumnSize.M,
                                  ),
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('customerAge', isAr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    size: ColumnSize.S,
                                  ),
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('customerTotalPaid', isAr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    size: ColumnSize.M,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('customerBalance', isAr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    size: ColumnSize.M,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: const Text(''),
                                    size: ColumnSize.L,
                                  ), // Actions
                                ],
                                rows: filteredCustomers.map((c) {
                                  final age = _calculateAge(c['dateOfBirth']);
                                  final balance =
                                      (c['balance'] as num?)?.toDouble() ?? 0.0;
                                  final totalPaid =
                                      (c['totalPaid'] as num?)?.toDouble() ??
                                      0.0;
                                  final hasDebt = balance > 0;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme.primary
                                                  .withValues(alpha: 0.15),
                                              child: Text(
                                                (c['name'] as String? ?? 'U')[0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                c['name'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          c['phone'] ?? '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          age != null ? age.toString() : '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '\$${totalPaid.toStringAsFixed(2)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasDebt
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.error.withValues(alpha: 0.15)
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            hasDebt
                                                ? '\$${balance.toStringAsFixed(2)}'
                                                : '\$0.00',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: hasDebt
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (hasDebt)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.payments,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  size: 20,
                                                ),
                                                tooltip: AppStrings.t(
                                                  'payDebt',
                                                  isAr,
                                                ),
                                                onPressed: () =>
                                                    _showPayDebtDialog(
                                                      context,
                                                      ref,
                                                      isAr,
                                                      c,
                                                    ),
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.history,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                size: 20,
                                              ),
                                              tooltip: AppStrings.t(
                                                'paymentHistory',
                                                isAr,
                                              ),
                                              onPressed: () =>
                                                  _showPaymentHistory(
                                                    context,
                                                    ref,
                                                    isAr,
                                                    c['id'],
                                                    c['name'],
                                                  ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                                size: 20,
                                              ),
                                              tooltip: AppStrings.t(
                                                'delete',
                                                isAr,
                                              ),
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: Text(
                                                      AppStrings.t(
                                                        'confirmDelete',
                                                        isAr,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      AppStrings.t(
                                                        'customerDeleteWarning',
                                                        isAr,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        child: Text(
                                                          AppStrings.t(
                                                            'cancel',
                                                            isAr,
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .error,
                                                              foregroundColor:
                                                                  Theme.of(context).colorScheme.onError,
                                                            ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              true,
                                                            ),
                                                        child: Text(
                                                          AppStrings.t(
                                                            'delete',
                                                            isAr,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  try {
                                                    await ref
                                                        .read(
                                                          customersProvider
                                                              .notifier,
                                                        )
                                                        .deleteCustomer(
                                                          c['id'],
                                                        );
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Error: $e',
                                                          ),
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
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
}
