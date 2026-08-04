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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(
        identifier: identifier,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected login failure: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.registerStudent(
        email: email,
        password: password,
        displayName: displayName,
        studentIdNumber: studentIdNumber,
        departmentId: departmentId,
        enrolledCourseIds: enrolledCourseIds,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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
