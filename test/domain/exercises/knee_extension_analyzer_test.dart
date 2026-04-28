import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:rehabtech/domain/exercises/analyzers/knee_extension_analyzer.dart';
import 'package:rehabtech/domain/pose_analysis/exercise_feedback.dart';

import '../../_helpers/pose_fixtures.dart';

/// Build a pose with both legs at the same angle (180° = extended).
/// `bend` is degrees off-straight: 0 = fully extended, 90 = bent right angle.
Pose poseWithBothKnees(double bend) {
  // Hip at (0,0), knee at (0,1), ankle position depends on bend angle.
  // We want angle hip-knee-ankle = (180 - bend).
  // Place ankle so that vector knee→ankle makes the desired angle with knee→hip.
  // For simplicity build via two Cartesian endpoints that yield the angle.
  final marks = <PoseLandmark>[
    mark(PoseLandmarkType.leftHip, 0, 0),
    mark(PoseLandmarkType.leftKnee, 0, 100),
    // bend=0 → ankle at (0,200), bend=90 → ankle at (100,100)
    mark(
      PoseLandmarkType.leftAnkle,
      100 * (bend / 90),
      100 + 100 * (1 - bend / 90),
    ),
    mark(PoseLandmarkType.rightHip, 0, 0),
    mark(PoseLandmarkType.rightKnee, 0, 100),
    mark(
      PoseLandmarkType.rightAnkle,
      100 * (bend / 90),
      100 + 100 * (1 - bend / 90),
    ),
  ];
  return poseFromMarks(marks);
}

void main() {
  group('KneeExtensionAnalyzer', () {
    test('returns waitingSetup when no poses', () {
      final a = KneeExtensionAnalyzer();
      expect(a.analyze([], ExercisePhase.active), ExerciseFeedback.waitingSetup);
    });

    test('extended legs (~180°) emit a "good" feedback message', () {
      final a = KneeExtensionAnalyzer();
      final fb = a.analyze([poseWithBothKnees(0)], ExercisePhase.active)!;
      expect(fb.level, FeedbackLevel.good);
    });

    test('bent at 90° prompts user to lift more', () {
      final a = KneeExtensionAnalyzer();
      final fb = a.analyze([poseWithBothKnees(90)], ExercisePhase.active)!;
      expect(fb.level, FeedbackLevel.warning);
      expect(fb.message, contains('Sube más'));
    });

    test('asymmetric legs trigger asymmetry warning', () {
      final a = KneeExtensionAnalyzer();
      final marks = <PoseLandmark>[
        mark(PoseLandmarkType.leftHip, 0, 0),
        mark(PoseLandmarkType.leftKnee, 0, 100),
        mark(PoseLandmarkType.leftAnkle, 0, 200), // 180°
        mark(PoseLandmarkType.rightHip, 0, 0),
        mark(PoseLandmarkType.rightKnee, 0, 100),
        mark(PoseLandmarkType.rightAnkle, 100, 100), // 90°
      ];
      final fb = a.analyze([poseFromMarks(marks)], ExercisePhase.active)!;
      expect(fb.level, FeedbackLevel.warning);
      expect(fb.message, contains('diferencia'));
    });
  });
}
