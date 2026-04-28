import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Glute bridge from supine. Hip extends to form a straight line
/// shoulder-hip-knee. Rep counted on top transition.
class GluteBridgeAnalyzer extends ExerciseAnalyzer {
  GluteBridgeAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 110, topThreshold: 165);
  }

  @override
  String get exerciseId => 'glute_bridge';

  @override
  String get exerciseName => 'Puente de glúteos';

  @override
  AngleRange get targetRange => const AngleRange(165, 180);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final shoulder = p.landmarks[PoseLandmarkType.rightShoulder];
    final hip = p.landmarks[PoseLandmarkType.rightHip];
    final knee = p.landmarks[PoseLandmarkType.rightKnee];
    final lk = p.landmarks[PoseLandmarkType.leftKnee];
    if (shoulder == null || hip == null || knee == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![shoulder, hip, knee].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Acuéstate boca arriba y muestra tu costado',
      );
    }

    // Shoulder-hip-knee approaches 180 at top of bridge.
    final line = AngleCalculator.calculateAngle(shoulder, hip, knee);
    tickRep(line);

    // Knee tracking: if both knees visible, distance between them shouldn't shrink.
    if (lk != null && AngleCalculator.isVisible(lk)) {
      final kneeGap = (lk.x - knee.x).abs();
      if (kneeGap < 30) {
        return ExerciseFeedback(
          level: FeedbackLevel.warning,
          message: 'Mantén las rodillas alineadas con los pies',
          measuredAngle: line,
          jointName: 'cadera',
          isRepCounting: justCountedRep,
        );
      }
    }

    if (line < 140) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Aprieta los glúteos y sube más las caderas',
        measuredAngle: line,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    if (line >= 165) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: 'Mantén arriba 2 segundos antes de bajar',
        measuredAngle: line,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Subiendo… ${line.toStringAsFixed(0)}°',
      measuredAngle: line,
      jointName: 'cadera',
      isRepCounting: justCountedRep,
    );
  }
}
