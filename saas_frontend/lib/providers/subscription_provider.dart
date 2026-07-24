import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'pos_provider.dart';

class SubscriptionNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    final resource = await ref.watch(defaultResourceProvider.future);
    if (resource == null) return [];

    final resourceId = resource['id'] as String;
    final dio = ref.watch(dioProvider);

    try {
      final response = await dio.get('/subscriptions/resource/$resourceId/active');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<void> addSubscription(String customerName, String? customerId, int months, double totalAmount, double amountPaid, String paymentMethod) async {
    final resource = await ref.read(defaultResourceProvider.future);
    if (resource == null) throw Exception('No resource found');

    final resourceId = resource['id'] as String;
    final dio = ref.read(dioProvider);
    DateTime startDate = DateTime.now();

    if (customerId != null) {
      final currentSubs = state.asData?.value ?? [];
      DateTime latestEnd = startDate;
      for (var sub in currentSubs) {
        if (sub['customerId']?.toString().toLowerCase() == customerId.toString().toLowerCase() && 
            (sub['status'] == 0 || sub['status']?.toString() == '0' || sub['status']?.toString().toLowerCase() == 'active')) {
          try {
            final subEnd = DateTime.parse(sub['endDate']).toLocal();
            if (subEnd.isAfter(latestEnd)) {
              latestEnd = subEnd;
            }
          } catch (_) {}
        }
      }
      if (latestEnd.isAfter(startDate)) {
        startDate = latestEnd;
      }
    }

    final endDate = startDate.add(Duration(days: 30 * months));

    await dio.post('/subscriptions', data: {
      'resourceId': resourceId,
      'customerName': customerName,
      'customerId': customerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': 0,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
    });

    ref.invalidateSelf();
  }

  Future<void> cancelSubscription(String id) async {
    final dio = ref.read(dioProvider);
    await dio.put('/subscriptions/$id/cancel');
    ref.invalidateSelf();
  }
}

final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, List<dynamic>>(() {
  return SubscriptionNotifier();
});
