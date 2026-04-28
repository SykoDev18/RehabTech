/// Severity of feedback shown to the user during a session.
enum FeedbackLevel { good, warning, error }

/// Phase the analyzer is in for the current frame.
enum ExercisePhase { setup, active, hold, rest }

/// Inclusive [min, max] degree window for the key joint of an exercise.
class AngleRange {
  const AngleRange(this.min, this.max);

  final double min;
  final double max;

  bool contains(double angle) => angle >= min && angle <= max;

  /// Whether [angle] is within [tolerance] degrees of either boundary.
  bool nearEdge(double angle, {double tolerance = 15}) =>
      (angle - min).abs() <= tolerance || (angle - max).abs() <= tolerance;
}

class ExerciseFeedback {
  const ExerciseFeedback({
    required this.level,
    required this.message,
    this.measuredAngle,
    this.jointName,
    this.isRepCounting = false,
  });

  final FeedbackLevel level;
  final String message;
  final double? measuredAngle;
  final String? jointName;
  final bool isRepCounting;

  static const ExerciseFeedback waitingSetup = ExerciseFeedback(
    level: FeedbackLevel.warning,
    message: 'Posiciónate frente a la cámara',
  );
}
