import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:rehabtech/domain/pose_analysis/angle_calculator.dart';

import '../../_helpers/pose_fixtures.dart';

void main() {
  group('AngleCalculator.calculateAngle', () {
    test('right angle: A=(0,0), V=(0,1), C=(1,1) → 90°', () {
      final a = mark(PoseLandmarkType.leftShoulder, 0, 0);
      final v = mark(PoseLandmarkType.leftElbow, 0, 1);
      final c = mark(PoseLandmarkType.leftWrist, 1, 1);
      expect(AngleCalculator.calculateAngle(a, v, c), closeTo(90, 0.01));
    });

    test('straight line returns ~180°', () {
      final a = mark(PoseLandmarkType.leftShoulder, 0, 0);
      final v = mark(PoseLandmarkType.leftElbow, 1, 0);
      final c = mark(PoseLandmarkType.leftWrist, 2, 0);
      expect(AngleCalculator.calculateAngle(a, v, c), closeTo(180, 0.01));
    });

    test('overlap returns ~0°', () {
      final a = mark(PoseLandmarkType.leftShoulder, 1, 0);
      final v = mark(PoseLandmarkType.leftElbow, 0, 0);
      final c = mark(PoseLandmarkType.leftWrist, 1, 0);
      expect(AngleCalculator.calculateAngle(a, v, c), closeTo(0, 0.01));
    });
  });

  group('AngleCalculator.isVisible', () {
    test('confidence 0.3 below default threshold → false', () {
      final l = mark(PoseLandmarkType.leftKnee, 0, 0, likelihood: 0.3);
      expect(AngleCalculator.isVisible(l), isFalse);
    });

    test('confidence 0.7 above threshold → true', () {
      final l = mark(PoseLandmarkType.leftKnee, 0, 0, likelihood: 0.7);
      expect(AngleCalculator.isVisible(l), isTrue);
    });
  });

  group('AngleCalculator.symmetricAngle', () {
    test('returns null when one side is below confidence', () {
      final lh = mark(PoseLandmarkType.leftHip, 0, 0);
      final lk = mark(PoseLandmarkType.leftKnee, 0, 1);
      final la = mark(PoseLandmarkType.leftAnkle, 1, 1);
      final rh = mark(PoseLandmarkType.rightHip, 0, 0, likelihood: 0.2);
      final rk = mark(PoseLandmarkType.rightKnee, 0, 1);
      final ra = mark(PoseLandmarkType.rightAnkle, 1, 1);
      expect(
        AngleCalculator.symmetricAngle(lh, lk, la, rh, rk, ra),
        isNull,
      );
    });

    test('averages left + right angles', () {
      final lh = mark(PoseLandmarkType.leftHip, 0, 0);
      final lk = mark(PoseLandmarkType.leftKnee, 0, 1);
      final la = mark(PoseLandmarkType.leftAnkle, 1, 1); // 90°
      final rh = mark(PoseLandmarkType.rightHip, 0, 0);
      final rk = mark(PoseLandmarkType.rightKnee, 1, 0);
      final ra = mark(PoseLandmarkType.rightAnkle, 2, 0); // 180°
      final avg = AngleCalculator.symmetricAngle(lh, lk, la, rh, rk, ra)!;
      expect(avg, closeTo(135, 0.01));
    });
  });
}
