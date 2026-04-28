import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';

/// Wall sit / sentadilla en pared. Timed hold at ~90° knee flexion.
/// Does not count reps — caller drives a timer instead.
class WallSquatAnalyzer extends ExerciseAnalyzer {
  WallSquatAnalyzer();

  @override
  String get exerciseId => 'wall_squat';

  @override
  String get exerciseName => 'Sentadilla en pared';

  @override
  AngleRange get targetRange => const AngleRange(80, 100);

  @override
  bool get countsReps => false;

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
    final ls = p.landmarks[PoseLandmarkType.leftShoulder];
    if (lh == null ||
        lk == null ||
        la == null ||
        rh == null ||
        rk == null ||
        ra == null) {
      return ExerciseFeedback.waitingSetup;
    }

    final knee = AngleCalculator.symmetricAngle(lh, lk, la, rh, rk, ra);
    if (knee == null) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Ponte de lado para que se vean tus piernas',
      );
    }

    if (knee > 110) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Baja un poco más, apunta a 90°',
        measuredAngle: knee,
        jointName: 'rodilla',
      );
    }
    if (knee < 70) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Sube un poco, no bajes tanto',
        measuredAngle: knee,
        jointName: 'rodilla',
      );
    }

    // Hip-flexion sanity: if shoulder visible, hip should also be ~90°.
    if (ls != null && AngleCalculator.isVisible(ls)) {
      final hip = AngleCalculator.calculateAngle(ls, lh, lk);
      if ((hip - 90).abs() > 25) {
        return ExerciseFeedback(
          level: FeedbackLevel.warning,
          message: 'Mantén las caderas también en 90°',
          measuredAngle: knee,
          jointName: 'rodilla',
        );
      }
    }

    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Mantén la posición — ${knee.toStringAsFixed(0)}°',
      measuredAngle: knee,
      jointName: 'rodilla',
    );
  }
}
