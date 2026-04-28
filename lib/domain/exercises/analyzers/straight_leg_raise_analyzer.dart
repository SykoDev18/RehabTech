import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Straight leg raise — patient lying down, hip flexion to 45°-60° while
/// knee stays extended. Rep counted on top transition.
class StraightLegRaiseAnalyzer extends ExerciseAnalyzer {
  StraightLegRaiseAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 15, topThreshold: 45);
  }

  @override
  String get exerciseId => 'straight_leg_raise';

  @override
  String get exerciseName => 'Elevación de pierna recta';

  @override
  AngleRange get targetRange => const AngleRange(45, 70);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final shoulder = p.landmarks[PoseLandmarkType.rightShoulder];
    final hip = p.landmarks[PoseLandmarkType.rightHip];
    final knee = p.landmarks[PoseLandmarkType.rightKnee];
    final ankle = p.landmarks[PoseLandmarkType.rightAnkle];
    if (shoulder == null || hip == null || knee == null || ankle == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![shoulder, hip, knee, ankle].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Acuéstate y muestra tu cuerpo completo',
      );
    }

    // Hip flexion: angle at hip between shoulder and knee. When lying flat,
    // shoulder-hip-knee ≈ 180°. Raised leg → angle decreases toward 90°.
    final shoulderHipKnee = AngleCalculator.calculateAngle(shoulder, hip, knee);
    final hipFlexion = (180 - shoulderHipKnee).clamp(0.0, 180.0);

    // Knee should remain straight (>= 165°)
    final kneeStraight = AngleCalculator.calculateAngle(hip, knee, ankle);

    tickRep(hipFlexion);

    if (kneeStraight < 165) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Mantén la rodilla estirada',
        measuredAngle: hipFlexion,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    if (hipFlexion < 30) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Sube más la pierna',
        measuredAngle: hipFlexion,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    if (hipFlexion >= 60) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: '¡Excelente! Mantén esa altura',
        measuredAngle: hipFlexion,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Subiendo… ${hipFlexion.toStringAsFixed(0)}°',
      measuredAngle: hipFlexion,
      jointName: 'cadera',
      isRepCounting: justCountedRep,
    );
  }
}
