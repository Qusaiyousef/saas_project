import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

// ── نموذج نتيجة Check-In ─────────────────────────────────────────────────────
class CheckInResult {
  final String id;
  final String name;
  final String? phone;
  final String? fingerprintId;
  final CheckInSubscription? subscription;

  CheckInResult({
    required this.id,
    required this.name,
    this.phone,
    this.fingerprintId,
    this.subscription,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      fingerprintId: json['fingerprintId'] as String?,
      subscription: json['subscription'] == null
          ? null
          : CheckInSubscription.fromJson(
              json['subscription'] as Map<String, dynamic>),
    );
  }

  /// حالة الاشتراك: 0=نشط+مدفوع كامل, 1=نشط+متبقي, 2=منتهٍ أو لا يوجد
  int get statusLevel {
    if (subscription == null) return 2;
    if (subscription!.balance > 0) return 1;
    return 0;
  }
}

class CheckInSubscription {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double amountPaid;
  final double balance;
  final int daysRemaining;
  final String paymentMethod;

  CheckInSubscription({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    required this.daysRemaining,
    required this.paymentMethod,
  });

  factory CheckInSubscription.fromJson(Map<String, dynamic> json) {
    return CheckInSubscription(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      daysRemaining: json['daysRemaining'] as int,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
    );
  }
}

// ── State للبحث ──────────────────────────────────────────────────────────────
class CheckInState {
  final bool isLoading;
  final CheckInResult? result;
  final String? error;
  final bool searched;

  const CheckInState({
    this.isLoading = false,
    this.result,
    this.error,
    this.searched = false,
  });

  CheckInState copyWith({
    bool? isLoading,
    CheckInResult? result,
    String? error,
    bool? searched,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CheckInState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      searched: searched ?? this.searched,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class CheckInNotifier extends Notifier<CheckInState> {
  @override
  CheckInState build() => const CheckInState();

  Dio get _dio => ref.read(dioProvider);

  /// البحث برقم الهاتف
  Future<void> searchByPhone(String phone) async {
    if (phone.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, clearResult: true, clearError: true, searched: true);
    try {
      final response = await _dio.get('/customers/by-phone/${phone.trim()}');
      state = state.copyWith(
        isLoading: false,
        result: CheckInResult.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 404 ? null : e.message;
      state = state.copyWith(isLoading: false, error: msg, clearResult: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), clearResult: true);
    }
  }

  /// البحث بكود الجهاز الخارجي
  Future<void> searchByFingerprintId(String fingerprintId) async {
    if (fingerprintId.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, clearResult: true, clearError: true, searched: true);
    try {
      final response = await _dio.get('/customers/by-fingerprint/${fingerprintId.trim()}');
      state = state.copyWith(
        isLoading: false,
        result: CheckInResult.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 404 ? null : e.message;
      state = state.copyWith(isLoading: false, error: msg, clearResult: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), clearResult: true);
    }
  }

  /// ربط معرف بصمة خارجية بعميل
  Future<bool> linkFingerprintId(String customerId, String fingerprintId) async {
    try {
      await _dio.put('/customers/$customerId/fingerprint',
          data: {'fingerprintId': fingerprintId});
      // تحديث النتيجة الحالية
      if (state.result != null) {
        final updated = CheckInResult(
          id: state.result!.id,
          name: state.result!.name,
          phone: state.result!.phone,
          fingerprintId: fingerprintId,
          subscription: state.result!.subscription,
        );
        state = state.copyWith(result: updated);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    state = const CheckInState();
  }
}

final checkInProvider = NotifierProvider<CheckInNotifier, CheckInState>(() {
  return CheckInNotifier();
});
