import '../pose_analysis/exercise_analyzer.dart';
import '../pose_analysis/exercise_feedback.dart';
import '../pose_analysis/pose_detection_quality.dart';

/// Sealed hierarchy of states the therapy session can be in.
sealed class SessionState {
  const SessionState();
}

final class SessionIdle extends SessionState {
  const SessionIdle();
}

final class SessionCountdown extends SessionState {
  const SessionCountdown(this.secondsRemaining);
  final int secondsRemaining;
}

final class SessionActive extends SessionState {
  const SessionActive({
    required this.currentExercise,
    required this.currentSet,
    required this.totalSets,
    required this.repsCompleted,
    required this.targetReps,
    required this.detectionQuality,
    this.latestFeedback,
    this.holdSecondsRemaining,
  });

  final ExerciseAnalyzer currentExercise;
  final int currentSet;
  final int totalSets;
  final int repsCompleted;
  final int? targetReps;
  final ExerciseFeedback? latestFeedback;
  final PoseDetectionQuality detectionQuality;
  final int? holdSecondsRemaining;

  SessionActive copyWith({
    int? currentSet,
    int? repsCompleted,
    ExerciseFeedback? latestFeedback,
    PoseDetectionQuality? detectionQuality,
    int? holdSecondsRemaining,
    bool clearHold = false,
  }) {
    return SessionActive(
      currentExercise: currentExercise,
      currentSet: currentSet ?? this.currentSet,
      totalSets: totalSets,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      targetReps: targetReps,
      detectionQuality: detectionQuality ?? this.detectionQuality,
      latestFeedback: latestFeedback ?? this.latestFeedback,
      holdSecondsRemaining:
          clearHold ? null : (holdSecondsRemaining ?? this.holdSecondsRemaining),
    );
  }
}

final class SessionResting extends SessionState {
  const SessionResting({
    required this.secondsRemaining,
    required this.nextExerciseName,
  });
  final int secondsRemaining;
  final String nextExerciseName;
}

final class SessionCompleted extends SessionState {
  const SessionCompleted({
    required this.totalReps,
    required this.sessionDuration,
    required this.averageFormScore,
  });
  final int totalReps;
  final Duration sessionDuration;
  final double averageFormScore;
}
