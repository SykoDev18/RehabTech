import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Lateral shoulder abduction — arm raised to the side. Target: 0° (down)
/// to 90° (shoulder height). Elbow should stay nearly straight.
class ShoulderAbductionAnalyzer extends ExerciseAnalyzer {
  ShoulderAbductionAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 20, topThreshold: 80);
  }

  @override
  String get exerciseId => 'shoulder_abduction';

  @override
  String get exerciseName => 'Abducción de hombro';

  @override
  AngleRange get targetRange => const AngleRange(80, 100);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final hip = p.landmarks[PoseLandmarkType.rightHip];
    final shoulder = p.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = p.landmarks[PoseLandmarkType.rightElbow];
    final wrist = p.landmarks[PoseLandmarkType.rightWrist];
    if (hip == null || shoulder == null || elbow == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![hip, shoulder, elbow].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Muestra tu brazo y torso desde el frente',
      );
    }

    final abduction = AngleCalculator.calculateAngle(hip, shoulder, elbow);
    tickRep(abduction);

    // Elbow angle (shoulder-elbow-wrist) should stay near 180.
    if (wrist != null && AngleCalculator.isVisible(wrist)) {
      final elbowAngle = AngleCalculator.calculateAngle(shoulder, elbow, wrist);
      if (elbowAngle < 150) {
        return ExerciseFeedback(
          level: FeedbackLevel.warning,
          message: 'Mantén el codo casi recto',
          measuredAngle: abduction,
          jointName: 'hombro',
          isRepCounting: justCountedRep,
        );
      }
    }

    if (abduction < 60) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Intenta llegar a la altura del hombro',
        measuredAngle: abduction,
        jointName: 'hombro',
        isRepCounting: justCountedRep,
      );
    }
    if (abduction > 90) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: '¡Excelente movilidad!',
        measuredAngle: abduction,
        jointName: 'hombro',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Subiendo… ${abduction.toStringAsFixed(0)}°',
      measuredAngle: abduction,
      jointName: 'hombro',
      isRepCounting: justCountedRep,
    );
  }
}
