import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/enums/app_enums.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/pending_approval_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../features/dashboard/screens/lecturer_dashboard.dart';
import '../features/dashboard/screens/student_dashboard.dart';
import '../features/dashboard/widgets/dashboard_layout.dart';
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
        // '/register' is a real route (see GoRoute below) that an
        // unauthenticated visitor must be able to reach. Without it here,
        // rule 1 below treats /register as just another protected route and
        // redirect-loops straight back to /login before the form ever shows.
        final isLoggingIn = location == '/login' || location == '/register';

        // 1. Unauthenticated users accessing protected routes -> Redirect to Login
        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }

        // 2. Authenticated users accessing Login/Register -> Redirect to Role Dashboard
        if (isLoggedIn && isLoggingIn) {
          return _homeRouteFor(authProvider);
        }

        // 3. Role Guards for Protected Routes
        if (isLoggedIn) {
          final user = authProvider.currentUser;
          final role = user?.role;

          // Admin area guard
          if (location.startsWith('/admin-dashboard') &&
              role != UserRole.admin) {
            return _homeRouteFor(authProvider);
          }

          // Lecturer area guard — also catches a lecturer whose account is
          // still awaiting approval. Without this, a pending lecturer could
          // type /lecturer-dashboard into the address bar directly and land
          // on it, even though nothing there was built for an unapproved
          // account and no courses have been assigned yet.
          final isPendingLecturer =
              role == UserRole.lecturer && user?.approvalStatus == 'pending';
          final lacksLecturerAccess =
              (role != UserRole.lecturer && role != UserRole.admin) ||
              isPendingLecturer;
          if (location.startsWith('/lecturer-dashboard') &&
              lacksLecturerAccess) {
            return _homeRouteFor(authProvider);
          }

          // An approved lecturer (or anyone else) has no reason to sit on
          // the waiting screen — send them to wherever they actually
          // belong instead.
          if (location == '/pending-approval' && !isPendingLecturer) {
            return _homeRouteFor(authProvider);
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
          path: '/pending-approval',
          builder: (context, state) => const PendingApprovalScreen(),
        ),
        GoRoute(
          path: '/student-dashboard',
          builder: (context, state) {
            final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
            return StudentDashboard(initialTabIndex: tab ?? 0);
          },
        ),
        GoRoute(
          path: '/lecturer-dashboard',
          builder: (context, state) => const LecturerDashboard(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        // Kept for any old bookmarks/links: opens the same dashboard shell
        // (sidebar + working back button) on the Free Practice tab, rather
        // than the bare standalone page this used to be — that page had no
        // sidebar and no way back, since context.go replaces navigation
        // history and there was nothing for an AppBar back arrow to pop to.
        GoRoute(
          path: '/practice-levels',
          builder: (context, state) => const StudentDashboard(
            initialTabIndex: DashboardLayout.freePracticeTabIndex,
          ),
        ),
        GoRoute(
          path: '/canvas-builder/:topologyId',
          builder: (context, state) {
            final topologyId =
                state.pathParameters['topologyId'] ?? 'default_canvas';
            final exerciseId = state.uri.queryParameters['exerciseId'];
            final practiceLevel = int.tryParse(
              state.uri.queryParameters['practiceLevel'] ?? '',
            );
            return CanvasBuilderScreen(
              // go_router's default page key is derived from the route's
              // path *pattern* (/canvas-builder/:topologyId), not the
              // resolved topologyId, so switching between two canvases
              // reuses the same Page/State and never re-runs initState.
              // Keying on the actual topologyId forces a fresh screen (and
              // a fresh watchTopology call) per canvas.
              key: ValueKey('canvas_$topologyId'),
              topologyId: topologyId,
              exerciseId: exerciseId,
              practiceLevel: practiceLevel,
            );
          },
        ),
      ],
    );
  }

  /// Where a signed-in user belongs right now — the one place both the
  /// post-login redirect and every route guard decide this, so a pending
  /// lecturer can't fall through a guard that only checked `role` and
  /// forgot `approvalStatus`.
  static String _homeRouteFor(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    switch (user?.role) {
      case UserRole.admin:
        return '/admin-dashboard';
      case UserRole.lecturer:
        return user?.approvalStatus == 'pending'
            ? '/pending-approval'
            : '/lecturer-dashboard';
      case UserRole.student:
      default:
        return '/student-dashboard';
    }
  }
}
