import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:virtuanetlab/app/app_routes.dart';
import 'package:virtuanetlab/core/errors/failures.dart';
import 'package:virtuanetlab/data/models/user_model.dart';
import 'package:virtuanetlab/data/repositories/auth_repository.dart';
import 'package:virtuanetlab/features/auth/providers/auth_provider.dart';
import 'package:virtuanetlab/features/auth/screens/login_screen.dart';
import 'package:virtuanetlab/features/auth/screens/register_screen.dart';

/// Emits a single `null` (no signed-in user) so AuthProvider's initial
/// `isLoading` flips to false and the redirect logic actually runs — while
/// `isLoading` is stuck true (its default), `redirect` returns early and
/// never exercises the checks these tests care about.
class _LoggedOutAuthRepository implements IAuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.fromIterable([null]);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) {
    throw const AuthFailure('not used in this test');
  }

  @override
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) {
    throw const AuthFailure('not used in this test');
  }

  @override
  Future<UserModel> registerLecturer({
    required String email,
    required String password,
    required String displayName,
    required String departmentId,
  }) {
    throw const AuthFailure('not used in this test');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUserProfile() async => null;
}

void main() {
  testWidgets(
    'an unauthenticated visitor can reach /register without being bounced to /login',
    (tester) async {
      final authProvider = AuthProvider(
        authRepository: _LoggedOutAuthRepository(),
      );
      addTearDown(authProvider.dispose);

      final router = AppRouter.createRouter(authProvider);
      addTearDown(router.dispose);

      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Let the fake authStateChanges(null) emission propagate.
      await tester.pump();
      await tester.pump();

      router.go('/register');
      await tester.pumpAndSettle();

      expect(
        find.byType(RegisterScreen),
        findsOneWidget,
        reason:
            'redirect must treat /register as a login-type route — '
            'otherwise an unauthenticated visit bounces straight back to '
            '/login before the form ever renders',
      );
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets(
    'an unauthenticated visitor hitting a protected route is sent to /login',
    (tester) async {
      final authProvider = AuthProvider(
        authRepository: _LoggedOutAuthRepository(),
      );
      addTearDown(authProvider.dispose);

      final router = AppRouter.createRouter(authProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pump();

      router.go('/student-dashboard');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
