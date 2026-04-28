import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Builders that produce real ML-Kit `Pose` / `PoseLandmark` instances
/// from raw x/y/likelihood values, so analyzers can be unit-tested
/// without a camera.
PoseLandmark mark(
  PoseLandmarkType t,
  double x,
  double y, {
  double likelihood = 0.9,
}) =>
    PoseLandmark(type: t, x: x, y: y, z: 0, likelihood: likelihood);

Pose poseFromMarks(Iterable<PoseLandmark> marks) =>
    Pose(landmarks: {for (final m in marks) m.type: m});
