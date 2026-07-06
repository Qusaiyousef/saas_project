import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/subscription_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref, bool isAr, List<dynamic> customers) {
    String? selectedCustomerId;
    final nameController = TextEditingController(); // For new customer quick-add
    final amountPaidController = TextEditingController();
    String selectedPlan = '1 Month';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.card_membership, color: Colors.blue),
              const SizedBox(width: 8),
              Text(AppStrings.t('subAddNew', isAr)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownMenu<String?>(
                      expandedInsets: EdgeInsets.zero,
                      enableFilter: true,
                      leadingIcon: const Icon(Icons.search),
                      label: Text(isAr ? 'بحث عن عميل' : 'Search Customer'),
                      inputDecorationTheme: const InputDecorationTheme(
                        border: OutlineInputBorder(),
                      ),
                      dropdownMenuEntries: [
                        ...customers.map((c) {
                          final isSubbed = c['hasActiveSubscription'] == true;
                          final subText = isSubbed ? (isAr ? ' (مشترك)' : ' (Subscribed)') : '';
                          return DropdownMenuEntry<String?>(
                            value: c['id'],
                            label: '${c['name']}$subText',
                          );
                        }),
                      ],
                      onSelected: (val) => setState(() => selectedCustomerId = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    tooltip: AppStrings.t('customerAddNew', isAr),
                    onPressed: () {
                      _showCreateCustomerDialog(context, ref, isAr).then((_) {
                        // Just closes the dialog so user can reload or see it. 
                        // Note: To automatically select it, we would need to wait for the provider to update,
                        // but invalidating the provider will trigger a rebuild anyway.
                        Navigator.pop(ctx); 
                      });
                    },
                  ),
                ],
              ),
              if (selectedCustomerId == null) ...[
                const SizedBox(height: 16),
                Text(
                  isAr ? 'يرجى اختيار عميل أو إضافة عميل جديد' : 'Please select or add a new customer',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlan,
                decoration: InputDecoration(
                  labelText: AppStrings.t('subPlan', isAr),
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '1 Month',  child: Text('1 Month')),
                  DropdownMenuItem(value: '3 Months', child: Text('3 Months')),
                  DropdownMenuItem(value: '6 Months', child: Text('6 Months')),
                  DropdownMenuItem(value: '1 Year',   child: Text('1 Year (Best Value)')),
                ],
                onChanged: (val) => setState(() => selectedPlan = val!),
              ),
              const SizedBox(height: 8),
              // Price preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'إجمالي السعر:' : 'Total Price:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _planPrice(selectedPlan),
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountPaidController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isAr ? 'المبلغ المدفوع الان' : 'Amount Paid Now',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.t('cancel', isAr))),
            ElevatedButton.icon(
              onPressed: loading ? null : () async {
                  if (selectedCustomerId == null) return;
                  setState(() => loading = true);
                  try {
                    String finalCustId = selectedCustomerId!;
                    String customerName = customers.firstWhere((c) => c['id'] == finalCustId)['name'];

                  final months = _planToMonths(selectedPlan);
                  final priceStr = _planPrice(selectedPlan).replaceAll('\$', '');
                  final totalAmount = double.tryParse(priceStr) ?? 0.0;
                  final amountPaid = double.tryParse(amountPaidController.text) ?? totalAmount;
                  
                  await ref.read(subscriptionProvider.notifier).addSubscription(customerName, finalCustId, months, totalAmount, amountPaid);
                  ref.invalidate(customersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.t('subSuccessAdd', isAr)), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  setState(() => loading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${AppStrings.t('error', isAr)}: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(AppStrings.t('subAddNew', isAr)),
            ),
          ],
        );
      }),
    );
  }

  static String _planPrice(String plan) {
    switch (plan) {
      case '1 Month':  return '\$30';
      case '3 Months': return '\$80';
      case '6 Months': return '\$150';
      case '1 Year':   return '\$280';
      default:         return '';
    }
  }

  static int _planToMonths(String plan) {
    switch (plan) {
      case '1 Month':  return 1;
      case '3 Months': return 3;
      case '6 Months': return 6;
      case '1 Year':   return 12;
      default:         return 1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subData = ref.watch(subscriptionProvider);
    final customersData = ref.watch(customersProvider);
    final isAr = ref.watch(isArabicProvider);
    final s    = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('subTitle')),
        elevation: 2,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              final cust = customersData.asData?.value ?? [];
              _showAddDialog(context, ref, isAr, cust);
            },
            icon: const Icon(Icons.add),
            label: Text(s('subAddNew')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: subData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error: $err', textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (subs) => DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                empty: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_membership, size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(s('subNoSubs'), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final cust = customersData.asData?.value ?? [];
                          _showAddDialog(context, ref, isAr, cust);
                        },
                        icon: const Icon(Icons.add),
                        label: Text(s('subAddNew')),
                      ),
                    ],
                  ),
                ),
                columns: [
                  DataColumn2(label: Text(s('subMemberName')), size: ColumnSize.L),
                  DataColumn(label: Text(s('subStartDate'))),
                  DataColumn(label: Text(s('subEndDate'))),
                  DataColumn2(label: Text(isAr ? 'الأيام المتبقية' : 'Days Left'), size: ColumnSize.S),
                  DataColumn2(label: Text(s('subStatus')), size: ColumnSize.S),
                ],
                rows: subs.map((sub) {
                  final endDate = DateTime.parse(sub['endDate']);
                  final daysLeft = endDate.difference(DateTime.now()).inDays;
                  final isExpired = daysLeft < 0;
                  final isWarning = daysLeft >= 0 && daysLeft <= 7;

                  return DataRow(cells: [
                    DataCell(Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          (sub['customerName'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(sub['customerName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ])),
                    DataCell(Text(DateTime.parse(sub['startDate']).toLocal().toString().split(' ')[0])),
                    DataCell(Text(endDate.toLocal().toString().split(' ')[0])),
                    DataCell(Text(
                      isExpired ? s('subExpired') : '$daysLeft ${isAr ? 'يوم' : 'days'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.red : isWarning ? Colors.orange : Colors.green,
                      ),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isExpired ? Colors.red : Colors.green).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired ? s('subExpired') : s('subActive'),
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCustomerDialog(BuildContext context, WidgetRef ref, bool isAr) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime? selectedDob;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final dobStr = selectedDob != null ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}" : (isAr ? 'لم يحدد' : 'Not Set');
        return AlertDialog(
          title: Text(AppStrings.t('customerAddNew', isAr)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: AppStrings.t('customerName', isAr), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: AppStrings.t('customerPhone', isAr), border: const OutlineInputBorder()),
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
                  if (date != null) setState(() => selectedDob = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.t('cancel', isAr))),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setState(() => isLoading = true);
                try {
                  await ref.read(customersProvider.notifier).addCustomer(nameController.text.trim(), phoneController.text.trim(), selectedDob);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppStrings.t('save', isAr)),
            ),
          ],
        );
      }),
    );
  }
}
