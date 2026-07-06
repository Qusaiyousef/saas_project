import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tenant_type.dart';
import '../providers/auth_provider.dart';
import '../providers/pos_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final tenantType = authState.tenantType ?? TenantType.pool;
    final hasSubscriptions = tenantType == TenantType.gym || tenantType == TenantType.pool;
    final isAr = ref.watch(isArabicProvider);
    final s    = (String key) => AppStrings.t(key, isAr);

    final bookingsAsync = ref.watch(bookingsProvider);
    final subsAsync = hasSubscriptions ? ref.watch(subscriptionProvider) : null;
    final resourceAsync = ref.watch(defaultResourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('dashTitle')),
        elevation: 2,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading bookings: $err')),
        data: (bookings) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Booking stats
          final todayBookings = bookings.where((b) {
            final dt = DateTime.parse(b['startTime']).toLocal();
            return dt.year == today.year && dt.month == today.month && dt.day == today.day;
          }).toList();
          final totalBookings = bookings.length;
          final todayCount = todayBookings.length;
          final fullDayCount = bookings.where((b) => b['isFullDayBlock'] == true).length;

          // Weekly bar data (last 7 days)
          final weeklyData = List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            return bookings.where((b) {
              final dt = DateTime.parse(b['startTime']).toLocal();
              return dt.year == day.year && dt.month == day.month && dt.day == day.day;
            }).length.toDouble();
          });
          final dayLabels = List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            final d = isAr
                ? ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
                : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return d[day.weekday - 1];
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── KPI Row ──
                resourceAsync.when(
                  data: (resource) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _kpiCard(context, s('dashTotalBookings'), '$totalBookings', Icons.book_online, Colors.blue),
                        _kpiCard(context, s('dashTodayBookings'), '$todayCount', Icons.today, Colors.teal),
                        _kpiCard(context, isAr ? 'حجوزات يوم كامل' : 'Full Day Blocks', '$fullDayCount', Icons.block, Colors.orange),
                        if (hasSubscriptions)
                          _subsKpiCard(context, subsAsync!, s),
                        _kpiCard(context, isAr ? 'المورد' : 'Resource', resource?['name'] ?? 'N/A', Icons.business, Colors.purple),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 28),

                // ── Charts Row ──
                LayoutBuilder(builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bar Chart - weekly bookings
                      Expanded(
                        flex: isDesktop ? 2 : 0,
                        child: _chartCard(
                          context,
                          isAr ? 'الحجوزات — آخر 7 أيام' : 'Bookings — Last 7 Days',
                          SizedBox(
                            height: 260,
                            child: totalBookings == 0
                                ? Center(child: Text(isAr ? 'لا توجد بيانات بعد' : 'No booking data yet', style: const TextStyle(color: Colors.grey)))
                                : BarChart(BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barGroups: List.generate(7, (i) => BarChartGroupData(
                                      x: i,
                                      barRods: [BarChartRodData(
                                        toY: weeklyData[i],
                                        color: Colors.blue,
                                        width: 18,
                                        borderRadius: BorderRadius.circular(4),
                                      )],
                                    )),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (val, _) => Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(dayLabels[val.toInt()], style: const TextStyle(fontSize: 11)),
                                          ),
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: const FlGridData(show: false),
                                  )),
                          ),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 24),
                      // Pie Chart - booking types
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: _chartCard(
                          context,
                          isAr ? 'أنواع الحجوزات' : 'Booking Types',
                          SizedBox(
                            height: 260,
                            child: totalBookings == 0
                                ? Center(child: Text(isAr ? 'لا توجد بيانات بعد' : 'No data yet', style: const TextStyle(color: Colors.grey)))
                                : PieChart(PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        color: Colors.blue,
                                        value: (totalBookings - fullDayCount).toDouble().clamp(0, double.infinity),
                                      title: '${isAr ? 'بالساعة' : 'Hourly'}\n${totalBookings - fullDayCount}',
                                        radius: 65,
                                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      if (fullDayCount > 0)
                                        PieChartSectionData(
                                          color: Colors.orange,
                                          value: fullDayCount.toDouble(),
                                          title: '${isAr ? 'يوم كامل' : 'Full Day'}\n$fullDayCount',
                                          radius: 65,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                    ],
                                    centerSpaceRadius: 28,
                                  )),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 24),

                // ── Subscriptions Section (Gym & Pool only) ──
                if (hasSubscriptions)
                  subsAsync!.when(
                    loading: () => _chartCard(context, s('dashActiveSubs'),
                        const Center(child: CircularProgressIndicator())),
                    error: (e, _) => _chartCard(context, s('dashActiveSubs'),
                        Text('Error: $e', style: const TextStyle(color: Colors.red))),
                    data: (subs) => _chartCard(
                      context,
                      '${s('dashActiveSubs')} (${subs.length})',
                      subs.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(child: Text(s('dashNoBookings'), style: const TextStyle(color: Colors.grey))),
                            )
                          : Column(
                              children: subs.take(6).map((sub) {
                                final endDate = DateTime.parse(sub['endDate']);
                                final daysLeft = endDate.difference(DateTime.now()).inDays;
                                final isExpired = daysLeft < 0;
                                final isWarning = !isExpired && daysLeft <= 7;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: (isExpired ? Colors.red : Colors.green).withOpacity(0.1),
                                    child: Text(
                                      (sub['customerName'] as String? ?? 'U')[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isExpired ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(sub['customerName'] ?? 'Unknown'),
                                  subtitle: Text(
                                    '${isAr ? 'ينتهي:' : 'Expires:'} ${endDate.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: isExpired ? Colors.red : isWarning ? Colors.orange : Colors.grey,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isExpired ? Colors.red : isWarning ? Colors.orange : Colors.green).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isExpired
                                          ? s('subExpired')
                                          : isWarning
                                              ? '$daysLeft ${isAr ? 'يوم متبقي' : 'days left'}'
                                              : s('subActive'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isExpired ? Colors.red : isWarning ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Recent Bookings Table ──
                _chartCard(
                  context,
                  s('dashRecentBookings'),
                  bookings.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text(s('dashNoBookings'), style: const TextStyle(color: Colors.grey))),
                        )
                      : Column(
                          children: bookings.reversed.take(5).map((b) {
                            final dt = DateTime.parse(b['startTime']).toLocal();
                            final isFullDay = b['isFullDayBlock'] == true;
                            return ListTile(
                              leading: Icon(
                                isFullDay ? Icons.calendar_month : Icons.timer,
                                color: isFullDay ? Colors.orange : Colors.blue,
                              ),
                              title: Text(b['customerName'] ?? 'Walk-in'),
                              subtitle: Text('${dt.day}/${dt.month}/${dt.year}  '
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
                              trailing: Chip(
                                label: Text(isFullDay ? s('dashFullDay') : s('dashHourly')),
                                backgroundColor:
                                    isFullDay ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // KPI card for subscriptions — reads its own async state internally
  Widget _subsKpiCard(BuildContext context, AsyncValue<List<dynamic>> subsAsync, String Function(String) s) {
    return subsAsync.when(
      loading: () => _kpiCard(context, s('dashActiveSubs'), '...', Icons.card_membership, Colors.green),
      error: (_, __) => _kpiCard(context, s('dashActiveSubs'), 'Err', Icons.card_membership, Colors.red),
      data: (subs) {
        final activeCount = subs.where((sub) {
          final endDate = DateTime.parse(sub['endDate']);
          return endDate.isAfter(DateTime.now());
        }).length;
        return _kpiCard(context, s('dashActiveSubs'), '$activeCount', Icons.card_membership, Colors.green);
      },
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
