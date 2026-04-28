import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Shoulder flexion — front raise. Arm goes from at-side (~0°) to overhead.
class ShoulderFlexionAnalyzer extends ExerciseAnalyzer {
  ShoulderFlexionAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 25, topThreshold: 80);
  }

  @override
  String get exerciseId => 'shoulder_flexion';

  @override
  String get exerciseName => 'Flexión de hombro';

  @override
  AngleRange get targetRange => const AngleRange(80, 180);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final hip = p.landmarks[PoseLandmarkType.rightHip];
    final shoulder = p.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = p.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = p.landmarks[PoseLandmarkType.leftShoulder];
    if (hip == null || shoulder == null || elbow == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![hip, shoulder, elbow].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Muestra tu torso y brazo completo',
      );
    }

    // Shoulder flexion: angle at shoulder between hip and elbow.
    final flexion = AngleCalculator.calculateAngle(hip, shoulder, elbow);
    tickRep(flexion);

    // Trunk lean check: if shoulder line not roughly horizontal, user is leaning back.
    if (leftShoulder != null && AngleCalculator.isVisible(leftShoulder)) {
      final dy = (leftShoulder.y - shoulder.y).abs();
      if (dy > 60) {
        return ExerciseFeedback(
          level: FeedbackLevel.warning,
          message: 'Mantén el tronco recto, no te inclines',
          measuredAngle: flexion,
          jointName: 'hombro',
          isRepCounting: justCountedRep,
        );
      }
    }

    if (flexion < 90) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: '¡Muy bien para comenzar!',
        measuredAngle: flexion,
        jointName: 'hombro',
        isRepCounting: justCountedRep,
      );
    }
    if (flexion > 150) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: '¡Excelente rango de movimiento!',
        measuredAngle: flexion,
        jointName: 'hombro',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Subiendo… ${flexion.toStringAsFixed(0)}°',
      measuredAngle: flexion,
      jointName: 'hombro',
      isRepCounting: justCountedRep,
    );
  }
}
