import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';

/// Codman's pendulum — gentle exercise. Arm hangs and traces small circles.
/// Timed (60s), no rep counting. Feedback is mostly confirmatory.
class PendulumAnalyzer extends ExerciseAnalyzer {
  PendulumAnalyzer();

  @override
  String get exerciseId => 'pendulum';

  @override
  String get exerciseName => 'Péndulo de Codman';

  @override
  AngleRange get targetRange => const AngleRange(0, 30);

  @override
  bool get countsReps => false;

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final shoulder = p.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = p.landmarks[PoseLandmarkType.rightElbow];
    final wrist = p.landmarks[PoseLandmarkType.rightWrist];
    if (shoulder == null || elbow == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![shoulder, elbow].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Muestra el hombro y brazo',
      );
    }

    // If hand is high relative to shoulder, user is using muscle effort.
    if (wrist != null && AngleCalculator.isVisible(wrist)) {
      final hangAngle = AngleCalculator.calculateAngle(shoulder, elbow, wrist);
      if (hangAngle < 140) {
        return const ExerciseFeedback(
          level: FeedbackLevel.warning,
          message: 'Deja que el brazo cuelgue con gravedad — no hagas fuerza',
        );
      }
    }

    return const ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Movimiento suave en círculos — relájate',
    );
  }
}
