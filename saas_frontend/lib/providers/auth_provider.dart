import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant_type.dart';

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

// === إعدادات الرابط الافتراضي ===
// الطريقة الأولى (ديناميكية): 
// في وضع التطوير (Debug) سيتصل بالسيرفر المحلي، وفي وضع النشر (Release) سيتصل بالسيرفر المرفوع
final String defaultApiUrl = kReleaseMode 
    ? 'http://qusaiali-001-site1.ktempurl.com/api' 
    : 'http://localhost:5286/api';

// الطريقة الثانية (ديناميكية - تفيدك إذا رفعت الواجهة والباك إند على نفس الدومين تماماً)
// final String defaultApiUrl = kIsWeb
//     ? '/api'
//     : 'http://qusaiali-001-site1.ktempurl.com/api';

// =========================================
//final String DEFAULT_API_URL = 'http://localhost:5286/api'; // Default API URL for local development
class ApiUrlNotifier extends Notifier<String> {
  @override
  String build() {
    _loadFromPrefs();
    return defaultApiUrl;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_api_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      state = savedUrl;
    }
  }

  Future<void> updateUrl(String newUrl) async {
    state = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_url', newUrl);
  }
}

final apiUrlProvider = NotifierProvider<ApiUrlNotifier, String>(() {
  return ApiUrlNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final TenantType? tenantType;
  final String? role;
  final String? token;
  final String? error;
  final bool isLoading;
  final Map<String, bool>? permissions;

  AuthState({
    this.isAuthenticated = false,
    this.tenantType,
    this.role,
    this.token,
    this.error,
    this.isLoading = false,
    this.permissions,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    TenantType? tenantType,
    String? role,
    String? token,
    String? error,
    bool? isLoading,
    Map<String, bool>? permissions,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      tenantType: tenantType ?? this.tenantType,
      role: role ?? this.role,
      token: token ?? this.token,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      permissions: permissions ?? this.permissions,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late Dio _dio;

  @override
  AuthState build() {
    final apiUrl = ref.watch(apiUrlProvider);
    _dio = Dio(BaseOptions(baseUrl: apiUrl));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          String friendlyMessage;
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            friendlyMessage =
                'تعذر الاتصال بالسيرفر، يرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً';
          } else if (error.response?.statusCode == 401) {
            friendlyMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
          } else if (error.response?.statusCode == 500) {
            friendlyMessage = 'حدث خطأ في السيرفر، يرجى المحاولة لاحقاً';
          } else {
            final serverMsg = error.response?.data;
            if (serverMsg is Map && serverMsg.containsKey('message')) {
              friendlyMessage = serverMsg['message'].toString();
            } else {
              friendlyMessage =
                  'فشل تسجيل الدخول، يرجى التأكد من البيانات والمحاولة لاحقاً';
            }
          }
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: friendlyMessage,
            ),
          );
        },
      ),
    );
    _loadToken();
    return AuthState();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      try {
        if (!JwtDecoder.isExpired(token)) {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          final tenantTypeString = decodedToken['TenantType'] as String?;
          final role = decodedToken['Role'] as String?;

          TenantType type = TenantType.pool;
          if (tenantTypeString == 'Chalet') type = TenantType.chalet;
          if (tenantTypeString == 'Gym') type = TenantType.gym;

          Map<String, bool>? permissionsMap;
          final permissionsString = prefs.getString('auth_permissions');
          if (permissionsString != null) {
            try {
              permissionsMap = Map<String, bool>.from(
                jsonDecode(permissionsString),
              );
            } catch (_) {}
          }

          state = state.copyWith(
            isAuthenticated: true,
            tenantType: type,
            role: role,
            token: token,
            permissions: permissionsMap,
          );

          // Optionally refresh permissions from API on startup
          fetchMyPermissions();
        } else {
          prefs.remove('auth_token');
          prefs.remove('auth_permissions');
        }
      } catch (_) {}
    }
  }

  Future<void> fetchMyPermissions() async {
    try {
      final authState = state;
      if (authState.token == null) return;

      final apiUrl = ref.read(apiUrlProvider);
      final dio = Dio(BaseOptions(baseUrl: apiUrl));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer ${authState.token}';
            return handler.next(options);
          },
        ),
      );

      final response = await dio.get('/users/my-permissions');
      final permissionsData = Map<String, bool>.from(response.data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_permissions', jsonEncode(permissionsData));

      state = state.copyWith(permissions: permissionsData);
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'];

      // Decode JWT using jwt_decoder
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      final tenantTypeString = decodedToken['TenantType'] as String?;
      final role = decodedToken['Role'] as String?;

      TenantType type = TenantType.pool;
      if (tenantTypeString == 'Chalet') type = TenantType.chalet;
      if (tenantTypeString == 'Gym') type = TenantType.gym;

      final permissionsData =
          response.data['permissions'] as Map<String, dynamic>?;
      Map<String, bool>? permissionsMap;
      if (permissionsData != null) {
        permissionsMap = Map<String, bool>.from(permissionsData);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (permissionsMap != null) {
        await prefs.setString('auth_permissions', jsonEncode(permissionsMap));
      }

      state = state.copyWith(
        isAuthenticated: true,
        tenantType: type,
        role: role,
        token: token,
        permissions: permissionsMap,
        isLoading: false,
      );
    } on DioException catch (e) {
      String errorMessage =
          e.error?.toString() ??
          'فشل تسجيل الدخول، يرجى التأكد من البيانات والاتصال';
      if (e.response != null &&
          e.response?.data != null &&
          e.response?.data is Map &&
          (e.response?.data as Map).containsKey('message')) {
        errorMessage = e.response?.data['message'];
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_permissions');
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Provide a global Dio instance that injects the JWT token
final dioProvider = Provider<Dio>((ref) {
  final authState = ref.watch(authProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  final dio = Dio(BaseOptions(baseUrl: apiUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authState.token != null) {
          options.headers['Authorization'] = 'Bearer ${authState.token}';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        String friendlyMessage;
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          friendlyMessage =
              'تعذر الاتصال بالسيرفر، يرجى التحقق من الاتصال بالإنترنت والمحاولة لاحقاً';
        } else if (error.response?.statusCode == 401) {
          friendlyMessage = 'غير مصرح أو اسم المستخدم/كلمة المرور غير صحيحة';
        } else if (error.response?.statusCode == 403) {
          friendlyMessage = 'ليس لديك صلاحية لإجراء هذه العملية';
        } else if (error.response?.statusCode == 500) {
          friendlyMessage = 'حدث خطأ في السيرفر، يرجى المحاولة لاحقاً';
        } else {
          final serverMsg = error.response?.data;
          if (serverMsg is Map && serverMsg.containsKey('message')) {
            friendlyMessage = serverMsg['message'].toString();
          } else if (serverMsg is String && serverMsg.isNotEmpty) {
            friendlyMessage = serverMsg;
          } else {
            friendlyMessage = 'حدث خطأ في الشبكة، يرجى المحاولة لاحقاً';
          }
        }

        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: friendlyMessage,
          ),
        );
      },
    ),
  );
  return dio;
});
