import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Standing hamstring curl. Knee bends from ~0° (straight, hanging) up
/// to >80° (curl). Hip should stay relatively still.
class HamstringCurlAnalyzer extends ExerciseAnalyzer {
  HamstringCurlAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 30, topThreshold: 80);
  }

  double? _hipBaselineY;

  @override
  String get exerciseId => 'hamstring_curl';

  @override
  String get exerciseName => 'Curl de isquiotibiales';

  @override
  AngleRange get targetRange => const AngleRange(80, 130);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final hip = p.landmarks[PoseLandmarkType.rightHip];
    final knee = p.landmarks[PoseLandmarkType.rightKnee];
    final ankle = p.landmarks[PoseLandmarkType.rightAnkle];
    if (hip == null || knee == null || ankle == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![hip, knee, ankle].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Ponte de lado para que se vea tu pierna',
      );
    }

    // Knee bend angle: when standing straight, hip-knee-ankle ≈ 180°.
    // When curling, the angle (hip-knee-ankle) decreases. We invert so
    // bottomThreshold/topThreshold semantics match other exercises.
    final straight = AngleCalculator.calculateAngle(hip, knee, ankle);
    final curl = (180 - straight).clamp(0.0, 180.0);
    tickRep(curl);

    // Hip stillness check: store baseline on first frame, warn if drift > 8% of frame.
    _hipBaselineY ??= hip.y;
    final hipDrift = (hip.y - _hipBaselineY!).abs();

    if (hipDrift > 80) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Mantén la cadera quieta',
        measuredAngle: curl,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    if (curl < 50) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Intenta doblar más la rodilla',
        measuredAngle: curl,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: '¡Buen curl! ${curl.toStringAsFixed(0)}°',
      measuredAngle: curl,
      jointName: 'rodilla',
      isRepCounting: justCountedRep,
    );
  }

  @override
  void reset() {
    super.reset();
    _hipBaselineY = null;
  }
}
