import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:virtuanetlab/app/app_routes.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/core/errors/failures.dart';
import 'package:virtuanetlab/data/models/user_model.dart';
import 'package:virtuanetlab/data/repositories/auth_repository.dart';
import 'package:virtuanetlab/features/auth/providers/auth_provider.dart';
import 'package:virtuanetlab/features/auth/screens/pending_approval_screen.dart';

/// A "logged in" AuthProvider without a real Firebase User — see the note
/// in canvas_gorouter_navigation_test.dart for why `currentUser` can safely
/// stay null here.
class _FakeLoginAuthRepository implements IAuthRepository {
  final UserModel user;
  _FakeLoginAuthRepository(this.user);

  @override
  Stream<User?> get authStateChanges => Stream<User?>.fromIterable([null]);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async => user;

  @override
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) async => user;

  @override
  Future<UserModel> registerLecturer({
    required String email,
    required String password,
    required String displayName,
    required String departmentId,
  }) async => user;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUserProfile() async => user;
}

UserModel _pendingLecturer() {
  final now = DateTime.now();
  return UserModel(
    uid: 'lect1',
    email: 'newlecturer@test.edu',
    displayName: 'Applicant Lecturer',
    role: UserRole.lecturer,
    departmentId: 'dept_net',
    approvalStatus: 'pending',
    lastLoginAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Future<AuthProvider> _signIn(WidgetTester tester, UserModel user) async {
  final authProvider = AuthProvider(
    authRepository: _FakeLoginAuthRepository(user),
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

  await authProvider.loginWithIdentifierAndPassword(
    identifier: user.email,
    password: 'irrelevant',
  );
  await tester.pumpAndSettle();

  return authProvider;
}

void main() {
  testWidgets(
    'a pending lecturer signing in lands on the waiting screen, not the '
    'lecturer dashboard',
    (tester) async {
      await _signIn(tester, _pendingLecturer());

      expect(find.byType(PendingApprovalScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a pending lecturer cannot reach /lecturer-dashboard by typing the URL',
    (tester) async {
      final authProvider = await _signIn(tester, _pendingLecturer());

      final router = GoRouter.of(
        tester.element(find.byType(PendingApprovalScreen)),
      );
      router.go('/lecturer-dashboard');
      await tester.pumpAndSettle();

      expect(
        find.byType(PendingApprovalScreen),
        findsOneWidget,
        reason:
            'the lecturer-area route guard must catch approvalStatus == '
            "pending even when role == lecturer would otherwise pass — "
            'nothing lecturer-shaped should be reachable pre-approval',
      );

      // Sanity: this really is the account under test, not some other
      // redirect coincidentally landing here.
      expect(authProvider.currentUser?.approvalStatus, 'pending');
    },
  );

  testWidgets(
    'an unauthenticated visitor hitting /pending-approval directly is sent '
    'to /login, not shown the waiting screen',
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

      router.go('/pending-approval');
      await tester.pumpAndSettle();

      expect(find.byType(PendingApprovalScreen), findsNothing);
    },
  );
}

/// Emits a single `null` (no signed-in user) so AuthProvider's initial
/// `isLoading` flips to false and the redirect logic actually runs.
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
