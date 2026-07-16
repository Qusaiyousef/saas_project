import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tenant_type.dart';
import '../providers/auth_provider.dart';
import '../providers/pos_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _chartTimeframe = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tenantType = authState.tenantType ?? TenantType.pool;
    final isAr = ref.watch(isArabicProvider);
    final s = (String key) => AppStrings.t(key, isAr);

    final bookingsAsync = ref.watch(bookingsProvider);
    final subsAsync =
        (tenantType == TenantType.gym || tenantType == TenantType.pool)
        ? ref.watch(subscriptionProvider)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by ShellScreen
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (bookings) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final List<Map<String, dynamic>> todayBookings = bookings
              .where((b) {
                final dt = DateTime.parse(b['startTime']).toLocal();
                return dt.year == today.year &&
                    dt.month == today.month &&
                    dt.day == today.day;
              })
              .cast<Map<String, dynamic>>()
              .toList();

          final todayCount = todayBookings.length;
          final totalRev = bookings.fold<double>(
            0,
            (sum, b) => sum + ((b['totalAmount'] as num?)?.toDouble() ?? 0),
          );

          // Calculate Occupancy (Percentage of days booked this month)
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final bookedDaysThisMonth = bookings.where((b) {
            final dt = DateTime.parse(b['startTime']).toLocal();
            return dt.year == now.year && dt.month == now.month;
          }).map((b) => DateTime.parse(b['startTime']).toLocal().day).toSet().length;
          final occupancyRate = ((bookedDaysThisMonth / daysInMonth) * 100).toStringAsFixed(0) + '%';

          // Calculate Dynamic Revenue based on _chartTimeframe
          List<double> chartData = [];
          List<String> chartLabels = [];
          
          if (_chartTimeframe == 'Weekly') {
            chartData = List.filled(7, 0.0);
            chartLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final int daysSinceMonday = now.weekday - 1;
            final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceMonday));
            
            for (final b in bookings) {
              final dt = DateTime.parse(b['startTime']).toLocal();
              if (!dt.isBefore(startOfWeek) && dt.isBefore(startOfWeek.add(const Duration(days: 7)))) {
                final dayIndex = dt.weekday - 1;
                chartData[dayIndex] += ((b['totalAmount'] as num?)?.toDouble() ?? 0.0);
              }
            }
          } else if (_chartTimeframe == 'Monthly') {
            chartData = List.filled(4, 0.0);
            chartLabels = const ['W1', 'W2', 'W3', 'W4'];
            final startOfMonth = DateTime(now.year, now.month, 1);
            final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            
            for (final b in bookings) {
              final dt = DateTime.parse(b['startTime']).toLocal();
              if (!dt.isBefore(startOfMonth) && !dt.isAfter(endOfMonth)) {
                int weekIndex = (dt.day - 1) ~/ 7;
                if (weekIndex > 3) weekIndex = 3;
                chartData[weekIndex] += ((b['totalAmount'] as num?)?.toDouble() ?? 0.0);
              }
            }
          } else if (_chartTimeframe == 'Yearly') {
            chartData = List.filled(12, 0.0);
            chartLabels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            
            for (final b in bookings) {
              final dt = DateTime.parse(b['startTime']).toLocal();
              if (dt.year == now.year) {
                final monthIndex = dt.month - 1;
                chartData[monthIndex] += ((b['totalAmount'] as num?)?.toDouble() ?? 0.0);
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.t('dashWelcome', isAr)}${authState.role ?? "Admin"}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.t('dashSubtitle', isAr),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 1024;
                      final isTablet = constraints.maxWidth > 600 && !isDesktop;

                      return Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: KPIs and Chart
                          Expanded(
                            flex: isDesktop ? 2 : 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bento Grid
                                GridView.count(
                                  crossAxisCount: isDesktop || isTablet ? 2 : 1,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      2.2, // Adjust depending on card design
                                  children: [
                                    _buildKpiCard(
                                      context,
                                      AppStrings.t('dashTotalRevenue', isAr),
                                      '\$${totalRev.toStringAsFixed(0)}',
                                      Icons.payments,
                                      '+12%',
                                      true,
                                    ),
                                    if (subsAsync != null)
                                      subsAsync.when(
                                        data: (subs) => _buildKpiCard(
                                          context,
                                          AppStrings.t('dashActiveSubs', isAr),
                                          '${subs.length}',
                                          Icons.card_membership,
                                          null,
                                          false,
                                        ),
                                        loading: () => _buildKpiCard(
                                          context,
                                          AppStrings.t('dashActiveSubs', isAr),
                                          '...',
                                          Icons.card_membership,
                                          null,
                                          false,
                                        ),
                                        error: (_, __) => _buildKpiCard(
                                          context,
                                          AppStrings.t('dashActiveSubs', isAr),
                                          '0',
                                          Icons.card_membership,
                                          null,
                                          false,
                                        ),
                                      )
                                    else
                                      _buildKpiCard(
                                        context,
                                        AppStrings.t('dashResources', isAr),
                                        '1',
                                        Icons.business,
                                        null,
                                        false,
                                      ),
                                    _buildKpiCard(
                                      context,
                                      AppStrings.t('dashTodayBookings', isAr),
                                      '$todayCount',
                                      Icons.event_available,
                                      null,
                                      false,
                                    ),
                                    _buildKpiCard(
                                      context,
                                      AppStrings.t('dashOccupancy', isAr),
                                      occupancyRate,
                                      Icons.pie_chart,
                                      AppStrings.t('dashHighDemand', isAr),
                                      false,
                                      isWarning: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Sparkline Chart
                                _buildChartCard(context, isAr, chartData, chartLabels),
                              ],
                            ),
                          ),

                          if (isDesktop) const SizedBox(width: 24),
                          if (!isDesktop) const SizedBox(height: 24),

                          // Right Column: Recent Activity
                          Expanded(
                            flex: isDesktop ? 1 : 0,
                            child: _buildRecentActivity(
                              context,
                              todayBookings,
                              isAr,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    String? badge,
    bool primaryBadge, {
    bool isWarning = false,
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
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          icon,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrains Mono',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isWarning
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.15)
                                  : (primaryBadge
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.15)
                                        : Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (primaryBadge)
                                  Icon(
                                    Icons.trending_up,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                if (primaryBadge) const SizedBox(width: 4),
                                Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isWarning
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: -10,
                  bottom: -10,
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(
                      icon,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, bool isAr, List<double> chartData, List<String> chartLabels) {
    final maxRev = chartData.isEmpty ? 0.0 : chartData.reduce(math.max);
    final interval = maxRev > 0 ? (maxRev / 4).ceilToDouble() : 2500.0;
    final validInterval = interval == 0 ? 2500.0 : interval;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.t('dashWeeklyTrend', isAr),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _chartTimeframe,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                      items: ['Weekly', 'Monthly', 'Yearly'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            isAr ? (value == 'Weekly' ? 'أسبوعي' : value == 'Monthly' ? 'شهري' : 'سنوي') : value,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _chartTimeframe = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: validInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: validInterval,
                            getTitlesWidget: (val, meta) => Text(
                              '\$${(val / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (val, meta) {
                              if (val >= 0 && val < chartLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    chartLabels[val.toInt()],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (index) => FlSpot(index.toDouble(), chartData[index]),
                          ),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2,
                                  strokeColor: Theme.of(context).colorScheme.surface,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    List<Map<String, dynamic>> todayBookings,
    bool isAr,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t('dashRecentActivity', isAr),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  
                  ],
                ),
              ),
              const Divider(height: 1),
              if (todayBookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      AppStrings.t('dashNoActivity', isAr),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...todayBookings
                    .take(6)
                    .map((b) => _buildActivityItem(context, b, isAr)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> booking,
    bool isAr,
  ) {
    final title = booking['customerName'] ?? 'Walk-in';
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.pool,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.t('dashBookingLabel', isAr)} $title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t('dashStatusConfirmed', isAr),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppStrings.t('dashJustNow', isAr),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}
