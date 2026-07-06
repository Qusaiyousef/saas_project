import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

class PaymentsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addPayment(String customerId, String? subscriptionId, String? timeBookingId, double amount, String? notes) async {
    final dio = ref.read(dioProvider);

    try {
      await dio.post('/payments', data: {
        'customerId': customerId,
        'subscriptionId': subscriptionId,
        'timeBookingId': timeBookingId,
        'amount': amount,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw Exception('Failed to add payment: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<dynamic>> getCustomerPayments(String customerId) async {
    final dio = ref.read(dioProvider);

    try {
      final response = await dio.get('/payments/customer/$customerId');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch payments: ${e.response?.data ?? e.message}');
    }
  }
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, void>(() {
  return PaymentsNotifier();
});
