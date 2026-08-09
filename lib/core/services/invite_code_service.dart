import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// What redeeming a course code actually did, so the caller can show a
/// specific message rather than a bare true/false.
class InviteCodeResult {
  final bool success;
  final String? courseTitle;
  final bool alreadyEnrolled;
  final String? errorMessage;

  const InviteCodeResult({
    required this.success,
    this.courseTitle,
    this.alreadyEnrolled = false,
    this.errorMessage,
  });
}

/// Course-code enrolment for students.
///
/// Replaces the old class/roster system: there is no separate "class"
/// document, no lecturer-generated 8-character join code, no roster
/// membership record. A course code IS the code a lecturer was assigned by
/// an admin (`UserModel.assignedCourses`, see `LecturersTab`'s approval
/// flow) — a student enters that same code, and this checks whether any
/// approved lecturer actually teaches it before enrolling them. There is
/// nothing else to create: `ExerciseProvider.fetchCourseAssessments`
/// already matches on `enrolledCourseIds`, which is the only thing this
/// writes.
class InviteCodeService {
  final FirebaseFirestore _firestore;

  InviteCodeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Looks up which course [code] resolves to, among every approved
  /// lecturer's assigned courses. Returns the course title, or null if no
  /// lecturer currently teaches that code.
  ///
  /// A full scan of approved lecturers, filtered client-side — there is no
  /// Firestore query that reaches into a field inside each element of an
  /// array of maps, and the lecturer roster is small enough (tens, not
  /// thousands) that this is cheap. [LecturersTab] does the same kind of
  /// scan for its own listing.
  Future<String?> _findCourseTitle(String code) async {
    final lecturers = await _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'lecturer')
        .where('approvalStatus', isEqualTo: 'approved')
        .get();

    for (final doc in lecturers.docs) {
      final courses =
          (doc.data()['assignedCourses'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
      for (final course in courses) {
        if ((course['code'] as String?)?.toUpperCase() == code) {
          return course['title'] as String?;
        }
      }
    }
    return null;
  }

  /// Verifies [code] is currently taught, then enrols [studentUid] in it.
  Future<InviteCodeResult> redeemCourseCode({
    required String code,
    required String studentUid,
    List<String> currentlyEnrolled = const [],
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return const InviteCodeResult(
        success: false,
        errorMessage: 'Enter a course code.',
      );
    }

    if (currentlyEnrolled.contains(cleanCode)) {
      return const InviteCodeResult(success: false, alreadyEnrolled: true);
    }

    try {
      final courseTitle = await _findCourseTitle(cleanCode);
      if (courseTitle == null) {
        return InviteCodeResult(
          success: false,
          errorMessage:
              'No lecturer is currently assigned to course $cleanCode. '
              'Check the code with your lecturer.',
        );
      }

      await _firestore.collection(AppConstants.usersCollection).doc(studentUid).set({
        'enrolledCourseIds': FieldValue.arrayUnion([cleanCode]),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Best-effort: the admin Overview audit feed reads this collection,
      // but a logging hiccup here must never look like the enrolment
      // itself failed.
      try {
        final logDoc = _firestore
            .collection(AppConstants.currentActivityLogsCollection)
            .doc();
        await logDoc.set({
          'id': logDoc.id,
          'action': 'JOIN_COURSE',
          'description': 'Student ($studentUid) joined course $cleanCode',
          'performedBy': studentUid,
          'timestamp': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return InviteCodeResult(success: true, courseTitle: courseTitle);
    } catch (e) {
      return InviteCodeResult(
        success: false,
        errorMessage: 'Could not join $cleanCode: $e',
      );
    }
  }
}
