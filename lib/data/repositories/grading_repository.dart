import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../features/topology/services/topology_grader.dart';

/// The private "correct answer" for an exercise.
///
/// Written by `LecturerManagementService.createExercise` to
/// `exercises/{exerciseId}/private/solution_key`. `solutionTopologyId` points
/// at a reference topology the lecturer built in the canvas editor, which
/// `TopologyGrader` compares the student's canvas against.
class ExerciseSolutionKey {
  final String solutionTopologyId;
  final Map<String, dynamic> targetCriteria;

  const ExerciseSolutionKey({
    required this.solutionTopologyId,
    this.targetCriteria = const {},
  });

  factory ExerciseSolutionKey.fromJson(Map<String, dynamic> json) {
    return ExerciseSolutionKey(
      solutionTopologyId: json['solutionTopologyId'] as String,
      targetCriteria:
          (json['targetCriteria'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// A student's standing on one exercise.
///
/// Lives at `users/{uid}/progress/{exerciseId}`. [attemptCount] counts every
/// Check Connection press; [attemptsUsed] freezes at the count that first
/// passed, so re-opening a solved level to look around doesn't inflate the
/// "solved in N attempts" figure shown on the level cards.
class ExerciseProgress {
  final String exerciseId;
  final int attemptCount;
  final bool passed;
  final int? attemptsUsed;
  final DateTime? passedAt;

  /// How many of the most recent attempt's checks passed, out of
  /// [totalChecks] — e.g. 6 of 8 devices/cables correct. Both null until the
  /// first attempt; from then on they describe the LATEST attempt, not a
  /// running best — a course assessment only ever gets one attempt anyway
  /// (see [GradingProvider]'s course-assessment lock), so "latest" and
  /// "only" are the same thing there. For a re-checkable Free Practice
  /// level, this is simply whatever the last press showed.
  final int? correctChecks;
  final int? totalChecks;

  const ExerciseProgress({
    required this.exerciseId,
    this.attemptCount = 0,
    this.passed = false,
    this.attemptsUsed,
    this.passedAt,
    this.correctChecks,
    this.totalChecks,
  });

  /// True when the attempt that produced this record is the one that solved
  /// the exercise — as opposed to a re-check of something already solved.
  ///
  /// [attemptsUsed] freezes at the attempt that first passed, so it equals
  /// [attemptCount] on exactly that attempt and falls behind on every later
  /// one. This is what decides whether a solve pays out, so it deliberately
  /// does not care *how many* attempts it took: failing twice and getting
  /// there on the third go is still a first solve, and still earns.
  bool get solvedOnThisAttempt =>
      passed && attemptsUsed != null && attemptsUsed == attemptCount;

  /// Percentage score for the latest attempt — "correct out of total"
  /// scaled to 0–100 — or null before any attempt exists.
  double? get scorePercent {
    if (correctChecks == null || totalChecks == null || totalChecks == 0) {
      return null;
    }
    return (correctChecks! / totalChecks!) * 100;
  }

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    final passedAtRaw = json['passedAt'] as String?;
    return ExerciseProgress(
      exerciseId: json['exerciseId'] as String? ?? '',
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      attemptsUsed: (json['attemptsUsed'] as num?)?.toInt(),
      passedAt: passedAtRaw == null ? null : DateTime.tryParse(passedAtRaw),
      correctChecks: (json['correctChecks'] as num?)?.toInt(),
      totalChecks: (json['totalChecks'] as num?)?.toInt(),
    );
  }
}

/// One canvas the student pressed Save on, as listed on the Save History
/// tab.
///
/// Saves share the `users/{uid}/attempts` collection with Check Connection
/// records (see [IGradingRepository.recordAttempt] /
/// [IGradingRepository.recordSave]), distinguished by `type`. Save History
/// deliberately lists only the saves: a graded attempt is feedback about a
/// level, not a thing the student stored and might want to reopen, and
/// interleaving the two buried the handful of real saves under every
/// Check Connection press.
class SaveRecord {
  final String id;

  /// Always 'save' for records this class is used to list — kept on the
  /// model because the underlying collection also holds 'check' records
  /// that [IGradingRepository.watchSaveHistory] filters out.
  final String type;

  /// Human-readable name — the level's own title for a graded canvas, or
  /// the name the student typed when saving a sandbox. Never a raw
  /// exerciseId/topologyId.
  final String title;

  final String? exerciseId;

  /// The canvas this save points at, so history rows can reopen it.
  final String? topologyId;

  /// Set only on 'check' records, which Save History does not list.
  final bool? passed;

  /// Set only on 'check' records, which Save History does not list.
  final List<String> failureMessages;

  final DateTime attemptedAt;

  /// A save made against a Free Practice level or course assessment, as
  /// opposed to a free-form sandbox canvas.
  bool get isFromExercise => exerciseId != null && exerciseId!.isNotEmpty;

  const SaveRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.attemptedAt,
    this.exerciseId,
    this.topologyId,
    this.passed,
    this.failureMessages = const [],
  });

  factory SaveRecord.fromJson(String id, Map<String, dynamic> json) {
    final rawChecks = json['checks'] as List<dynamic>? ?? const [];
    final failures = rawChecks
        .cast<Map<String, dynamic>>()
        .where((c) => c['passed'] != true)
        .map((c) => c['message'] as String? ?? 'Unnamed check')
        .toList();

    return SaveRecord(
      id: id,
      // Records written before this field existed are all Check Connection
      // attempts — 'check' is the correct backfill default, not a guess.
      type: json['type'] as String? ?? 'check',
      title: json['title'] as String? ?? 'Untitled canvas',
      exerciseId: json['exerciseId'] as String?,
      topologyId: json['topologyId'] as String?,
      passed: json['passed'] as bool?,
      failureMessages: failures,
      attemptedAt:
          DateTime.tryParse(json['attemptedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Contract interface for reading a level's answer key and recording a
/// student's grading attempts and canvas saves against it.
abstract class IGradingRepository {
  Future<ExerciseSolutionKey?> getSolutionKey(String exerciseId);

  /// Records one Check Connection press and returns the student's updated
  /// standing on this exercise. [title] is the exercise's display name,
  /// stored on the record so the Submissions history can show it without a
  /// second read per row.
  ///
  /// [practiceLevel], [authorUid], [studentName] and [studentEmail] matter
  /// only for a course assessment (practiceLevel null): when [authorUid] is
  /// given, a denormalised result is also written to a top-level collection
  /// the lecturer's own Grading Center reads directly by
  /// `where('authorUid', isEqualTo: ...)` — a plain, always-indexed
  /// single-field query, deliberately not a Firestore collection-group
  /// query across every student's `progress` subcollection, which would
  /// need its own index this project has no way to deploy from here. Free
  /// Practice attempts (practiceLevel set) never write this record: the
  /// user's own requirement is that free practice stays out of a
  /// lecturer's gradebook.
  Future<ExerciseProgress> recordAttempt({
    required String uid,
    required String exerciseId,
    required String title,
    required GradeResult result,
    int? practiceLevel,
    String? authorUid,
    String? studentName,
    String? studentEmail,
  });

  /// One-shot read of a student's standing on one exercise, or null if they
  /// have never attempted it. Used to enforce the course-assessment
  /// one-attempt rule before grading runs at all — [watchProgress] is a
  /// stream meant for a UI subscription, not a single point-in-time check.
  Future<ExerciseProgress?> getProgress({
    required String uid,
    required String exerciseId,
  });

  /// Records a plain "Save Canvas" press — no grading involved, just a
  /// checkpoint in the student's activity history. [exerciseId] is null for
  /// an ungraded sandbox canvas.
  Future<void> recordSave({
    required String uid,
    required String title,
    required String topologyId,
    String? exerciseId,
  });

  /// Advances the student's `freePracticeLevel` so the next Free Practice
  /// level unlocks. No-op for course assessments.
  Future<void> advancePracticeLevel({
    required String uid,
    required int practiceLevel,
  });

  /// Adds [delta] to the student's score, returning the total either side
  /// of the change.
  ///
  /// Floors at zero: a run of failed checks should leave a student with
  /// nothing to spend, not a debt they have to climb out of before the
  /// score means anything again. `before` is returned because "could they
  /// actually afford this penalty?" is not answerable from the new total
  /// alone — zero after a deduction could mean they had exactly enough, or
  /// that they had nothing to give.
  Future<({int before, int after})> applyPointsDelta({
    required String uid,
    required int delta,
  });

  /// Drops the student back one Free Practice level, returning the level
  /// they land on. Never goes below 1.
  Future<int> demotePracticeLevel({required String uid});

  /// Clears this student's standing on one exercise so it can be played
  /// again from scratch.
  ///
  /// Attempts drop back to zero and `passed` to false, which is what makes
  /// the next solve pay out again — a re-check of a level still marked
  /// passed is deliberately worth nothing (see [GradingProvider]). The
  /// per-attempt log is left alone: it is a record of what the student
  /// actually did, and replaying doesn't un-do that.
  Future<void> resetExerciseProgress({
    required String uid,
    required String exerciseId,
  });

  /// All of this student's exercise progress, keyed by exerciseId.
  Stream<Map<String, ExerciseProgress>> watchProgress(String uid);

  /// The canvases this student has saved, newest first. Check Connection
  /// attempts share the same collection but are excluded — Save History
  /// lists things the student stored, not every time they were graded.
  Stream<List<SaveRecord>> watchSaveHistory(String uid);
}

/// Firebase & Cloud Firestore implementation of Grading Repository
class FirebaseGradingRepository implements IGradingRepository {
  final FirebaseFirestore _firestore;

  FirebaseGradingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ExerciseSolutionKey?> getSolutionKey(String exerciseId) async {
    try {
      final doc = await _firestore
          .doc(AppConstants.exerciseSolutionKeyPath(exerciseId))
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return ExerciseSolutionKey.fromJson(doc.data()!);
    } catch (e) {
      throw ServerFailure('Failed to load exercise solution key: $e');
    }
  }

  @override
  Future<ExerciseProgress?> getProgress({
    required String uid,
    required String exerciseId,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.userProgressCollection(uid))
          .doc(exerciseId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ExerciseProgress.fromJson(doc.data()!);
    } catch (e) {
      throw ServerFailure('Failed to load exercise progress: $e');
    }
  }

  /// Where a lecturer's Grading Center reads real, per-student course
  /// assessment results from — see the field doc on
  /// [IGradingRepository.recordAttempt] for why this exists instead of a
  /// collection-group query.
  String get _exerciseResultsPath => AppConstants.exerciseResultsCollection;

  @override
  Future<ExerciseProgress> recordAttempt({
    required String uid,
    required String exerciseId,
    required String title,
    required GradeResult result,
    int? practiceLevel,
    String? authorUid,
    String? studentName,
    String? studentEmail,
  }) async {
    try {
      final now = DateTime.now();

      // Detailed per-attempt log, kept separate from the rolled-up counter so
      // a lecturer can see what a student actually tried.
      final attemptRef = _firestore
          .collection(AppConstants.userAttemptsCollection(uid))
          .doc();

      await attemptRef.set({
        'attemptId': attemptRef.id,
        'type': 'check',
        'title': title,
        'exerciseId': exerciseId,
        'passed': result.passed,
        'checks': result.checks
            .map((c) => {'passed': c.passed, 'message': c.message})
            .toList(),
        'attemptedAt': now.toIso8601String(),
      });

      // The counter and pass-state move together in a transaction: two
      // near-simultaneous checks (double-tap, or the same student on two
      // devices) would otherwise read the same count and both write it back,
      // losing an attempt.
      final progressRef = _firestore
          .collection(AppConstants.userProgressCollection(uid))
          .doc(exerciseId);

      final updated = await _firestore.runTransaction((tx) async {
        final snap = await tx.get(progressRef);
        final existing = snap.exists && snap.data() != null
            ? ExerciseProgress.fromJson(snap.data()!)
            : ExerciseProgress(exerciseId: exerciseId);

        final newCount = existing.attemptCount + 1;
        // Freeze attemptsUsed/passedAt at the FIRST pass.
        final firstPassNow = result.passed && !existing.passed;

        final updated = ExerciseProgress(
          exerciseId: exerciseId,
          attemptCount: newCount,
          passed: existing.passed || result.passed,
          attemptsUsed: firstPassNow ? newCount : existing.attemptsUsed,
          passedAt: firstPassNow ? now : existing.passedAt,
          // Latest attempt's breakdown, not a running best — see the field
          // doc on ExerciseProgress for why that's the right choice for a
          // once-only course assessment.
          correctChecks: result.checks.where((c) => c.passed).length,
          totalChecks: result.checks.length,
        );

        tx.set(progressRef, {
          'exerciseId': exerciseId,
          'attemptCount': updated.attemptCount,
          'passed': updated.passed,
          'attemptsUsed': updated.attemptsUsed,
          'passedAt': updated.passedAt?.toIso8601String(),
          'correctChecks': updated.correctChecks,
          'totalChecks': updated.totalChecks,
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));

        return updated;
      });

      // Course assessment only — a lecturer's gradebook must not include
      // Free Practice attempts. Best-effort: a lecturer not seeing one
      // result promptly is far less serious than the student's own
      // progress record failing to save, so this never rethrows.
      if (practiceLevel == null && authorUid != null) {
        try {
          await _firestore
              .collection(_exerciseResultsPath)
              .doc('${exerciseId}_$uid')
              .set({
                'exerciseId': exerciseId,
                'uid': uid,
                'authorUid': authorUid,
                'studentName': studentName ?? 'Student',
                'studentEmail': studentEmail ?? '',
                'exerciseTitle': title,
                'passed': updated.passed,
                'correctChecks': updated.correctChecks,
                'totalChecks': updated.totalChecks,
                'attemptedAt': now.toIso8601String(),
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('recordAttempt: failed to write lecturer result: $e');
        }

        // Surfaced on the admin Overview's existing "Recent System Audit
        // Feed" — a course assessment result is exactly the kind of event
        // that feed already exists to show, and this reuses it rather than
        // building admin a second place to look.
        try {
          final score = (updated.totalChecks ?? 0) == 0
              ? 0
              : (((updated.correctChecks ?? 0) / updated.totalChecks!) * 100)
                    .round();
          final logDoc = _firestore
              .collection(AppConstants.currentActivityLogsCollection)
              .doc();
          await logDoc.set({
            'id': logDoc.id,
            'action': 'SUBMIT_ASSESSMENT',
            'description':
                '${studentName ?? 'A student'} submitted "$title" — '
                '$score% (${updated.passed ? 'passed' : 'not passed'})',
            'performedBy': studentName ?? uid,
            'timestamp': now.toIso8601String(),
            'createdAt': now.toIso8601String(),
          });
        } catch (e) {
          debugPrint('recordAttempt: failed to write admin audit log: $e');
        }
      }

      return updated;
    } catch (e) {
      throw ServerFailure('Failed to save grading attempt: $e');
    }
  }

  @override
  Future<void> recordSave({
    required String uid,
    required String title,
    required String topologyId,
    String? exerciseId,
  }) async {
    try {
      final saveRef = _firestore
          .collection(AppConstants.userAttemptsCollection(uid))
          .doc();

      await saveRef.set({
        'attemptId': saveRef.id,
        'type': 'save',
        'title': title,
        'topologyId': topologyId,
        'exerciseId': exerciseId,
        'attemptedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure('Failed to record canvas save: $e');
    }
  }

  @override
  Future<void> advancePracticeLevel({
    required String uid,
    required int practiceLevel,
  }) async {
    try {
      final userDocRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);
      final userSnap = await userDocRef.get();
      final currentLevel =
          (userSnap.data()?['freePracticeLevel'] as num?)?.toInt() ?? 1;

      // Only ever move forward — replaying an earlier level must not demote a
      // student who has already progressed past it.
      if (practiceLevel < currentLevel) return;

      await userDocRef.set({
        'freePracticeLevel': practiceLevel + 1,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw ServerFailure('Failed to update level progress: $e');
    }
  }

  @override
  Future<({int before, int after})> applyPointsDelta({
    required String uid,
    required int delta,
  }) async {
    try {
      final userDocRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);

      // A transaction, not a read-then-write: Check Connection can be
      // pressed again while the previous one is still settling, and two
      // overlapping read-modify-writes would lose one of the deltas.
      return await _firestore.runTransaction<({int before, int after})>((
        transaction,
      ) async {
        final snap = await transaction.get(userDocRef);
        final current = (snap.data()?['points'] as num?)?.toInt() ?? 0;
        final updated = (current + delta).clamp(0, 1 << 30);

        transaction.set(userDocRef, {
          'points': updated,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        return (before: current, after: updated);
      });
    } catch (e) {
      throw ServerFailure('Failed to update score: $e');
    }
  }

  @override
  Future<int> demotePracticeLevel({required String uid}) async {
    try {
      final userDocRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);

      return await _firestore.runTransaction<int>((transaction) async {
        final snap = await transaction.get(userDocRef);
        final current =
            (snap.data()?['freePracticeLevel'] as num?)?.toInt() ?? 1;
        final demoted = current <= 1 ? 1 : current - 1;

        if (demoted != current) {
          transaction.set(userDocRef, {
            'freePracticeLevel': demoted,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }

        return demoted;
      });
    } catch (e) {
      throw ServerFailure('Failed to update level progress: $e');
    }
  }

  @override
  Future<void> resetExerciseProgress({
    required String uid,
    required String exerciseId,
  }) async {
    try {
      final progressRef = _firestore
          .collection(AppConstants.userProgressCollection(uid))
          .doc(exerciseId);

      await progressRef.set({
        'exerciseId': exerciseId,
        'attemptCount': 0,
        'passed': false,
        // Explicit nulls, not omitted keys: this is a merge write, so
        // leaving them out would keep the previous "solved in N attempts"
        // and pass date hanging around on a level the student is about to
        // start over.
        'attemptsUsed': null,
        'passedAt': null,
        'resetAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw ServerFailure('Failed to reset level progress: $e');
    }
  }

  @override
  Stream<Map<String, ExerciseProgress>> watchProgress(String uid) {
    return _firestore
        .collection(AppConstants.userProgressCollection(uid))
        .snapshots()
        .map((snap) {
          final entries = <String, ExerciseProgress>{};
          for (final doc in snap.docs) {
            final data = doc.data();
            entries[doc.id] = ExerciseProgress.fromJson({
              'exerciseId': doc.id,
              ...data,
            });
          }
          return entries;
        });
  }

  @override
  Stream<List<SaveRecord>> watchSaveHistory(String uid) {
    return _firestore
        .collection(AppConstants.userAttemptsCollection(uid))
        .orderBy('attemptedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SaveRecord.fromJson(doc.id, doc.data()))
              // Filtered here rather than with a Firestore
              // where('type', '==', 'save'): combined with the orderBy above
              // that needs a composite index, and a student's attempt log is
              // small enough that filtering client-side costs nothing.
              .where((record) => record.type == 'save')
              .toList(),
        );
  }
}
