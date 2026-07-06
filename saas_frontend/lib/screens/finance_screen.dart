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
    final summaryAsync = ref.watch(financeSummaryProvider);
    final transactionsAsync = ref.watch(financeTransactionsProvider);
    final isAr = ref.watch(isArabicProvider);
    final s = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      appBar: AppBar(title: Text(s('financeTitle')), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── KPI Summary ──
            summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  '${s('error')}: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (summary) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpiCard(
                      context,
                      s('financeTotalRev'),
                      '\$${summary['totalRevenue']}',
                      Icons.account_balance,
                      Colors.green,
                    ),
                    _kpiCard(
                      context,
                      s('financeBookRev'),
                      '\$${summary['bookingsRevenue']}',
                      Icons.book_online,
                      Colors.blue,
                    ),
                    _kpiCard(
                      context,
                      s('financeSubRev'),
                      '\$${summary['subscriptionsRevenue']}',
                      Icons.card_membership,
                      Colors.purple,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Transactions Table ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header & Filters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s('financeTrans'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: s('financeCustomer'),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (val) => setState(
                                () => _searchQuery = val.toLowerCase(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _filterType,
                            items: [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text(s('financeFilterAll')),
                              ),
                              DropdownMenuItem(
                                value: 'Bookings',
                                child: Text(s('financeFilterBook')),
                              ),
                              DropdownMenuItem(
                                value: 'Subscriptions',
                                child: Text(s('financeFilterSub')),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _filterType = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Table
                  SizedBox(
                    height: 500,
                    child: transactionsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('${s('error')}: $e')),
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
                                const Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  s('financeNoTrans'),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 600,
                          columns: [
                            DataColumn2(
                              label: Text(s('financeDate')),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text(s('financeCustomer')),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text(s('financeType')),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text(s('financeDesc')),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text(s('financeAmount')),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                          ],
                          rows: filtered.map((t) {
                            final dt = DateTime.parse(t['date']).toLocal();
                            final isBooking = t['type'] == 'Booking';
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    t['customerName'] ?? 'Walk-in',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    avatar: Icon(
                                      isBooking
                                          ? Icons.book_online
                                          : Icons.card_membership,
                                      size: 16,
                                      color: isBooking
                                          ? Colors.blue
                                          : Colors.purple,
                                    ),
                                    label: Text(
                                      isBooking ? 'Booking' : 'Subscription',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: isBooking
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.purple.withOpacity(0.1),
                                  ),
                                ),
                                DataCell(Text(t['description'] ?? '')),
                                DataCell(
                                  Text(
                                    '+\$${t['amount']}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
