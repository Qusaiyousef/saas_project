import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

class CustomersNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    return _fetchCustomers();
  }

  Future<List<dynamic>> _fetchCustomers() async {
    final dio = ref.read(dioProvider);

    try {
      final response = await dio.get('/customers');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to load customers: ${e.response?.data ?? e.message}');
    }
  }

  Future<void> addCustomer(String name, String? phone, DateTime? dob) async {
    final dio = ref.read(dioProvider);

    try {
      await dio.post('/customers', data: {
        'name': name,
        'phone': phone,
        'dateOfBirth': dob?.toIso8601String(),
      });
      ref.invalidateSelf();
      await future;
    } on DioException catch (e) {
      throw Exception('Failed to add customer: ${e.response?.data ?? e.message}');
    }
  }

  Future<void> deleteCustomer(String id) async {
    final dio = ref.read(dioProvider);

    try {
      await dio.delete('/customers/$id');
      ref.invalidateSelf();
      await future;
    } on DioException catch (e) {
      throw Exception('Failed to delete customer: ${e.response?.data ?? e.message}');
    }
  }
}

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<dynamic>>(() {
  return CustomersNotifier();
});
