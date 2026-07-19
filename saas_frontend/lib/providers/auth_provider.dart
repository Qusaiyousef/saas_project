import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant_type.dart';

// === إعدادات الرابط (API Configuration) ===

//const String API_BASE_URL = 'http://localhost:5286/api';

// لرفع الموقع على الإنترنت (Production) :
 const String API_BASE_URL = '/api';
// =========================================

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
  final Dio _dio = Dio(BaseOptions(baseUrl: API_BASE_URL));

  @override
  AuthState build() {
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
              permissionsMap = Map<String, bool>.from(jsonDecode(permissionsString));
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
      
      final dio = Dio(BaseOptions(baseUrl: API_BASE_URL));
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer ${authState.token}';
          return handler.next(options);
        },
      ));

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
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      
      // Decode JWT using jwt_decoder
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      final tenantTypeString = decodedToken['TenantType'] as String?;
      final role = decodedToken['Role'] as String?;
      
      TenantType type = TenantType.pool;
      if (tenantTypeString == 'Chalet') type = TenantType.chalet;
      if (tenantTypeString == 'Gym') type = TenantType.gym;

      final permissionsData = response.data['permissions'] as Map<String, dynamic>?;
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
      String errorMessage = 'Login failed';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
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
  final dio = Dio(BaseOptions(baseUrl: API_BASE_URL));
  
  if (authState.token != null) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer ${authState.token}';
        return handler.next(options);
      },
    ));
  }
  return dio;
});
