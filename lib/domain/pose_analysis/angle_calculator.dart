import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Pure math + visibility helpers for pose landmarks. No ML Kit calls.
class AngleCalculator {
  static const double defaultMinConfidence = 0.5;

  /// Angle at [vertex] formed by [pointA]->[vertex]->[pointC], in degrees [0, 180].
  static double calculateAngle(
    PoseLandmark pointA,
    PoseLandmark vertex,
    PoseLandmark pointC,
  ) {
    final radians = math.atan2(pointC.y - vertex.y, pointC.x - vertex.x) -
        math.atan2(pointA.y - vertex.y, pointA.x - vertex.x);
    var degrees = radians * 180 / math.pi;
    degrees = degrees.abs();
    if (degrees > 180) degrees = 360 - degrees;
    return degrees;
  }

  static bool isVisible(
    PoseLandmark landmark, {
    double minConfidence = defaultMinConfidence,
  }) {
    return landmark.likelihood >= minConfidence;
  }

  /// Average left/right of the same joint for symmetric exercises.
  /// Returns null if either side is below confidence.
  static double? symmetricAngle(
    PoseLandmark leftA,
    PoseLandmark leftVertex,
    PoseLandmark leftC,
    PoseLandmark rightA,
    PoseLandmark rightVertex,
    PoseLandmark rightC, {
    double minConfidence = defaultMinConfidence,
  }) {
    final leftVisible = [leftA, leftVertex, leftC]
        .every((l) => isVisible(l, minConfidence: minConfidence));
    final rightVisible = [rightA, rightVertex, rightC]
        .every((l) => isVisible(l, minConfidence: minConfidence));
    if (!leftVisible || !rightVisible) return null;
    final left = calculateAngle(leftA, leftVertex, leftC);
    final right = calculateAngle(rightA, rightVertex, rightC);
    return (left + right) / 2;
  }

  /// Absolute difference between left and right side. Used for asymmetry warnings.
  static double? asymmetry(
    PoseLandmark leftA,
    PoseLandmark leftVertex,
    PoseLandmark leftC,
    PoseLandmark rightA,
    PoseLandmark rightVertex,
    PoseLandmark rightC,
  ) {
    final left = calculateAngle(leftA, leftVertex, leftC);
    final right = calculateAngle(rightA, rightVertex, rightC);
    return (left - right).abs();
  }

  /// Average likelihood of [landmarks] (skipping nulls). 0 if all null.
  static double averageConfidence(Iterable<PoseLandmark?> landmarks) {
    final present = landmarks.whereType<PoseLandmark>().toList();
    if (present.isEmpty) return 0;
    return present.map((l) => l.likelihood).reduce((a, b) => a + b) /
        present.length;
  }
}
