import 'dart:async';

import 'package:flutter/foundation.dart';

import '../pose_analysis/exercise_analyzer.dart';
import '../pose_analysis/exercise_feedback.dart';
import '../pose_analysis/pose_detection_quality.dart';
import 'session_state.dart';

/// Drives the therapy session through the [SessionState] hierarchy.
///
/// Owns the countdown / hold / rest timers. Stateless about poses — the
/// screen feeds it pose-quality + analyzer ticks via [recordRepIfNeeded] and
/// [recordFeedback]. Calls [notifyListeners] on every state change.
class SessionController extends ChangeNotifier {
  SessionController({
    required this.analyzer,
    required this.totalSets,
    this.targetReps,
    this.holdDurationSeconds,
    this.restSeconds = 30,
    this.countdownSeconds = 3,
    String? nextExerciseName,
    DateTime Function() now = _defaultNow,
  })  : _nextExerciseName = nextExerciseName ?? analyzer.exerciseName,
        _now = now,
        assert(targetReps != null || holdDurationSeconds != null,
            'Either targetReps or holdDurationSeconds must be set');

  final ExerciseAnalyzer analyzer;
  final int totalSets;
  final int? targetReps;
  final int? holdDurationSeconds;
  final int restSeconds;
  final int countdownSeconds;
  final String _nextExerciseName;
  final DateTime Function() _now;

  SessionState _state = const SessionIdle();
  SessionState get state => _state;

  Timer? _ticker;
  DateTime? _startedAt;
  int _goodFeedbackCount = 0;
  int _totalFeedbackCount = 0;
  int _totalReps = 0;
  int _currentSet = 1;
  int _holdRemaining = 0;
  PoseDetectionQuality _quality = PoseDetectionQuality.poor;
  ExerciseFeedback? _latestFeedback;

  void start() {
    _startedAt = _now();
    _currentSet = 1;
    _totalReps = 0;
    _goodFeedbackCount = 0;
    _totalFeedbackCount = 0;
    analyzer.reset();
    _beginCountdown();
  }

  void _beginCountdown() {
    int remaining = countdownSeconds;
    _state = SessionCountdown(remaining);
    notifyListeners();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining -= 1;
      if (remaining <= 0) {
        t.cancel();
        _enterActive();
      } else {
        _state = SessionCountdown(remaining);
        notifyListeners();
      }
    });
  }

  void _enterActive() {
    _holdRemaining = holdDurationSeconds ?? 0;
    _state = SessionActive(
      currentExercise: analyzer,
      currentSet: _currentSet,
      totalSets: totalSets,
      repsCompleted: 0,
      targetReps: targetReps,
      detectionQuality: _quality,
      latestFeedback: _latestFeedback,
      holdSecondsRemaining: holdDurationSeconds != null ? _holdRemaining : null,
    );
    notifyListeners();
    if (holdDurationSeconds != null) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
        _holdRemaining -= 1;
        if (_holdRemaining <= 0) {
          t.cancel();
          _completeSet();
        } else if (_state is SessionActive) {
          _state = (_state as SessionActive).copyWith(
            holdSecondsRemaining: _holdRemaining,
          );
          notifyListeners();
        }
      });
    }
  }

  /// Called by the screen when the analyzer has a new feedback for this frame.
  void recordFeedback(ExerciseFeedback fb, PoseDetectionQuality quality) {
    _latestFeedback = fb;
    _quality = quality;
    _totalFeedbackCount += 1;
    if (fb.level == FeedbackLevel.good) _goodFeedbackCount += 1;
    if (_state is SessionActive) {
      _state = (_state as SessionActive).copyWith(
        latestFeedback: fb,
        detectionQuality: quality,
      );
      notifyListeners();
    }
  }

  /// Called by the screen when the analyzer counted a rep.
  void recordRep() {
    if (_state is! SessionActive) return;
    if (targetReps == null) return;
    final active = _state as SessionActive;
    final next = active.repsCompleted + 1;
    _totalReps += 1;
    if (next >= active.targetReps!) {
      _completeSet();
    } else {
      _state = active.copyWith(repsCompleted: next);
      notifyListeners();
    }
  }

  void _completeSet() {
    if (_currentSet >= totalSets) {
      _finish();
      return;
    }
    _currentSet += 1;
    _beginRest();
  }

  void _beginRest() {
    int remaining = restSeconds;
    _state = SessionResting(
      secondsRemaining: remaining,
      nextExerciseName: _nextExerciseName,
    );
    notifyListeners();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining -= 1;
      if (remaining <= 0) {
        t.cancel();
        analyzer.reset();
        _enterActive();
      } else {
        _state = SessionResting(
          secondsRemaining: remaining,
          nextExerciseName: _nextExerciseName,
        );
        notifyListeners();
      }
    });
  }

  void skipRest() {
    if (_state is! SessionResting) return;
    _ticker?.cancel();
    analyzer.reset();
    _enterActive();
  }

  void _finish() {
    _ticker?.cancel();
    final duration = _startedAt == null
        ? Duration.zero
        : _now().difference(_startedAt!);
    final score =
        _totalFeedbackCount == 0 ? 0.0 : _goodFeedbackCount / _totalFeedbackCount;
    _state = SessionCompleted(
      totalReps: _totalReps,
      sessionDuration: duration,
      averageFormScore: score,
    );
    notifyListeners();
  }

  void cancel() {
    _ticker?.cancel();
    _state = const SessionIdle();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static DateTime _defaultNow() => DateTime.now();
}
