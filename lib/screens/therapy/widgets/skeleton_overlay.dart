import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../domain/pose_analysis/exercise_feedback.dart';

/// Painter that draws an ML-Kit skeleton over the camera preview.
/// - Lines connect main joints (shoulder→elbow→wrist, hip→knee→ankle, shoulder↔hip).
/// - Color reflects per-landmark confidence + how close [measuredAngle] is to [targetRange].
/// - Low-confidence landmarks render as dashed grey.
class SkeletonOverlay extends StatelessWidget {
  const SkeletonOverlay({
    super.key,
    required this.poses,
    required this.imageSize,
    required this.previewSize,
    this.isMirrored = true,
    this.targetRange,
    this.measuredAngle,
    this.measuredJointName,
  });

  final List<Pose>? poses;
  final Size imageSize;
  final Size previewSize;
  final bool isMirrored;
  final AngleRange? targetRange;
  final double? measuredAngle;
  final String? measuredJointName;

  @override
  Widget build(BuildContext context) {
    if (poses == null || poses!.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SkeletonPainter(
        pose: poses!.first,
        imageSize: imageSize,
        previewSize: previewSize,
        isMirrored: isMirrored,
        targetRange: targetRange,
        measuredAngle: measuredAngle,
        measuredJointName: measuredJointName,
      ),
      size: Size.infinite,
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.previewSize,
    required this.isMirrored,
    required this.targetRange,
    required this.measuredAngle,
    required this.measuredJointName,
  });

  final Pose pose;
  final Size imageSize;
  final Size previewSize;
  final bool isMirrored;
  final AngleRange? targetRange;
  final double? measuredAngle;
  final String? measuredJointName;

  static const double _minConfidence = 0.5;
  static const Color _good = Color(0xFF4CAF50);
  static const Color _warn = Color(0xFFFF9800);
  static const Color _bad = Color(0xFFF44336);
  static const Color _dim = Color(0xFF9E9E9E);

  static const List<List<PoseLandmarkType>> _connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  ];

  static const List<PoseLandmarkType> _keyJoints = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  static const List<PoseLandmarkType> _faceJoints = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftEye,
    PoseLandmarkType.rightEye,
    PoseLandmarkType.leftEar,
    PoseLandmarkType.rightEar,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;

    Offset project(PoseLandmark l) {
      final x = isMirrored ? imageSize.width - l.x : l.x;
      return Offset(dx + x * scale, dy + l.y * scale);
    }

    final connColor = _colorForCurrent();

    for (final pair in _connections) {
      final a = pose.landmarks[pair[0]];
      final b = pose.landmarks[pair[1]];
      if (a == null || b == null) continue;
      final lowConf = a.likelihood < _minConfidence || b.likelihood < _minConfidence;
      final paint = Paint()
        ..color = lowConf ? _dim : connColor
        ..strokeWidth = lowConf ? 2 : 3
        ..style = PaintingStyle.stroke;
      if (lowConf) {
        _drawDashedLine(canvas, project(a), project(b), paint);
      } else {
        canvas.drawLine(project(a), project(b), paint);
      }
    }

    for (final t in _keyJoints) {
      final l = pose.landmarks[t];
      if (l == null) continue;
      final c = l.likelihood < _minConfidence ? _dim : connColor;
      canvas.drawCircle(project(l), 6, Paint()..color = c);
    }
    for (final t in _faceJoints) {
      final l = pose.landmarks[t];
      if (l == null || l.likelihood < _minConfidence) continue;
      canvas.drawCircle(project(l), 3, Paint()..color = Colors.white70);
    }

    if (measuredAngle != null && measuredJointName != null) {
      final anchor = _anchorForJointName(measuredJointName!);
      if (anchor != null) {
        final l = pose.landmarks[anchor];
        if (l != null && l.likelihood >= _minConfidence) {
          _drawAngleLabel(canvas, project(l), measuredAngle!);
        }
      }
    }
  }

  Color _colorForCurrent() {
    if (measuredAngle == null || targetRange == null) return _good;
    if (targetRange!.contains(measuredAngle!)) return _good;
    if (targetRange!.nearEdge(measuredAngle!)) return _warn;
    return _bad;
  }

  PoseLandmarkType? _anchorForJointName(String name) {
    switch (name.toLowerCase()) {
      case 'rodilla':
        return PoseLandmarkType.rightKnee;
      case 'cadera':
        return PoseLandmarkType.rightHip;
      case 'hombro':
        return PoseLandmarkType.rightShoulder;
      case 'codo':
        return PoseLandmarkType.rightElbow;
      case 'tobillo':
        return PoseLandmarkType.rightAnkle;
    }
    return null;
  }

  void _drawAngleLabel(Canvas canvas, Offset center, double angle) {
    final text = '${angle.toStringAsFixed(0)}°';
    final span = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          Shadow(color: Colors.black, offset: Offset(-1, -1), blurRadius: 2),
        ],
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, center.translate(10, -tp.height - 4));
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * (drawn + dashLen).clamp(0.0, total);
      canvas.drawLine(start, end, paint);
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) {
    return old.pose != pose ||
        old.measuredAngle != measuredAngle ||
        old.targetRange != targetRange;
  }
}
