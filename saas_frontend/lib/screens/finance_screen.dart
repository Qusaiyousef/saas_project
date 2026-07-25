import 'dart:convert';
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/finance_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../services/print_service.dart';
import '../utils/app_snackbar.dart';

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

  List<Map<String, dynamic>> _reconciliationLedger = [];

  @override
  void initState() {
    super.initState();
    _loadReconciliationState();
  }

  Future<void> _loadReconciliationState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('reconciliation_ledger_v2');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> rawList = jsonDecode(jsonStr);
        final List<Map<String, dynamic>> loaded = [];
        for (var item in rawList) {
          if (item != null && item is Map) {
            loaded.add(Map<String, dynamic>.from(item));
          }
        }
        if (mounted) {
          setState(() {
            _reconciliationLedger = loaded;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _reconciliationLedger = [];
          });
        }
      }
    }
  }

  Future<void> _addReconciliationRecord({
    required double amount,
    required String period,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newRecord = <String, dynamic>{
      'id': now.millisecondsSinceEpoch.toString(),
      'date': dateStr,
      'amount': amount,
      'period': period,
      'note': note.isNotEmpty ? note : '—',
    };

    final updatedList = [newRecord, ..._reconciliationLedger];
    await prefs.setString('reconciliation_ledger_v2', jsonEncode(updatedList));
    setState(() {
      _reconciliationLedger = updatedList;
    });
  }

  String _getCurrentFilterPeriodLabel(bool isAr) {
    if (_startDate != null && _endDate != null) {
      final startStr = '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}';
      final endStr = '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}';
      return isAr ? 'تخصيص ($startStr إلى $endStr)' : 'Custom ($startStr to $endStr)';
    }
    switch (_dateRangePreset) {
      case 'Today':
        return isAr ? 'اليوم' : 'Today';
      case 'This Week':
        return isAr ? 'هذا الأسبوع' : 'This Week';
      case 'This Month':
        return isAr ? 'هذا الشهر' : 'This Month';
      default:
        return isAr ? 'كل الأوقات' : 'All Time';
    }
  }

  bool _matchesFilterType(dynamic t) {
    if (_filterType == 'All') return true;
    final typeStr = t['type']?.toString() ?? '';
    if (_filterType == 'Bookings' &&
        (typeStr == 'Booking' || typeStr == 'Bookings'))
      return true;
    if (_filterType == 'Subscriptions' &&
        (typeStr == 'Subscription' || typeStr == 'Subscriptions'))
      return true;
    return typeStr == _filterType;
  }

  String _dateRangePreset =
      'All Time'; // All Time, Today, This Week, This Month, Custom
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
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
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
                  icon: Icon(
                    Icons.print,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: s('print'),
                  onPressed: transactionsAsync.value == null
                      ? null
                      : () => _printReport(
                          transactionsAsync.value!,
                          s('financeTitle'),
                          isAr,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: transactionsAsync.value == null
                            ? null
                            : () => _printReport(
                                transactionsAsync.value!,
                                s('financeTitle'),
                                isAr,
                              ),
                        icon: const Icon(Icons.print),
                        label: Text(AppStrings.t('print', isAr)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
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
                  double finalTotalRev =
                      (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
                  double finalTotalCash =
                      (summary['totalCash'] as num?)?.toDouble() ?? 0.0;

                  if ((_startDate != null && _endDate != null) ||
                      _filterType != 'All' ||
                      _searchQuery.isNotEmpty) {
                    final allTx = transactionsAsync.value ?? [];
                    finalTotalRev = 0;
                    finalTotalCash = 0;
                    for (var t in allTx) {
                      final matchesSearch =
                          (t['customerName']?.toString().toLowerCase().contains(
                                _searchQuery,
                              ) ??
                              false) ||
                          (t['type']?.toString().toLowerCase().contains(
                                _searchQuery,
                              ) ??
                              false);
                      final matchesType = _matchesFilterType(t);
                      bool matchesDate = true;
                      if (_startDate != null && _endDate != null) {
                        final dt = DateTime.parse(t['date']).toLocal();
                        matchesDate =
                            dt.compareTo(_startDate!) >= 0 &&
                            dt.compareTo(_endDate!) <= 0;
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
                      final matchedCount = transactionsAsync.value?.length ?? 0;
                      final kpi1 = _buildKpiCard(
                        context,
                        s('finCurrentBalance'),
                        '\$${finalTotalRev.toStringAsFixed(2)}',
                        Icons.account_balance,
                        '$matchedCount ${AppStrings.t('finTotalTransactionsRecorded', isAr)}',
                        isPositive: true,
                      );
                      final latestRec = _reconciliationLedger.isNotEmpty ? _reconciliationLedger.first : null;
                      final reconciliationSub = latestRec != null
                          ? (isAr 
                              ? 'آخر تسوية: \$${(latestRec['amount'] as num?)?.toStringAsFixed(2)} بتاريخ ${latestRec['date']}'
                              : 'Last Reconciled: \$${(latestRec['amount'] as num?)?.toStringAsFixed(2)} on ${latestRec['date']}')
                          : AppStrings.t('finReconciledStatus', isAr);

                      final kpi2 = _buildKpiCard(
                        context,
                        s('finTotalCash'),
                        '\$${finalTotalCash.toStringAsFixed(2)}',
                        Icons.payments,
                        reconciliationSub,
                        isPositive: null,
                        actionText: s('finReconcileNow'),
                        onActionTap: () => _showReconciliationDialog(context, isAr, finalTotalCash),
                        secondaryActionText: AppStrings.t('finReconcileHistoryBtn', isAr),
                        onSecondaryActionTap: () => _showReconciliationHistoryDialog(context, isAr),
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
                                            child: Text(
                                              isAr ? 'كل الأوقات' : 'All Time',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Today',
                                            child: Text(
                                              isAr ? 'اليوم' : 'Today',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'This Week',
                                            child: Text(
                                              isAr
                                                  ? 'هذا الأسبوع'
                                                  : 'This Week',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'This Month',
                                            child: Text(
                                              isAr ? 'هذا الشهر' : 'This Month',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Custom',
                                            child: Text(
                                              isAr ? 'تخصيص...' : 'Custom...',
                                            ),
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
                                final matchesSearch =
                                    (t['customerName']
                                            ?.toString()
                                            .toLowerCase()
                                            .contains(_searchQuery) ??
                                        false) ||
                                    (t['type']
                                            ?.toString()
                                            .toLowerCase()
                                            .contains(_searchQuery) ??
                                        false);
                                final matchesType = _matchesFilterType(t);

                                bool matchesDate = true;
                                if (_startDate != null && _endDate != null) {
                                  final dt = DateTime.parse(
                                    t['date'],
                                  ).toLocal();
                                  matchesDate =
                                      dt.compareTo(_startDate!) >= 0 &&
                                      dt.compareTo(_endDate!) <= 0;
                                }

                                return matchesSearch &&
                                    matchesType &&
                                    matchesDate;
                              }).toList();

                              if (_sortColumnIndex != null) {
                                filtered.sort((a, b) {
                                  if (_sortColumnIndex == 0) {
                                    final aDate =
                                        DateTime.tryParse(a['date'] ?? '') ??
                                        DateTime(1970);
                                    final bDate =
                                        DateTime.tryParse(b['date'] ?? '') ??
                                        DateTime(1970);
                                    return _sortAscending
                                        ? aDate.compareTo(bDate)
                                        : bDate.compareTo(aDate);
                                  } else if (_sortColumnIndex == 2) {
                                    final aMethod =
                                        a['method']?.toString() ?? '';
                                    final bMethod =
                                        b['method']?.toString() ?? '';
                                    return _sortAscending
                                        ? aMethod.compareTo(bMethod)
                                        : bMethod.compareTo(aMethod);
                                  } else if (_sortColumnIndex == 4) {
                                    final aAmt =
                                        double.tryParse('${a['amount']}') ??
                                        0.0;
                                    final bAmt =
                                        double.tryParse('${b['amount']}') ??
                                        0.0;
                                    return _sortAscending
                                        ? aAmt.compareTo(bAmt)
                                        : bAmt.compareTo(aAmt);
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
                              final isMobile =
                                  MediaQuery.of(context).size.width <= 800;
                              if (isMobile) {
                                return _buildMobileTransactionsList(
                                  filtered,
                                  isAr,
                                  context,
                                );
                              }

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        showCheckboxColumn: false,
                                        sortColumnIndex: _sortColumnIndex,
                                        sortAscending: _sortAscending,
                                        columnSpacing: 16,

                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              Theme.of(context).cardColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                        dataRowColor:
                                            WidgetStateProperty.resolveWith((
                                              states,
                                            ) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.05);
                                              }
                                              return null; // default
                                            }),
                                        dividerThickness: 0.5,
                                        columns: [
                                          DataColumn(
                                            onSort: _sort,
                                            label: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  AppStrings.t(
                                                    'financeDate',
                                                    isAr,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                if (_sortColumnIndex != 0)
                                                  const Icon(
                                                    Icons.unfold_more,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppStrings.t('financeDesc', isAr),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            onSort: _sort,
                                            label: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  AppStrings.t(
                                                    'finMethod',
                                                    isAr,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                if (_sortColumnIndex != 2)
                                                  const Icon(
                                                    Icons.unfold_more,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppStrings.t('subStatus', isAr),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            onSort: _sort,
                                            label: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  AppStrings.t(
                                                    'financeAmount',
                                                    isAr,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                if (_sortColumnIndex != 4)
                                                  const Icon(
                                                    Icons.unfold_more,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                              ],
                                            ),

                                            numeric: true,
                                          ),
                                        ],
                                        rows: filtered.map((t) {
                                          final dt = DateTime.parse(
                                            t['date'],
                                          ).toLocal();
                                          final isBooking =
                                              t['type'] == 'Booking';
                                          final amount =
                                              double.tryParse(
                                                '${t['amount']}',
                                              ) ??
                                              0.0;
                                          String paymentMethodStr =
                                              t['method']?.toString() ??
                                              (isBooking ? 'Cash' : 'Card');
                                          final isTransfer =
                                              paymentMethodStr.toLowerCase() ==
                                              'transfer';
                                          final pIcon = isTransfer
                                              ? Icons.swap_horiz
                                              : (paymentMethodStr
                                                            .toLowerCase() ==
                                                        'card'
                                                    ? Icons.credit_card
                                                    : Icons.payments);

                                          if (isAr) {
                                            if (paymentMethodStr
                                                    .toLowerCase() ==
                                                'cash')
                                              paymentMethodStr = 'كاش (نقدي)';
                                            else if (paymentMethodStr
                                                    .toLowerCase() ==
                                                'card')
                                              paymentMethodStr = 'بطاقة بنكية';
                                            else if (paymentMethodStr
                                                    .toLowerCase() ==
                                                'transfer')
                                              paymentMethodStr = 'تحويل بنكي';
                                          }

                                          return DataRow(
                                            onSelectChanged: (selected) {
                                              if (selected == true) {
                                                _showTransactionDetails(
                                                  context,
                                                  t,
                                                  isAr,
                                                  pIcon,
                                                  paymentMethodStr,
                                                  isBooking
                                                      ? (isAr
                                                            ? 'حجز'
                                                            : 'Booking')
                                                      : (isAr
                                                            ? 'اشتراك'
                                                            : 'Subscription'),
                                                  amount,
                                                  dt,
                                                );
                                              }
                                            },
                                            cells: [
                                              DataCell(
                                                Text(
                                                  '${dt.day}/${dt.month}/${dt.year}',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  isBooking
                                                      ? '${AppStrings.t('dashBookingLabel', isAr)} - ${t['customerName'] ?? AppStrings.t('walkInCustomer', isAr)} ${t['status'] == 'Cancelled' ? (isAr ? '(مبلغ مخصوم)' : '(Deducted)') : ''}'
                                                      : '${AppStrings.t('finSubscriptions', isAr)} - ${t['customerName'] ?? AppStrings.t('walkInCustomer', isAr)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        t['status'] ==
                                                            'Cancelled'
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.error
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    Icon(
                                                      pIcon,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      paymentMethodStr,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    AppStrings.t(
                                                      'completed',
                                                      isAr,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '+\$${amount.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'JetBrains Mono',
                                                    color:
                                                        t['status'] ==
                                                            'Cancelled'
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.error
                                                        : Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ), // Close DataTable
                                    ), // Close ConstrainedBox
                                  ); // Close SingleChildScrollView
                                }, // Close builder
                              ); // Close LayoutBuilder
                            }, // Close data
                          ), // Close transactionsAsync.when
                        ), // Close SizedBox
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
    VoidCallback? onActionTap,
    String? secondaryActionText,
    VoidCallback? onSecondaryActionTap,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (secondaryActionText != null) ...[
                              InkWell(
                                onTap: onSecondaryActionTap,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        secondaryActionText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (actionText != null)
                              InkWell(
                                onTap: onActionTap,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.task_alt,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        actionText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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

  void _showReconciliationDialog(
    BuildContext context,
    bool isAr,
    double totalCash,
  ) {
    final notesController = TextEditingController();
    final filterPeriod = _getCurrentFilterPeriodLabel(isAr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.t('finReconcileDialogTitle', isAr),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.t('finTotalCash', isAr),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${totalCash.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${AppStrings.t('finReconciledPeriod', isAr)}: ',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: Text(
                            filterPeriod,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: AppStrings.t('finReconcileNotesHint', isAr),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                ),
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
            onPressed: () async {
              final note = notesController.text.trim();
              await _addReconciliationRecord(
                amount: totalCash,
                period: filterPeriod,
                note: note,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                AppSnackBar.showSuccessDialog(
                  context,
                  title: AppStrings.t('finReconcileSuccessTitle', isAr),
                  message: AppStrings.t('finReconcileSuccessMsg', isAr),
                  confirmLabel: AppStrings.t('ok', isAr),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: Text(AppStrings.t('finConfirmReconcile', isAr)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showReconciliationHistoryDialog(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.t('finReconcileLedgerTitle', isAr),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: _reconciliationLedger.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.t('finNoReconciliationsYet', isAr),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 380,
                  child: ListView.separated(
                    itemCount: _reconciliationLedger.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _reconciliationLedger[index];
                      final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified, size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Text(
                                      '\$${amt.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['date']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.filter_alt_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppStrings.t('finReconciledPeriod', isAr)}: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item['period']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (item['note'] != null && item['note'].toString() != '—') ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item['note'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('done', isAr)),
          ),
        ],
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
        _startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'This Month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
    });
  }

  Future<void> _printReport(
    List<dynamic> allTx,
    String title,
    bool isAr,
  ) async {
    final filteredTx = allTx.where((t) {
      final matchesSearch =
          (t['customerName']?.toString().toLowerCase().contains(_searchQuery) ??
              false) ||
          (t['type']?.toString().toLowerCase().contains(_searchQuery) ?? false);
      final matchesType = _matchesFilterType(t);

      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        final dt = DateTime.parse(t['date']).toLocal();
        matchesDate = dt.isAfter(_startDate!) && dt.isBefore(_endDate!);
      }
      return matchesSearch && matchesType && matchesDate;
    }).toList();

    double totalRev = 0;
    double totalCash = 0;
    for (var tx in filteredTx) {
      final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      totalRev += amt;
      if (tx['method'] == 'Cash') {
        totalCash += amt;
      }
    }

    await PrintService.printFinanceReport(
      isAr: isAr,
      title: title,
      summary: {'totalRevenue': totalRev, 'totalCash': totalCash},
      transactions: filteredTx,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Widget _buildMobileTransactionsList(
    List<dynamic> transactions,
    bool isAr,
    BuildContext context,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = transactions[index];
        final dt = DateTime.parse(t['date']).toLocal();
        final isBooking = t['type'] == 'Booking';
        final amount = double.tryParse('${t['amount']}') ?? 0.0;
        String paymentMethodStr =
            t['method']?.toString() ?? (isBooking ? 'Cash' : 'Card');
        final isTransfer = paymentMethodStr.toLowerCase() == 'transfer';
        final pIcon = isTransfer
            ? Icons.swap_horiz
            : (paymentMethodStr.toLowerCase() == 'card'
                  ? Icons.credit_card
                  : Icons.payments);

        if (isAr) {
          if (paymentMethodStr.toLowerCase() == 'cash')
            paymentMethodStr = 'كاش (نقدي)';
          else if (paymentMethodStr.toLowerCase() == 'transfer')
            paymentMethodStr = 'تحويل بنكي';
        }
        //${AppStrings.t('dashBookingLabel', isAr)} -
        //${AppStrings.t('finSubscriptions', isAr)} -
        final title = isBooking
            ? ' ${t['customerName'] ?? AppStrings.t('walkInCustomer', isAr)}'
            : ' ${t['customerName'] ?? AppStrings.t('walkInCustomer', isAr)}';

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTransactionDetails(
              context,
              t,
              isAr,
              pIcon,
              paymentMethodStr,
              title,
              amount,
              dt,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      pIcon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (t['status'] == 'Cancelled')
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              isAr ? 'مبلغ مخصوم' : 'Deducted Amount',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: t['status'] == 'Cancelled'
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    dynamic t,
    bool isAr,
    IconData pIcon,
    String paymentMethodStr,
    String title,
    double amount,
    DateTime dt,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        pIcon,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? (t['description'] ?? '')
                                      .toString()
                                      .replaceAll('Booking', 'حجز')
                                      .replaceAll(
                                        'Membership Plan',
                                        'خطة اشتراك',
                                      )
                                      .replaceAll('Subscription:', 'اشتراك:')
                                      .replaceAll('Monthly', 'شهري')
                                      .replaceAll('Yearly', 'سنوي')
                                      .replaceAll('Weekly', 'أسبوعي')
                                      .replaceAll('Daily', 'يومي')
                                      .replaceAll('Plan', 'خطة')
                                : (t['description'] ?? ''),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (t['fingerprintId'] != null &&
                              t['fingerprintId'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${isAr ? 'رقم المشترك' : 'Subscriber ID'}: ${t['fingerprintId']}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Details
                _buildDetailRow(
                  context,
                  AppStrings.t('financeDate', isAr),
                  '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                ),
                const Divider(),
                _buildDetailRow(
                  context,
                  AppStrings.t('finMethod', isAr),
                  paymentMethodStr,
                ),
                const Divider(),
                _buildDetailRow(
                  context,
                  AppStrings.t('subStatus', isAr),
                  t['status'] == 'Cancelled'
                      ? (isAr ? 'مبلغ مخصوم (ملغي)' : 'Deducted (Cancelled)')
                      : AppStrings.t('completed', isAr),
                ),
                const Divider(),
                _buildDetailRow(
                  context,
                  AppStrings.t('financeAmount', isAr),
                  '\$${amount.toStringAsFixed(2)}',
                  isAmount: true,
                ),

                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Print action
                          _printReport([t], title, isAr);
                        },
                        icon: const Icon(Icons.print),
                        label: Text(AppStrings.t('printReceipt', isAr)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isAmount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isAmount ? 20 : 16,
              color: isAmount ? Theme.of(context).colorScheme.primary : null,
              fontFamily: isAmount ? 'JetBrains Mono' : null,
            ),
          ),
        ],
      ),
    );
  }
}
