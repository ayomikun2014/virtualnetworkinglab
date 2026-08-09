import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/grading_repository.dart';

/// State Management Provider for a student's Submissions tab — the combined
/// activity log of Check Connection attempts and plain canvas saves.
class SaveHistoryProvider extends ChangeNotifier {
  final IGradingRepository _repository;
  StreamSubscription<List<SaveRecord>>? _subscription;

  SaveHistoryProvider({IGradingRepository? repository})
    : _repository = repository ?? FirebaseGradingRepository();

  List<SaveRecord> _history = [];
  String? _watchedUid;
  bool _isLoading = false;
  String? _errorMessage;

  List<SaveRecord> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Safe to call repeatedly from `build`/`didChangeDependencies` — re-
  /// subscribing to the same uid is a no-op.
  void watchSaveHistory(String uid) {
    if (_watchedUid == uid) return;
    _watchedUid = uid;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.watchSaveHistory(uid).listen(
      (records) {
        _history = records;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load submission history: $error';
        debugPrint('watchSaveHistory failed: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _watchedUid = null;
    _history = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
