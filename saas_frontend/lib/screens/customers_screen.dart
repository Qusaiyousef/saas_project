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
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
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
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final dobStr = selectedDob != null ? DateFormat('yyyy-MM-dd').format(selectedDob!) : (isAr ? 'لم يحدد' : 'Not Set');
        
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_add, color: Colors.blue),
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
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(AppStrings.t('customerDOB', isAr)),
                  subtitle: Text(dobStr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setState(() => isLoading = true);
                try {
                  await ref.read(customersProvider.notifier).addCustomer(
                    nameController.text.trim(),
                    phoneController.text.trim(),
                    selectedDob,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.save),
              label: Text(AppStrings.t('save', isAr)),
            ),
          ],
        );
      }),
    );
  }

  void _showPayDebtDialog(BuildContext context, WidgetRef ref, bool isAr, Map<String, dynamic> c) {
    final amountController = TextEditingController();
    bool isPaying = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(isAr ? 'تسديد دفعة' : 'Pay Debt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${isAr ? 'العميل:' : 'Customer:'} ${c['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${isAr ? 'الديون المتبقية:' : 'Remaining Debt:'} \$${((c['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isAr ? 'المبلغ المراد سداده الآن' : 'Amount to pay now',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.t('cancel', isAr))),
            ElevatedButton.icon(
              onPressed: isPaying ? null : () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                
                setState(() => isPaying = true);
                try {
                  await ref.read(paymentsProvider.notifier).addPayment(c['id'], null, null, amount, 'Debt payment');
                  ref.invalidate(customersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم سداد الدفعة بنجاح' : 'Payment successful'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  setState(() => isPaying = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              icon: isPaying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.payment),
              label: Text(isAr ? 'دفع' : 'Pay'),
            ),
          ],
        );
      }),
    );
  }

  void _showPaymentHistory(BuildContext context, WidgetRef ref, bool isAr, String customerId, String customerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isAr ? 'سجل الدفعات:' : 'Payment History:'} $customerName'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: ref.read(paymentsProvider.notifier).getCustomerPayments(customerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              }
              final payments = snapshot.data ?? [];
              if (payments.isEmpty) {
                return Text(isAr ? 'لا يوجد سجل دفعات.' : 'No payment history found.');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final date = DateTime.parse(p['paymentDate']).toLocal();
                  return ListTile(
                    leading: const Icon(Icons.payment, color: Colors.green),
                    title: Text('\$${p['amount']}'),
                    subtitle: Text('${date.toString().split('.')[0]}\n${p['notes'] ?? ''}'),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إغلاق' : 'Close')),
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
      appBar: AppBar(
        title: Text(s('customersTitle')),
        elevation: 2,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddCustomerDialog(context, ref, isAr),
            icon: const Icon(Icons.add),
            label: Text(s('customerAddNew')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: isAr ? 'بحث بالاسم أو رقم الهاتف...' : 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('${s('error')}: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(s('customerNoData'), style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCustomerDialog(context, ref, isAr),
                          icon: const Icon(Icons.add),
                          label: Text(s('customerAddNew')),
                        ),
                      ],
                    ),
                  );
                }

                final filteredCustomers = customers.where((c) {
                  final name = (c['name'] ?? '').toString().toLowerCase();
                  final phone = (c['phone'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || phone.contains(_searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Text(isAr ? 'لم يتم العثور على نتائج.' : 'No results found.', style: const TextStyle(color: Colors.grey)),
                  );
                }

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  headingRowColor: WidgetStateProperty.all(Colors.blue.withValues(alpha: 0.05)),
                  columns: [
                    DataColumn2(label: Text(s('customerName')), size: ColumnSize.L),
                    DataColumn(label: Text(s('customerPhone'))),
                    DataColumn2(label: Text(s('customerAge')), size: ColumnSize.S),
                    DataColumn(label: Text(s('customerTotalPaid'))),
                    DataColumn(label: Text(s('customerBalance'))),
                    DataColumn2(label: const Text(''), size: ColumnSize.S), // Actions
                  ],
                  rows: filteredCustomers.map((c) {
                    final age = _calculateAge(c['dateOfBirth']);
                    final balance = (c['balance'] as num?)?.toDouble() ?? 0.0;
                    final totalPaid = (c['totalPaid'] as num?)?.toDouble() ?? 0.0;
                    final hasDebt = balance > 0;

                    return DataRow(cells: [
                      DataCell(Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: Text(
                            (c['name'] as String? ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ])),
                      DataCell(Text(c['phone'] ?? '-')),
                      DataCell(Text(age != null ? age.toString() : '-')),
                      DataCell(Text('\$${totalPaid.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      DataCell(
                        Text(
                          hasDebt ? '\$${balance.toStringAsFixed(2)}' : '\$0.00',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasDebt ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasDebt)
                              IconButton(
                                icon: const Icon(Icons.payments, color: Colors.green, size: 20),
                                tooltip: isAr ? 'تسديد الدفعات' : 'Pay Debt',
                                onPressed: () => _showPayDebtDialog(context, ref, isAr, c),
                              ),
                            IconButton(
                              icon: const Icon(Icons.history, color: Colors.blue, size: 20),
                              tooltip: isAr ? 'سجل الدفعات' : 'Payment History',
                              onPressed: () => _showPaymentHistory(context, ref, isAr, c['id'], c['name']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          tooltip: s('delete'),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(s('confirmDelete')),
                                content: Text(s('customerDeleteWarning')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s('cancel'))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(s('delete')),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await ref.read(customersProvider.notifier).deleteCustomer(c['id']);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                );
              },
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
