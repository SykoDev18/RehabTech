import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';

/// Single leg stance — measure trunk sway via shoulder midpoint stability.
/// Timed (no reps). Lower sway = better balance.
class SingleLegStanceAnalyzer extends ExerciseAnalyzer {
  SingleLegStanceAnalyzer();

  @override
  String get exerciseId => 'single_leg_stance';

  @override
  String get exerciseName => 'Equilibrio en una pierna';

  @override
  AngleRange get targetRange => const AngleRange(0, 1);

  @override
  bool get countsReps => false;

  // Rolling window of the last N shoulder-midpoint x positions.
  final List<double> _swayWindow = [];
  static const int _windowSize = 30;

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final ls = p.landmarks[PoseLandmarkType.leftShoulder];
    final rs = p.landmarks[PoseLandmarkType.rightShoulder];
    final lk = p.landmarks[PoseLandmarkType.leftKnee];
    final rk = p.landmarks[PoseLandmarkType.rightKnee];
    if (ls == null || rs == null) return ExerciseFeedback.waitingSetup;
    if (!AngleCalculator.isVisible(ls) || !AngleCalculator.isVisible(rs)) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Muestra el cuerpo completo de frente',
      );
    }

    // Sanity: verify one knee is clearly higher (raised).
    String? legNote;
    if (lk != null && rk != null && AngleCalculator.isVisible(lk) && AngleCalculator.isVisible(rk)) {
      final dy = (lk.y - rk.y).abs();
      if (dy < 40) {
        legNote = 'Levanta una pierna del suelo';
      }
    }

    final midX = (ls.x + rs.x) / 2;
    _swayWindow.add(midX);
    if (_swayWindow.length > _windowSize) _swayWindow.removeAt(0);

    if (legNote != null) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: legNote,
        measuredAngle: 0,
      );
    }

    if (_swayWindow.length < _windowSize / 2) {
      return const ExerciseFeedback(
        level: FeedbackLevel.good,
        message: 'Encuentra un punto fijo y respira',
      );
    }
    final mean = _swayWindow.reduce((a, b) => a + b) / _swayWindow.length;
    final variance = _swayWindow
            .map((v) => math.pow(v - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        _swayWindow.length;
    final stdev = math.sqrt(variance);

    if (stdev > 18) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Encuentra un punto fijo para mirar y mantén la calma',
        measuredAngle: stdev,
      );
    }
    if (stdev > 8) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: 'Buen equilibrio — sigue así',
        measuredAngle: stdev,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: '¡Equilibrio excelente!',
      measuredAngle: stdev,
    );
  }

  @override
  void reset() {
    super.reset();
    _swayWindow.clear();
  }
}
