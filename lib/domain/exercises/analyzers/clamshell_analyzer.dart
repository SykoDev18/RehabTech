import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Side-lying clamshell — hip external rotation. Knees together at start;
/// top knee opens 30°-45° from bottom knee, hip stays still.
class ClamshellAnalyzer extends ExerciseAnalyzer {
  ClamshellAnalyzer() {
    repMachine = RepPhaseMachine(bottomThreshold: 5, topThreshold: 25);
  }

  @override
  String get exerciseId => 'clamshell';

  @override
  String get exerciseName => 'Apertura de cadera (almeja)';

  @override
  AngleRange get targetRange => const AngleRange(25, 50);

  double? _baselineKneeY;
  double? _baselineHipY;

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final lk = p.landmarks[PoseLandmarkType.leftKnee];
    final rk = p.landmarks[PoseLandmarkType.rightKnee];
    final lh = p.landmarks[PoseLandmarkType.leftHip];
    final rh = p.landmarks[PoseLandmarkType.rightHip];
    if (lk == null || rk == null || lh == null || rh == null) {
      return ExerciseFeedback.waitingSetup;
    }
    if (![lk, rk, lh, rh].every(AngleCalculator.isVisible)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Acuéstate de lado y muestra tu cadera y rodillas',
      );
    }

    // Approximate rotation by vertical separation between knees, normalised
    // to hip width. Higher knee = more open.
    _baselineKneeY ??= ((lk.y + rk.y) / 2).toDouble();
    _baselineHipY ??= ((lh.y + rh.y) / 2).toDouble();

    final hipWidth = (lh.x - rh.x).abs().clamp(1.0, 10000.0);
    final kneeGap = (lk.y - rk.y).abs();
    // Convert to a degree-like value for the rep machine: 0..60.
    final opening = (kneeGap / hipWidth * 30).clamp(0.0, 60.0);
    tickRep(opening);

    // Hip rolling-back check: avg hip Y shouldn't drift more than 30px from baseline.
    final currentHipY = (lh.y + rh.y) / 2;
    if ((currentHipY - _baselineHipY!).abs() > 30) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'No dejes que la cadera se eche atrás',
        measuredAngle: opening,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    if (opening < 20) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Abre un poco más manteniendo los pies juntos',
        measuredAngle: opening,
        jointName: 'cadera',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Buena apertura — ${opening.toStringAsFixed(0)}°',
      measuredAngle: opening,
      jointName: 'cadera',
      isRepCounting: justCountedRep,
    );
  }

  @override
  void reset() {
    super.reset();
    _baselineKneeY = null;
    _baselineHipY = null;
  }
}
