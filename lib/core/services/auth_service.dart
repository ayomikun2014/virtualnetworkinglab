import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../enums/app_enums.dart';
import '../errors/failures.dart';
import '../utils/validators.dart';
import '../../data/models/user_model.dart';
import '../../data/models/class_model.dart';

/// Core Authentication & Cross-Role Linking Service for VirtuaNetLab
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Resolves an institutional Matriculation Number (e.g., NT20240111512) to an Email Address
  Future<String> resolveEmailFromMatric(String matricNumber) async {
    final cleanMatric = matricNumber.trim().toUpperCase();

    if (!Validators.isValidMatricNumber(cleanMatric)) {
      throw const ValidationFailure(
        'Invalid Matriculation Number format. Must match NT-YYYY-XXXXX (e.g. NT20240111512)',
      );
    }

    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('studentIdNumber', isEqualTo: cleanMatric)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw AuthFailure(
          'No student account found registered with Matriculation Number $cleanMatric',
        );
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        throw const ServerFailure(
          'Account record exists but institutional email is missing. Contact support.',
        );
      }

      return email;
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Failed to resolve email from matriculation number: $e');
    }
  }

  /// Logs in a user via Email Address OR Matriculation Number + Password
  Future<UserCredential> loginWithEmailOrMatric({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();

    if (cleanIdentifier.isEmpty) {
      throw const ValidationFailure('Please enter your Email or Matriculation Number');
    }

    if (password.isEmpty) {
      throw const ValidationFailure('Please enter your password');
    }

    String resolvedEmail;

    // Root Admin Shortcut
    if (cleanIdentifier == 'admin@virtuanetlab.univ.edu' || cleanIdentifier.toLowerCase() == 'admin') {
      resolvedEmail = 'admin@virtuanetlab.univ.edu';
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: resolvedEmail,
          password: password,
        );
        return userCredential;
      } catch (_) {
        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: resolvedEmail,
            password: password,
          );
          // Write admin user profile
          final now = DateTime.now();
          await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': resolvedEmail,
            'displayName': 'Root Administrator',
            'role': UserRole.admin.name,
            'departmentId': 'dept_admin',
            'isActive': true,
            'lastLoginAt': now.toIso8601String(),
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }, SetOptions(merge: true));
          return userCredential;
        } catch (_) {}
      }
    } else if (Validators.isMatricNumber(cleanIdentifier)) {
      resolvedEmail = await resolveEmailFromMatric(cleanIdentifier);
    } else {
      if (!Validators.isValidEmail(cleanIdentifier)) {
        throw const ValidationFailure('Please enter a valid Email Address or Matriculation Number');
      }
      resolvedEmail = cleanIdentifier;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      // Update lastLoginAt timestamp in Firestore profile
      if (userCredential.user != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw const AuthFailure('No user account found with these credentials.');
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthFailure('Invalid credentials provided. Please check your password.');
        case 'user-disabled':
          throw const AuthFailure('This account has been disabled. Contact administrator.');
        default:
          throw AuthFailure(e.message ?? 'Authentication failed. Please try again.');
      }
    } catch (e) {
      throw ServerFailure('Login error: $e');
    }
  }

  /// Registers a new Student account, enforces matric uniqueness, writes UserModel profile
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String displayName,
    required String studentIdNumber,
    required String departmentId,
    List<String> enrolledCourseIds = const [],
  }) async {
    final cleanEmail = email.trim();
    final cleanMatric = studentIdNumber.trim().toUpperCase();
    final cleanName = displayName.trim();

    if (!Validators.isValidEmail(cleanEmail)) {
      throw const ValidationFailure('Please enter a valid institutional email address.');
    }
    if (!Validators.isValidMatricNumber(cleanMatric)) {
      throw const ValidationFailure(
        'Invalid Matriculation Number. Format must be NT + Year + Sequence (e.g. NT20240111512).',
      );
    }
    if (!Validators.isPasswordValid(password)) {
      throw const ValidationFailure('Password must be at least 6 characters long.');
    }
    if (!Validators.isValidDisplayName(cleanName)) {
      throw const ValidationFailure('Please enter your full name.');
    }

    try {
      final matricQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('studentIdNumber', isEqualTo: cleanMatric)
          .limit(1)
          .get();

      if (matricQuery.docs.isNotEmpty) {
        throw ValidationFailure(
          'Matriculation Number $cleanMatric is already registered to another account.',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      final userModel = UserModel(
        uid: uid,
        email: cleanEmail,
        displayName: cleanName,
        studentIdNumber: cleanMatric,
        role: UserRole.student,
        departmentId: departmentId,
        enrolledCourseIds: enrolledCourseIds,
        freePracticeLevel: 1,
        isActive: true,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
        stats: {
          'completedExercises': 0,
          'totalScore': 0,
        },
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toJson());

      for (final courseId in enrolledCourseIds) {
        final memberId = '${courseId}_$uid';
        final memberModel = ClassMemberModel(
          memberId: memberId,
          classId: courseId,
          studentUid: uid,
          status: MemberStatus.active,
          joinedAt: now,
          createdAt: now,
        );

        await _firestore
            .collection(AppConstants.classMembersCollection)
            .doc(memberId)
            .set(memberModel.toJson());
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthFailure('Email address is already in use by another account.');
      }
      throw AuthFailure(e.message ?? 'Registration failed.');
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Failed to register student account: $e');
    }
  }

  /// Student Joins a Class Cohort using Lecturer's 8-Character Join Code
  Future<bool> joinClassWithCode({
    required String joinCode,
    required String studentUid,
  }) async {
    final cleanCode = joinCode.trim().toUpperCase();
    if (cleanCode.length < 4) {
      throw const ValidationFailure('Enter a valid 8-character class join code.');
    }

    try {
      final classQuery = await _firestore
          .collection('${AppConstants.rootPath}/${AppConstants.classesCollection}')
          .where('joinCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (classQuery.docs.isEmpty) {
        throw AuthFailure('No active class section found for join code $cleanCode');
      }

      final classDoc = classQuery.docs.first;
      final classData = classDoc.data();
      final classId = classDoc.id;
      final courseId = classData['courseId'] as String? ?? 'NET201';
      final sectionName = classData['sectionName'] as String? ?? 'Section A';

      final now = DateTime.now();

      // 1. Add courseId to Student's enrolledCourseIds
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(studentUid)
          .update({
        'enrolledCourseIds': FieldValue.arrayUnion([courseId]),
        'updatedAt': now.toIso8601String(),
      });

      // 2. Create class_members Junction Record
      final memberId = '${classId}_$studentUid';
      await _firestore
          .collection(AppConstants.classMembersCollection)
          .doc(memberId)
          .set({
        'memberId': memberId,
        'classId': classId,
        'studentUid': studentUid,
        'status': 'active',
        'joinedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      // 3. Increment studentCount in class document
      await _firestore
          .collection('${AppConstants.rootPath}/${AppConstants.classesCollection}')
          .doc(classId)
          .update({
        'studentCount': FieldValue.increment(1),
        'updatedAt': now.toIso8601String(),
      });

      // 4. Log Activity Event for Admin Feed
      final logDoc = _firestore.collection('${AppConstants.rootPath}/${AppConstants.activityLogsCollection}').doc();
      await logDoc.set({
        'id': logDoc.id,
        'action': 'JOIN_CLASS',
        'description': 'Student ($studentUid) joined class $sectionName ($courseId) with code $cleanCode',
        'performedBy': studentUid,
        'timestamp': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      });

      return true;
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Failed to join class cohort: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ServerFailure('Sign out error: $e');
    }
  }
}
