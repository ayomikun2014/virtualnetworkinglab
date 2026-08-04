import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/errors/failures.dart';
import '../../core/services/auth_service.dart';
import '../models/user_model.dart';

/// Contract interface for Authentication Repository
abstract class IAuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserModel> login({required String identifier, required String password});
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUserProfile();
}

/// Firebase & Cloud Firestore implementation of Authentication Repository
class FirebaseAuthRepository implements IAuthRepository {
  final AuthService _authService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    AuthService? authService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final userCredential = await _authService.loginWithEmailOrMatric(
      identifier: identifier,
      password: password,
    );

    final uid = userCredential.user!.uid;
    final userProfile = await _fetchUserProfile(uid);

    if (userProfile == null) {
      throw const AuthFailure('User authenticated but profile document was not found.');
    }

    return userProfile;
  }

  @override
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) async {
    return await _authService.registerStudent(
      email: email,
      password: password,
      displayName: displayName,
      studentIdNumber: studentIdNumber,
      departmentId: departmentId,
      enrolledCourseIds: enrolledCourseIds,
    );
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return await _fetchUserProfile(user.uid);
  }

  /// Helper to fetch UserModel profile from Cloud Firestore
  Future<UserModel?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        final authUser = currentUser;
        final email = authUser?.email ?? '';
        final isAdmin = email.toLowerCase() == 'admin@virtuanetlab.univ.edu' || email.toLowerCase().startsWith('admin');
        final role = isAdmin ? UserRole.admin : UserRole.student;
        final name = isAdmin ? 'Root Administrator' : (authUser?.displayName ?? 'User Account');
        final now = DateTime.now();

        final newProfile = UserModel(
          uid: uid,
          email: email,
          displayName: name,
          role: role,
          departmentId: isAdmin ? 'dept_admin' : 'dept_general',
          isActive: true,
          lastLoginAt: now,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(newProfile.toJson(), SetOptions(merge: true));

        return newProfile;
      }

      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw ServerFailure('Failed to fetch user profile: $e');
    }
  }
}
