import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/finance_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../services/print_service.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _filterType = 'All'; // All, Bookings, Subscriptions
  String _searchQuery = '';
  int? _sortColumnIndex = 0; // Default to Date
  bool _sortAscending = false; // Newest first
  
  String _dateRangePreset = 'All Time'; // All Time, Today, This Week, This Month, Custom
  DateTime? _startDate;
  DateTime? _endDate;

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateRangePreset = 'Custom';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalEntries =
        ref.watch(financeTransactionsProvider).value?.length ?? 0;
    final summaryAsync = ref.watch(financeSummaryProvider);
    final transactionsAsync = ref.watch(financeTransactionsProvider);

    // We now use summary['totalCash'] from the backend directly.

    final isAr = ref.watch(isArabicProvider);
    String s(String key) => AppStrings.t(key, isAr);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from shell
      appBar: MediaQuery.of(context).size.width < 1024
          ? AppBar(
              title: Text(s('financeTitle')),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.print, color: Theme.of(context).colorScheme.primary),
                  tooltip: s('print'),
                  onPressed: transactionsAsync.value == null ? null : () => _printReport(
                    transactionsAsync.value!, s('financeTitle'), isAr
                  ),
                ),
              ],
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
                            s('financeTitle'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            s('finSubtitle'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: transactionsAsync.value == null ? null : () => _printReport(
                          transactionsAsync.value!, s('financeTitle'), isAr
                        ),
                        icon: const Icon(Icons.print),
                        label: Text(AppStrings.t('print', isAr)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),

              // KPI Summary
              summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    '${s('error')}: $e',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                data: (summary) {
                  // Recompute summary if date filter is applied
                  double finalTotalRev = (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
                  double finalTotalCash = (summary['totalCash'] as num?)?.toDouble() ?? 0.0;

                  if ((_startDate != null && _endDate != null) || _filterType != 'All' || _searchQuery.isNotEmpty) {
                    final allTx = transactionsAsync.value ?? [];
                    finalTotalRev = 0;
                    finalTotalCash = 0;
                    for (var t in allTx) {
                      final matchesSearch = (t['customerName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                            (t['type']?.toString().toLowerCase().contains(_searchQuery) ?? false);
                      final matchesType = _filterType == 'All' || t['type'] == _filterType;
                      bool matchesDate = true;
                      if (_startDate != null && _endDate != null) {
                        final dt = DateTime.parse(t['date']).toLocal();
                        matchesDate = dt.compareTo(_startDate!) >= 0 && dt.compareTo(_endDate!) <= 0;
                      }
                      if (matchesSearch && matchesType && matchesDate) {
                        final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
                        finalTotalRev += amt;
                        if (t['method'] == 'Cash') {
                          finalTotalCash += amt;
                        }
                      }
                    }
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final kpi1 = _buildKpiCard(
                        context,
                        s('finCurrentBalance'),
                        '\$${finalTotalRev.toStringAsFixed(2)}',
                        Icons.account_balance,
                        s('finLastMonth'),
                        isPositive: true,
                      );
                      final kpi2 = _buildKpiCard(
                        context,
                        s('finTotalCash'),
                        '\$${finalTotalCash.toStringAsFixed(2)}',
                        Icons.payments,
                        s('finReconciled'),
                        isPositive: null,
                        actionText: s('finReconcileNow'),
                      );

                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: kpi1),
                            const SizedBox(width: 16),
                            Expanded(child: kpi2),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [kpi1, const SizedBox(height: 16), kpi2],
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // Transactions Ledger
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
                        // Ledger Header & Filters
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                AppStrings.t('finRecentTrans', isAr),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: s('finSearchHint'),
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          size: 20,
                                        ),
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                      ),
                                      onChanged: (val) => setState(
                                        () => _searchQuery = val.toLowerCase(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context).cardColor,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _filterType,
                                        items: [
                                          DropdownMenuItem(
                                            value: 'All',
                                            child: Text(
                                              AppStrings.t('finAllTypes', isAr),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Bookings',
                                            child: Text(
                                              AppStrings.t('finBookings', isAr),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Subscriptions',
                                            child: Text(
                                              AppStrings.t(
                                                'finSubscriptions',
                                                isAr,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(() => _filterType = val);
                                        },
                                      ),
                                    ),
                                  ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context).cardColor,
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _dateRangePreset,
                                          items: [
                                            DropdownMenuItem(
                                              value: 'All Time',
                                              child: Text(isAr ? 'كل الأوقات' : 'All Time'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Today',
                                              child: Text(isAr ? 'اليوم' : 'Today'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'This Week',
                                              child: Text(isAr ? 'هذا الأسبوع' : 'This Week'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'This Month',
                                              child: Text(isAr ? 'هذا الشهر' : 'This Month'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Custom',
                                              child: Text(isAr ? 'تخصيص...' : 'Custom...'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              if (val == 'Custom') {
                                                _selectDateRange(context);
                                              } else {
                                                _applyPreset(val);
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                        // Ledger Table
                        SizedBox(
                          height: 600,
                          child: transactionsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Center(
                              child: Text(
                                '${s('error')}: $e',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            data: (transactions) {
                              if (transactions.isEmpty) {
                                return _buildEmptyState(
                                  context,
                                  s('finNoTransTitle'),
                                  s('finNoTransSub'),
                                );
                              }

                              final filtered = transactions.where((t) {
                                final matchesSearch = (t['customerName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                                      (t['type']?.toString().toLowerCase().contains(_searchQuery) ?? false);
                                final matchesType = _filterType == 'All' || t['type'] == _filterType;
                                
                                bool matchesDate = true;
                                if (_startDate != null && _endDate != null) {
                                  final dt = DateTime.parse(t['date']).toLocal();
                                  matchesDate = dt.compareTo(_startDate!) >= 0 && dt.compareTo(_endDate!) <= 0;
                                }

                                return matchesSearch && matchesType && matchesDate;
                              }).toList();

                              if (_sortColumnIndex != null) {
                                filtered.sort((a, b) {
                                  if (_sortColumnIndex == 0) {
                                    final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
                                    final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
                                    return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
                                  } else if (_sortColumnIndex == 2) {
                                    final aMethod = a['method']?.toString() ?? '';
                                    final bMethod = b['method']?.toString() ?? '';
                                    return _sortAscending ? aMethod.compareTo(bMethod) : bMethod.compareTo(aMethod);
                                  } else if (_sortColumnIndex == 4) {
                                    final aAmt = double.tryParse('${a['amount']}') ?? 0.0;
                                    final bAmt = double.tryParse('${b['amount']}') ?? 0.0;
                                    return _sortAscending ? aAmt.compareTo(bAmt) : bAmt.compareTo(aAmt);
                                  }
                                  return 0;
                                });
                              }

                              if (filtered.isEmpty) {
                                return _buildEmptyState(
                                  context,
                                  s('finNoTransTitle'),
                                  s('finNoTransSub'),
                                );
                              }


                              return DataTable2(
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
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
                                  if (states.contains(WidgetState.hovered)) {
                                    return Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.05);
                                  }
                                  return null; // default
                                }),
                                dividerThickness: 0.5,
                                columns: [
                                  DataColumn2(
                                    onSort: _sort,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppStrings.t('financeDate', isAr),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (_sortColumnIndex != 0)
                                          const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                    size: ColumnSize.S,
                                  ),
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('financeDesc', isAr),
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
                                    onSort: _sort,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppStrings.t('finMethod', isAr),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (_sortColumnIndex != 2)
                                          const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                                      ],
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
                                  DataColumn2(
                                    onSort: _sort,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppStrings.t('financeAmount', isAr),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (_sortColumnIndex != 4)
                                          const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                ],
                                rows: filtered.map((t) {
                                  final dt = DateTime.parse(
                                    t['date'],
                                  ).toLocal();
                                  final isBooking = t['type'] == 'Booking';
                                  final amount =
                                      double.tryParse('${t['amount']}') ?? 0.0;
                                  final paymentMethodStr = t['method']?.toString() ?? (isBooking ? 'Cash' : 'Card');
                                  final isTransfer = paymentMethodStr.toLowerCase() == 'transfer';
                                  final pIcon = isTransfer
                                      ? Icons.swap_horiz
                                      : (paymentMethodStr.toLowerCase() == 'card' ? Icons.credit_card : Icons.payments);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          '${dt.day}/${dt.month}/${dt.year}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          isBooking
                                              ? '${AppStrings.t('dashBookingLabel', isAr)} - ${t['customerName'] ?? 'Walk-in'}'
                                              : '${AppStrings.t('finSubscriptions', isAr)} - ${t['customerName'] ?? 'Walk-in'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            Icon(
                                              pIcon,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              paymentMethodStr,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            AppStrings.t('completed', isAr),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '+\$${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),

                        // Pagination Footer
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).cardColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppStrings.t('finShowing', isAr)} $totalEntries',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(),
                            ],
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

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    String subtitle, {
    required bool? isPositive,
    String? actionText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Stack(
            children: [
              Positioned.directional(
                textDirection: Directionality.of(context),
                end: -20,
                top: 20,
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrains Mono',
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (isPositive == true)
                                Icon(
                                  Icons.trending_up,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              if (isPositive == false)
                                Icon(
                                  Icons.trending_down,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              if (isPositive == null)
                                Icon(
                                  Icons.sync,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPositive == true
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (actionText != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              actionText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _dateRangePreset = preset;
      if (preset == 'All Time') {
        _startDate = null;
        _endDate = null;
      } else if (preset == 'Today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'This Week') {
        _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'This Month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
    });
  }

  Future<void> _printReport(List<dynamic> allTx, String title, bool isAr) async {
    final filteredTx = allTx.where((t) {
      final matchesSearch = (t['customerName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                            (t['type']?.toString().toLowerCase().contains(_searchQuery) ?? false);
      final matchesType = _filterType == 'All' || t['type'] == _filterType;
      
      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        final dt = DateTime.parse(t['date']).toLocal();
        matchesDate = dt.isAfter(_startDate!) && dt.isBefore(_endDate!);
      }
      return matchesSearch && matchesType && matchesDate;
    }).toList();

    double totalRev = 0;
    double totalCash = 0;
    for(var tx in filteredTx) {
      final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      totalRev += amt;
      if (tx['method'] == 'Cash') {
        totalCash += amt;
      }
    }

    await PrintService.printFinanceReport(
      isAr: isAr,
      title: title,
      summary: {
        'totalRevenue': totalRev,
        'totalCash': totalCash
      },
      transactions: filteredTx,
      startDate: _startDate,
      endDate: _endDate,
    );
  }
}
