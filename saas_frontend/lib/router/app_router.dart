// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/pos_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/finance_screen.dart';
import '../screens/users_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/checkin_screen.dart';

// Use a separate provider for the listenable so GoRouter can react to state changes
final _authStateListenableProvider = Provider<AuthStateListenable>((ref) {
  return AuthStateListenable(ref);
});

class AuthStateListenable extends ChangeNotifier {
  final Ref _ref;

  AuthStateListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }

  AuthState get state => _ref.read(authProvider);
}

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(_authStateListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = authListenable.state;
      final isLoggingIn = state.uri.path == '/login';

      if (!authState.isAuthenticated && !isLoggingIn) return '/login';

      if (authState.isAuthenticated && isLoggingIn) {
        bool hasPerm(String key) => authState.permissions?[key] ?? (authState.role == 'Admin');
        if (hasPerm('canAccessDashboard')) return '/dashboard';
        if (hasPerm('canAccessCalendar')) return '/calendar';
        if (hasPerm('canAccessPOS')) return '/pos';
        if (hasPerm('canAccessCustomers')) return '/customers';
        if (hasPerm('canAccessSettings')) return '/settings';
        return '/calendar';
      }

      if (authState.isAuthenticated) {
        bool hasPerm(String key) => authState.permissions?[key] ?? (authState.role == 'Admin');
        final path = state.uri.path;

        if (path == '/dashboard' && !hasPerm('canAccessDashboard')) return '/calendar';
        if (path == '/calendar' && !hasPerm('canAccessCalendar')) return '/dashboard';
        if (path == '/pos' && !hasPerm('canAccessPOS')) return '/calendar';
        if (path == '/subscriptions' && !hasPerm('canAccessSubscriptions')) return '/calendar';
        if (path == '/users' && !hasPerm('canAccessUsers')) return '/calendar';
        if (path == '/finance' && !hasPerm('canAccessFinance')) return '/calendar';
        if (path == '/customers' && !hasPerm('canAccessCustomers')) return '/calendar';
        if (path == '/settings' && !hasPerm('canAccessSettings')) return '/calendar';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PosScreen()),
          ),
          GoRoute(
            path: '/subscriptions',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SubscriptionsScreen()),
          ),
          GoRoute(
            path: '/finance',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FinanceScreen()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsersScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CustomersScreen()),
          ),
          GoRoute(
            path: '/checkin',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CheckInScreen()),
          ),
        ],
      ),
    ],
  );
});
