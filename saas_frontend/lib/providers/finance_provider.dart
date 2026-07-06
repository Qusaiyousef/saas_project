import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

final financeSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/finance/summary');
  return response.data;
});

final financeTransactionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/finance/transactions');
  return response.data;
});
