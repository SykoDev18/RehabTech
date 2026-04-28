import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Heel raises — calf strengthening. ML Kit doesn't track ground, so we
/// proxy via vertical movement of the ankle vs a baseline.
class HeelRaiseAnalyzer extends ExerciseAnalyzer {
  HeelRaiseAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 5, topThreshold: 30);
  }

  @override
  String get exerciseId => 'heel_raise';

  @override
  String get exerciseName => 'Elevación de talones';

  @override
  AngleRange get targetRange => const AngleRange(30, 60);

  double? _baselineAnkleY;
  DateTime? _lastRepAt;

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final ankle = p.landmarks[PoseLandmarkType.rightAnkle];
    final knee = p.landmarks[PoseLandmarkType.rightKnee];
    if (ankle == null || knee == null) return ExerciseFeedback.waitingSetup;
    if (![ankle, knee].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Muestra tus piernas y pies de frente',
      );
    }

    _baselineAnkleY ??= ankle.y;
    // Higher in image = smaller y. Rise = baseline - current (positive when up).
    final rise = (_baselineAnkleY! - ankle.y).clamp(0.0, 200.0);
    tickRep(rise);

    // Pace check: too-fast successive reps trigger "más despacio".
    if (justCountedRep) {
      final now = DateTime.now();
      if (_lastRepAt != null && now.difference(_lastRepAt!).inMilliseconds < 900) {
        _lastRepAt = now;
        return ExerciseFeedback(
          level: FeedbackLevel.warning,
          message: 'Hazlo más despacio, controlado',
          measuredAngle: rise,
          jointName: 'tobillo',
          isRepCounting: true,
        );
      }
      _lastRepAt = now;
    }

    if (rise < 15) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Sube más en la punta del pie',
        measuredAngle: rise,
        jointName: 'tobillo',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Elevando — ${rise.toStringAsFixed(0)}',
      measuredAngle: rise,
      jointName: 'tobillo',
      isRepCounting: justCountedRep,
    );
  }

  @override
  void reset() {
    super.reset();
    _baselineAnkleY = null;
    _lastRepAt = null;
  }
}
