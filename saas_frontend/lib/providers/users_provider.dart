import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

class UsersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/users');
    return (response.data as List).map((u) => Map<String, dynamic>.from(u)).toList();
  }

  Future<void> createUser({
    required String email,
    required String fullName,
    required String password,
    required String role,
    Map<String, bool>? permissions,
  }) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/users', data: {
        'email': email,
        'fullName': fullName,
        'password': password,
        'role': role,
        if (permissions != null) 'permissions': permissions,
      });
      ref.invalidateSelf();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to create user';
      throw Exception(msg);
    }
  }

  Future<void> updateUser({
    required String id,
    required String email,
    required String fullName,
    String? password,
    required String role,
    Map<String, bool>? permissions,
  }) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/users/$id', data: {
        'email': email,
        'fullName': fullName,
        'password': password,
        'role': role,
        if (permissions != null) 'permissions': permissions,
      });
      ref.invalidateSelf();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update user';
      throw Exception(msg);
    }
  }

  Future<void> deleteUser(String id) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.delete('/users/$id');
      ref.invalidateSelf();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to delete user';
      throw Exception(msg);
    }
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<Map<String, dynamic>>>(() {
  return UsersNotifier();
});
