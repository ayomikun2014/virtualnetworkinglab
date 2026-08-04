import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/enums/app_enums.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../features/dashboard/screens/lecturer_dashboard.dart';
import '../features/dashboard/screens/student_dashboard.dart';
import '../features/exercises/screens/practice_levels_screen.dart';
import '../features/topology/screens/canvas_builder_screen.dart';

/// App Router Configuration with Role-Based Navigation Guards
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        // While auth provider is initializing session state, do not redirect
        if (authProvider.isLoading) return null;

        final isLoggedIn = authProvider.isLoggedIn;
        final location = state.matchedLocation;
        final isLoggingIn = location == '/login' || location == '/register';

        // 1. Unauthenticated users accessing protected routes -> Redirect to Login
        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }

        // 2. Authenticated users accessing Login/Register -> Redirect to Role Dashboard
        if (isLoggedIn && isLoggingIn) {
          final role = authProvider.currentUser?.role;
          switch (role) {
            case UserRole.admin:
              return '/admin-dashboard';
            case UserRole.lecturer:
              return '/lecturer-dashboard';
            case UserRole.student:
            default:
              return '/student-dashboard';
          }
        }

        // 3. Role Guards for Protected Routes
        if (isLoggedIn) {
          final role = authProvider.currentUser?.role;

          // Admin area guard
          if (location.startsWith('/admin-dashboard') && role != UserRole.admin) {
            return _getHomeRouteForRole(role);
          }

          // Lecturer area guard
          if (location.startsWith('/lecturer-dashboard') &&
              role != UserRole.lecturer &&
              role != UserRole.admin) {
            return _getHomeRouteForRole(role);
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/student-dashboard',
          builder: (context, state) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/lecturer-dashboard',
          builder: (context, state) => const LecturerDashboard(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/practice-levels',
          builder: (context, state) => const PracticeLevelsScreen(),
        ),
        GoRoute(
          path: '/canvas-builder/:topologyId',
          builder: (context, state) {
            final topologyId = state.pathParameters['topologyId'] ?? 'default_canvas';
            return CanvasBuilderScreen(topologyId: topologyId);
          },
        ),
      ],
    );
  }

  static String _getHomeRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return '/admin-dashboard';
      case UserRole.lecturer:
        return '/lecturer-dashboard';
      case UserRole.student:
      default:
        return '/student-dashboard';
    }
  }
}
