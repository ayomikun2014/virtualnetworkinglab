import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// State Management Provider for Authentication and User Session Lifecycle
class AuthProvider extends ChangeNotifier {
  final IAuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  /// True while an explicit login/register call is in flight.
  ///
  /// `login()` and `registerStudent()` on the repository each fetch (or, for
  /// registration, first write) the Firestore profile themselves and return
  /// it. But `createUserWithEmailAndPassword`/`signInWithEmailAndPassword`
  /// also fire `authStateChanges` as soon as Firebase's local auth state
  /// updates — typically before that explicit fetch/write finishes. Without
  /// this guard, the reactive listener below ran a SECOND, independent
  /// profile fetch concurrently with the explicit one. For registration in
  /// particular, that second fetch could land in the gap after the auth
  /// account was created but before the real profile document was written,
  /// find nothing, and set `_currentUser` back to null — sometimes moments
  /// after the explicit flow had already navigated the user to their
  /// dashboard, which bounced them straight back to /login mid-registration.
  /// Gating the reactive listener while an explicit call owns the transition
  /// makes exactly one code path respond to any given sign-in.
  bool _isAuthenticating = false;

  AuthProvider({IAuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository() {
    _initAuthListener();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _currentUser != null;
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isLecturer => _currentUser?.role == UserRole.lecturer;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  /// Initializes reactive authentication state stream listener
  void _initAuthListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) async {
        if (_isAuthenticating) return;

        if (user == null) {
          _currentUser = null;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } else {
          await refreshCurrentUserProfile();
        }
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Refreshes current user profile from Cloud Firestore and validates Custom Claims
  Future<void> refreshCurrentUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authRepository.currentUser;
      if (user != null) {
        // Force refresh ID Token to parse updated Custom Claims (vnl_auth, role, departmentId)
        await user.getIdTokenResult(true);
        _currentUser = await _authRepository.getCurrentUserProfile();
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to load user session: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticates student, lecturer, or administrator via Email Address or Matriculation Number
  Future<bool> loginWithIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    _isAuthenticating = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(
        identifier: identifier,
        password: password,
      );
      // Force-refresh the ID token so role/department custom claims are
      // current before any role-gated route redirect evaluates them.
      await _authRepository.currentUser?.getIdTokenResult(true);
      _currentUser = user;
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected login failure: $e';
      return false;
    } finally {
      _isLoading = false;
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Registers a new Student account with matriculation validation and course selection
  Future<bool> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) async {
    _isAuthenticating = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.registerStudent(
        email: email,
        password: password,
        displayName: displayName,
        studentIdNumber: studentIdNumber,
        departmentId: departmentId,
        enrolledCourseIds: enrolledCourseIds,
      );
      await _authRepository.currentUser?.getIdTokenResult(true);
      _currentUser = user;
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Registers a new Lecturer account. Goes in immediately — it's a real,
  /// login-able account — but lands `approvalStatus: 'pending'`, which the
  /// router reads to keep them off the real lecturer dashboard until an
  /// admin approves them.
  Future<bool> registerLecturer({
    required String email,
    required String password,
    required String displayName,
    required String departmentId,
  }) async {
    _isAuthenticating = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.registerLecturer(
        email: email,
        password: password,
        displayName: displayName,
        departmentId: departmentId,
      );
      await _authRepository.currentUser?.getIdTokenResult(true);
      _currentUser = user;
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Logs out current user session
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
