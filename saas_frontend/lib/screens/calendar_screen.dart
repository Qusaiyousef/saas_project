import 'package:flutter/material.dart';
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
  DateTime _focusedDay  = DateTime.now();
  DateTime? _selectedDay;

  List<dynamic> _getEventsForDay(DateTime day, List<dynamic> bookings) {
    return bookings.where((b) {
      try {
        final start = DateTime.parse(b['startTime']).toLocal();
        return start.year == day.year &&
               start.month == day.month &&
               start.day == day.day;
      } catch (_) { return false; }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final isAr = ref.watch(isArabicProvider);
    final s    = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('calTitle')),
        elevation: 2,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading bookings: $err')),
        data: (bookings) {
          final selectedEvents = _getEventsForDay(
              _selectedDay ?? _focusedDay, bookings);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay  = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                eventLoader: (day) => _getEventsForDay(day, bookings),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _selectedDay != null
                          ? '${s('calBookingsOn')} ${_selectedDay!.toLocal().toString().split(' ')[0]}'
                          : s('calSelectDay'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${selectedEvents.length} ${s('calBookings')}'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_available, size: 64, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(s('calNoBookings'), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final booking  = selectedEvents[index];
                          final startTime = DateTime.parse(booking['startTime']).toLocal();
                          final endTime   = DateTime.parse(booking['endTime']).toLocal();
                          final isFullDay = booking['isFullDayBlock'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isFullDay
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                child: Icon(
                                  isFullDay ? Icons.block : Icons.pool,
                                  color: isFullDay ? Colors.red : Colors.blue,
                                ),
                              ),
                              title: Text(
                                booking['customerName'] ?? 'Walk-in',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                isFullDay
                                    ? s('calFullDayBlock')
                                    : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} → ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: Chip(
                                label: Text(isFullDay ? s('calFullDay') : s('calHourly')),
                                backgroundColor: isFullDay
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
