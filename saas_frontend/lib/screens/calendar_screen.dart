import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/pos_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<dynamic> _getEventsForDay(DateTime day, List<dynamic> bookings) {
    return bookings.where((b) {
      try {
        final start = DateTime.parse(b['startTime']).toLocal();
        return start.year == day.year &&
            start.month == day.month &&
            start.day == day.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final isAr = ref.watch(isArabicProvider);
    final s = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from shell
      appBar: MediaQuery.of(context).size.width < 1024
          ? AppBar(
              title: Text(s('calTitle')),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error loading bookings: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (bookings) {
          final selectedEvents = _getEventsForDay(
            _selectedDay ?? _focusedDay,
            bookings,
          );

          return SingleChildScrollView(
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
                            s('calTitle'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                             s('calSubtitle'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 900;

                      final calendarWidget = Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.6),
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
                            filter: dart_ui.ImageFilter.blur(
                              sigmaX: 8,
                              sigmaY: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                                onFormatChanged: (format) {
                                  setState(() => _calendarFormat = format);
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() => _focusedDay = focusedDay);
                                },
                                eventLoader: (day) =>
                                    _getEventsForDay(day, bookings),
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: true,
                                  titleCentered: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      final eventsListWidget = Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.6),
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
                            filter: dart_ui.ImageFilter.blur(
                              sigmaX: 8,
                              sigmaY: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDay != null
                                              ? '${s('calBookingsOn')} ${_selectedDay!.toLocal().toString().split(' ')[0]}'
                                              : s('calSelectDay'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          '${selectedEvents.length} ${s('calBookings')}',
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary.withValues(alpha: 0.1),
                                        labelStyle: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                if (selectedEvents.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(48.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 64,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            s('calNoBookings'),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: selectedEvents.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final booking = selectedEvents[index];
                                      final startTime = DateTime.parse(
                                        booking['startTime'],
                                      ).toLocal();
                                      final endTime = DateTime.parse(
                                        booking['endTime'],
                                      ).toLocal();
                                      final isFullDay =
                                          booking['isFullDayBlock'] == true;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor
                                              .withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                          leading: CircleAvatar(
                                            backgroundColor: isFullDay
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .error
                                                      .withValues(alpha: 0.1)
                                                : Theme.of(context).colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                            child: Icon(
                                              isFullDay
                                                  ? Icons.block
                                                  : Icons.pool,
                                              color: isFullDay
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                            ),
                                          ),
                                          title: Text(
                                            booking['customerName'] ??
                                                'Walk-in',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              isFullDay
                                                  ? s('calFullDayBlock')
                                                  : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} → ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontFamily: isFullDay
                                                    ? null
                                                    : 'JetBrains Mono',
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isFullDay
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .error
                                                        .withValues(alpha: 0.1)
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isFullDay
                                                  ? s('calFullDay')
                                                  : s('calHourly'),
                                              style: TextStyle(
                                                color: isFullDay
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
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: calendarWidget),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: eventsListWidget),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calendarWidget,
                            const SizedBox(height: 24),
                            eventsListWidget,
                          ],
                        );
                      }
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
}
