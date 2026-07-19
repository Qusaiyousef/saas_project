import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

/// Fetches the default resource for the current tenant
final defaultResourceProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/resources/default');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
});

/// Fetches bookings for the current month + next 2 months for the calendar and POS
class BookingsNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    final resource = await ref.watch(defaultResourceProvider.future);
    if (resource == null) return [];

    final resourceId = resource['id'] as String;
    final dio = ref.watch(dioProvider);
    final fromDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final toDate = DateTime.now().add(const Duration(days: 60)).toIso8601String();

    final response = await dio.get('/bookings/resource/$resourceId?from=$fromDate&to=$toDate');
    return response.data as List<dynamic>;
  }

  Future<void> addBooking({
    required String customerName,
    String? customerId,
    required DateTime startTime,
    required int durationHours,
    required bool isFullDay,
    required double totalAmount,
    required double amountPaid,
    required String paymentMethod,
  }) async {
    final resource = await ref.read(defaultResourceProvider.future);
    if (resource == null) throw Exception('No resource found for this tenant.');

    final resourceId = resource['id'] as String;
    final dio = ref.read(dioProvider);

    final endTime = isFullDay
        ? DateTime(startTime.year, startTime.month, startTime.day, 23, 59)
        : startTime.add(Duration(hours: durationHours));

    try {
      await dio.post('/bookings', data: {
        'resourceId': resourceId,
        'customerName': customerName,
        'customerId': customerId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isFullDayBlock': isFullDay,
        'status': 0,
        'totalAmount': totalAmount,
        'amountPaid': amountPaid,
        'paymentMethod': paymentMethod,
      });
      ref.invalidateSelf();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to create booking';
      throw Exception(msg);
    }
  }

  Future<void> cancelBooking(String id, double feePercentage) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/bookings/$id/cancel?feePercentage=$feePercentage');
      ref.invalidateSelf();
    } on DioException catch (e) {
      String msg = 'Failed to cancel booking';
      if (e.response?.data is Map<String, dynamic>) {
        msg = e.response?.data['message'] ?? msg;
      } else if (e.response?.data is String) {
        msg = e.response?.data as String;
      }
      throw Exception(msg);
    }
  }
}

final bookingsProvider = AsyncNotifierProvider<BookingsNotifier, List<dynamic>>(() {
  return BookingsNotifier();
});

// Keep posProvider as alias for backwards compat
final posProvider = bookingsProvider;
