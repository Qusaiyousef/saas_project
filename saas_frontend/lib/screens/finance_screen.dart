import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/finance_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _filterType = 'All'; // All, Bookings, Subscriptions
  String _searchQuery = '';

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
                  child: Column(
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
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final kpi1 = _buildKpiCard(
                        context,
                        s('finCurrentBalance'),
                        '\$${summary['totalRevenue']}',
                        Icons.account_balance,
                        s('finLastMonth'),
                        isPositive: true,
                      );
                      final kpi2 = _buildKpiCard(
                        context,
                        s('finTotalCash'),
                        '\$${summary['totalCash'] ?? 0.0}',
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
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Table
                        SizedBox(
                          height: 500,
                          child: transactionsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                Center(child: Text('${s('error')}: $e')),
                            data: (transactions) {
                              final filtered = transactions.where((t) {
                                final matchSearch = (t['customerName'] ?? '')
                                    .toLowerCase()
                                    .contains(_searchQuery);
                                final matchFilter =
                                    _filterType == 'All' ||
                                    (_filterType == 'Bookings' &&
                                        t['type'] == 'Booking') ||
                                    (_filterType == 'Subscriptions' &&
                                        t['type'] == 'Subscription');
                                return matchSearch && matchFilter;
                              }).toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 64,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        AppStrings.t('finNoTrans', isAr),
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
                                    label: Text(
                                      AppStrings.t('financeDate', isAr),
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
                                    label: Text(
                                      AppStrings.t('finMethod', isAr),
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
                                  DataColumn2(
                                    label: Text(
                                      AppStrings.t('financeAmount', isAr),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
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
                                              isBooking
                                                  ? Icons.payments
                                                  : Icons.credit_card,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isBooking ? 'Cash' : 'Card',
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
}
