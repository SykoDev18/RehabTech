import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'angle_calculator.dart';
import 'exercise_feedback.dart';
import 'rep_phase_machine.dart';

/// Base class for all exercise-specific pose analyzers.
///
/// Concrete subclasses inspect [Pose] landmarks for a specific exercise,
/// compute angles via [AngleCalculator], and (when [countsReps]) feed a
/// [RepPhaseMachine] to count full-range-of-motion repetitions.
abstract class ExerciseAnalyzer {
  ExerciseAnalyzer();

  String get exerciseId;
  String get exerciseName;
  AngleRange get targetRange;

  /// Whether this exercise counts reps. Timed holds (wall sit, pendulum)
  /// override to false.
  bool get countsReps => true;

  /// Returns null when the analyzer should not surface anything new for
  /// this frame. Returns [ExerciseFeedback.waitingSetup] when no usable
  /// pose was found.
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase);

  /// True when [tickRep] just transitioned the rep machine into a
  /// counted state on the latest call.
  bool get justCountedRep => _justCountedRep;

  /// Current rep count (0 when this exercise does not count reps).
  int get repCount => repMachine?.repCount ?? 0;

  /// Concrete analyzers construct this in their constructor body if they
  /// count reps.
  RepPhaseMachine? repMachine;

  bool _justCountedRep = false;

  /// Helper: feeds [angle] into [repMachine] and updates [justCountedRep].
  void tickRep(double angle) {
    _justCountedRep = repMachine?.update(angle) ?? false;
  }

  void reset() {
    repMachine?.reset();
    _justCountedRep = false;
  }

  /// Re-export so subclasses don't need a second import.
  static double angle(PoseLandmark a, PoseLandmark v, PoseLandmark c) =>
      AngleCalculator.calculateAngle(a, v, c);
}
