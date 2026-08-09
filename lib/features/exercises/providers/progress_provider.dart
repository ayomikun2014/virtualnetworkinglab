import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/grading_repository.dart';

/// State Management Provider exposing a student's per-exercise progress
/// (attempt counts and pass state) to the dashboard and level screens.
///
/// Backed by a live Firestore stream, so passing a level updates the cards
/// behind the canvas without the student needing to pull to refresh.
class ProgressProvider extends ChangeNotifier {
  final IGradingRepository _repository;
  StreamSubscription<Map<String, ExerciseProgress>>? _subscription;

  ProgressProvider({IGradingRepository? repository})
    : _repository = repository ?? FirebaseGradingRepository();

  Map<String, ExerciseProgress> _progressByExerciseId = {};
  String? _watchedUid;
  String? _errorMessage;

  Map<String, ExerciseProgress> get progressByExerciseId =>
      _progressByExerciseId;
  String? get errorMessage => _errorMessage;

  /// Progress for one exercise, or a zeroed record if it's never been tried.
  ExerciseProgress progressFor(String exerciseId) =>
      _progressByExerciseId[exerciseId] ??
      ExerciseProgress(exerciseId: exerciseId);

  /// Subscribes to [uid]'s progress. Safe to call repeatedly from `build` —
  /// re-subscribing to the same uid is a no-op, so this doesn't churn a
  /// Firestore listener on every rebuild.
  void watchProgress(String uid) {
    if (_watchedUid == uid) return;
    _watchedUid = uid;
    _errorMessage = null;

    _subscription?.cancel();
    _subscription = _repository
        .watchProgress(uid)
        .listen(
          (progress) {
            _progressByExerciseId = progress;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load progress: $error';
            // Also to the console: Firestore index errors embed a direct
            // "create this index" link the on-screen banner can't linkify.
            debugPrint('watchProgress failed: $error');
            notifyListeners();
          },
        );
  }

  /// Drops the subscription — call on sign-out so one student's progress
  /// can't linger into the next session on a shared machine.
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _watchedUid = null;
    _progressByExerciseId = {};
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
