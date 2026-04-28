import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Knee extension (seated). Knee bends from ~80° (start, bent) to ~170° (top, extended).
/// Rep counted on transition into the extended top.
class KneeExtensionAnalyzer extends ExerciseAnalyzer {
  KneeExtensionAnalyzer() {
    repMachine = RepPhaseMachine(
      bottomThreshold: 80,
      topThreshold: 160,
    );
  }

  @override
  String get exerciseId => 'knee_extension';

  @override
  String get exerciseName => 'Extensión de rodilla';

  @override
  AngleRange get targetRange => const AngleRange(160, 180);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final lh = p.landmarks[PoseLandmarkType.leftHip];
    final lk = p.landmarks[PoseLandmarkType.leftKnee];
    final la = p.landmarks[PoseLandmarkType.leftAnkle];
    final rh = p.landmarks[PoseLandmarkType.rightHip];
    final rk = p.landmarks[PoseLandmarkType.rightKnee];
    final ra = p.landmarks[PoseLandmarkType.rightAnkle];
    if (lh == null ||
        lk == null ||
        la == null ||
        rh == null ||
        rk == null ||
        ra == null) {
      return ExerciseFeedback.waitingSetup;
    }
    final visible = [lh, lk, la, rh, rk, ra].every(AngleCalculator.isVisible);
    if (!visible) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Siéntate de lado para que se vea la pierna entera',
      );
    }

    final symmetric = AngleCalculator.symmetricAngle(lh, lk, la, rh, rk, ra)!;
    final asym = AngleCalculator.asymmetry(lh, lk, la, rh, rk, ra)!;
    tickRep(symmetric);

    if (asym > 15) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Nota: hay diferencia entre tus piernas',
        measuredAngle: symmetric,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    if (symmetric < 100) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Sube más la pierna para completar el movimiento',
        measuredAngle: symmetric,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    if (symmetric >= 170) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: '¡Perfecto! Extiende completamente',
        measuredAngle: symmetric,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Extendiendo… ${symmetric.toStringAsFixed(0)}°',
      measuredAngle: symmetric,
      jointName: 'rodilla',
      isRepCounting: justCountedRep,
    );
  }
}
