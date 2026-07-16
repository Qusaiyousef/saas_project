import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/print_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/subscription_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String _searchQuery = '';
  bool _autoPrint = true;

  @override
  void initState() {
    super.initState();
    _initAutoPrint();
  }

  Future<void> _initAutoPrint() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _autoPrint = prefs.getBool('subAutoPrint') ?? true);
  }

  Future<void> _toggleAutoPrint(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subAutoPrint', val);
    if (mounted) setState(() => _autoPrint = val);
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
    List<dynamic> customers,
  ) {
    String? selectedCustomerId;
    final amountPaidController = TextEditingController();
    String selectedPlan = '1 Month';
    String selectedPaymentMethod = 'Cash';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                        label: Text(AppStrings.t('searchCustomer', isAr)),
                        inputDecorationTheme: const InputDecorationTheme(
                          border: OutlineInputBorder(),
                        ),
                        dropdownMenuEntries: [
                          ...customers.map((c) {
                            final isSubbed = c['hasActiveSubscription'] == true;
                            final subText = isSubbed
                                ? (AppStrings.t('subscribedSuffix', isAr))
                                : '';
                            return DropdownMenuEntry<String?>(
                              value: c['id'],
                              label: '${c['name']}$subText',
                            );
                          }),
                        ],
                        onSelected: (val) =>
                            setState(() => selectedCustomerId = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.person_add,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: AppStrings.t('customerAddNew', isAr),
                      onPressed: () {
                        _showCreateCustomerDialog(context, ref, isAr).then((_) {
                          Navigator.pop(ctx);
                        });
                      },
                    ),
                  ],
                ),
                if (selectedCustomerId == null) ...[
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t('pleaseSelectCustomer', isAr),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                    DropdownMenuItem(value: '1 Month', child: Text('1 Month')),
                    DropdownMenuItem(
                      value: '3 Months',
                      child: Text('3 Months'),
                    ),
                    DropdownMenuItem(
                      value: '6 Months',
                      child: Text('6 Months'),
                    ),
                    DropdownMenuItem(
                      value: '1 Year',
                      child: Text('1 Year (Best Value)'),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedPlan = val!),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.t('totalPriceColon', isAr),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _planPrice(selectedPlan),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountPaidController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.t('amountPaidNow', isAr),
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: isAr ? 'طريقة الدفع' : 'Payment Method',
                    prefixIcon: const Icon(Icons.payment),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Cash', child: Text(isAr ? 'كاش' : 'Cash')),
                    DropdownMenuItem(value: 'Transfer', child: Text(isAr ? 'حوالة' : 'Transfer')),
                  ],
                  onChanged: (val) => setState(() => selectedPaymentMethod = val!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(AppStrings.t('autoPrint', isAr)),
                  value: _autoPrint,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    _toggleAutoPrint(val);
                    setState(() {});
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.t('cancel', isAr)),
              ),
              ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        if (selectedCustomerId == null) return;
                        setState(() => loading = true);
                        try {
                          String finalCustId = selectedCustomerId!;
                          String customerName = customers.firstWhere(
                            (c) => c['id'] == finalCustId,
                          )['name'];

                          final months = _planToMonths(selectedPlan);
                          final priceStr = _planPrice(
                            selectedPlan,
                          ).replaceAll('\$', '');
                          final totalAmount = double.tryParse(priceStr) ?? 0.0;
                          final amountPaid =
                              double.tryParse(amountPaidController.text) ??
                              totalAmount;

                          await ref
                              .read(subscriptionProvider.notifier)
                              .addSubscription(
                                customerName,
                                finalCustId,
                                months,
                                totalAmount,
                                amountPaid,
                                selectedPaymentMethod,
                              );
                          ref.invalidate(customersProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            void doPrint() {
                              PrintService.printReceipt(
                                isAr: isAr,
                                title: AppStrings.t('receiptTitleSub', isAr),
                                customerName: customerName,
                                items: [{'name': selectedPlan, 'price': totalAmount}],
                                totalAmount: totalAmount,
                                amountPaid: amountPaid,
                                paymentMethod: selectedPaymentMethod,
                                date: DateTime.now(),
                              );
                            }

                            if (_autoPrint) doPrint();

                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(AppStrings.t('subSuccessAdd', isAr)),
                                  ],
                                ),
                                content: Text(AppStrings.t('subSuccessAdd', isAr)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dCtx);
                                      doPrint();
                                    },
                                    child: Text(AppStrings.t('printReceipt', isAr)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: Text(AppStrings.t('done', isAr)),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => loading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppStrings.t('error', isAr)}: $e',
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
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
                label: Text(AppStrings.t('subAddNew', isAr)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _planPrice(String plan) {
    switch (plan) {
      case '1 Month':
        return '\$30';
      case '3 Months':
        return '\$80';
      case '6 Months':
        return '\$150';
      case '1 Year':
        return '\$280';
      default:
        return '';
    }
  }

  static int _planToMonths(String plan) {
    switch (plan) {
      case '1 Month':
        return 1;
      case '3 Months':
        return 3;
      case '6 Months':
        return 6;
      case '1 Year':
        return 12;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subData = ref.watch(subscriptionProvider);
    final customersData = ref.watch(customersProvider);
    final isAr = ref.watch(isArabicProvider);
    final s = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from shell
      appBar: MediaQuery.of(context).size.width < 1024
          ? AppBar(
              title: Text(AppStrings.t('subTitle', isAr)),
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
                            AppStrings.t('subTitle', isAr),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            s('subSubtitle'),
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
                        onPressed: () {
                          final cust = customersData.asData?.value ?? [];
                          _showAddDialog(context, ref, isAr, cust);
                        },
                        icon: const Icon(Icons.add),
                        label: Text(AppStrings.t('subAddNew', isAr)),
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
                              Text(
                                AppStrings.t('supRecentTrans', isAr),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: AppStrings.t('searchName', isAr),
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
                          child: subData.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, _) => Center(
                              child: Text(
                                'Error: $err',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            data: (subs) {
                              final filteredSubs = subs.where((sub) {
                                final name = (sub['customerName'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return name.contains(_searchQuery);
                              }).toList();

                              if (filteredSubs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.card_membership,
                                        size: 64,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppStrings.t('subNoSubs', isAr),
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

                              return DataTable2(
                                columnSpacing: 16,
                                horizontalMargin: 24,
                                minWidth: 800,
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
                                      AppStrings.t('subMemberName', isAr),
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
                                      AppStrings.t('subStartDate', isAr),
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
                                      AppStrings.t('subEndDate', isAr),
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
                                      AppStrings.t('daysLeft', isAr),
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
                                      AppStrings.t('subStatus', isAr),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    size: ColumnSize.S,
                                  ),
                                  const DataColumn2(
                                    label: Text(''),
                                    size: ColumnSize.S,
                                  ),
                                ],
                                rows: filteredSubs.map((sub) {
                                  final endDate = DateTime.parse(
                                    sub['endDate'],
                                  );
                                  final daysLeft = endDate
                                      .difference(DateTime.now())
                                      .inDays;
                                  final isExpired = daysLeft < 0;
                                  final isWarning =
                                      daysLeft >= 0 && daysLeft <= 7;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                               backgroundColor: Theme.of(
                                                 context,
                                               ).colorScheme.primary.withValues(alpha: 0.1),
                                              child: Text(
                                                (sub['customerName']
                                                            as String? ??
                                                        'U')[0]
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
                                            Text(
                                              sub['customerName'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          DateTime.parse(
                                            sub['startDate'],
                                          ).toLocal().toString().split(' ')[0],
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          endDate.toLocal().toString().split(
                                            ' ',
                                          )[0],
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          isExpired
                                              ? AppStrings.t('subExpired', isAr)
                                              : '$daysLeft ${AppStrings.t('days', isAr)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isExpired
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.error
                                                : isWarning
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.secondary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
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
                                            color:
                                                (isExpired
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.error
                                                        : Theme.of(
                                                            context,
                                                           ).colorScheme.primary)
                                                     .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            isExpired
                                                ? AppStrings.t(
                                                    'subExpired',
                                                    isAr,
                                                  )
                                                : AppStrings.t(
                                                    'subActive',
                                                    isAr,
                                                  ),
                                            style: TextStyle(
                                              color: isExpired
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.print, size: 20),
                                          tooltip: AppStrings.t('printReceipt', isAr),
                                          onPressed: () {
                                            final mTotalAmount = double.tryParse(sub['totalAmount']?.toString() ?? '0') ?? 0.0;
                                            final mAmountPaid = double.tryParse(sub['amountPaid']?.toString() ?? '0') ?? 0.0;
                                            
                                            final subStart = DateTime.parse(sub['startDate']);
                                            final subEnd = DateTime.parse(sub['endDate']);
                                            final diffMonths = (subEnd.difference(subStart).inDays / 30).round();
                                            final planStr = isAr ? 'اشتراك $diffMonths شهر' : '$diffMonths Months';

                                            PrintService.printReceipt(
                                              isAr: isAr,
                                              title: AppStrings.t('receiptTitleSub', isAr),
                                              customerName: sub['customerName'] ?? '',
                                              items: [{'name': planStr, 'price': mTotalAmount}],
                                              totalAmount: mTotalAmount,
                                              amountPaid: mAmountPaid,
                                              paymentMethod: sub['paymentMethod'] ?? (isAr ? 'كاش' : 'Cash'),
                                              date: subStart,
                                            );
                                          },
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

  Future<void> _showCreateCustomerDialog(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
  ) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime? selectedDob;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final dobStr = selectedDob != null
              ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}"
              : (AppStrings.t('notSet', isAr));
          return AlertDialog(
            title: Text(AppStrings.t('customerAddNew', isAr)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('customerName', isAr),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('customerPhone', isAr),
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
                    if (date != null) setState(() => selectedDob = date);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.t('cancel', isAr)),
              ),
              ElevatedButton(
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
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.t('save', isAr)),
              ),
            ],
          );
        },
      ),
    );
  }
}
