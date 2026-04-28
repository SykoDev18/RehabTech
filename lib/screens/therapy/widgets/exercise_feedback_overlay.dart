import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../domain/pose_analysis/exercise_feedback.dart';
import '../../../domain/pose_analysis/pose_detection_quality.dart';

/// Heads-up overlay showing rep count, set progress, current feedback message,
/// and a small detection-quality pill. Rendered above the skeleton.
class ExerciseFeedbackOverlay extends StatelessWidget {
  const ExerciseFeedbackOverlay({
    super.key,
    required this.repsCompleted,
    required this.targetReps,
    required this.currentSet,
    required this.totalSets,
    required this.detectionQuality,
    this.feedback,
    this.holdSecondsRemaining,
  });

  final int repsCompleted;
  final int? targetReps;
  final int currentSet;
  final int totalSets;
  final PoseDetectionQuality detectionQuality;
  final ExerciseFeedback? feedback;
  final int? holdSecondsRemaining;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CounterBadge(
                  reps: repsCompleted,
                  target: targetReps,
                  hold: holdSecondsRemaining,
                ),
                const Spacer(),
                _SetBadge(set: currentSet, total: totalSets),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DetectionPill(quality: detectionQuality),
          ),
          if (feedback != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _FeedbackBar(feedback: feedback!),
            ),
        ],
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.reps, required this.target, required this.hold});
  final int reps;
  final int? target;
  final int? hold;

  @override
  Widget build(BuildContext context) {
    final big = hold != null
        ? '${hold!}s'
        : (target != null ? '$reps/$target' : '$reps');
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              big,
              key: ValueKey(big),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge({required this.set, required this.total});
  final int set;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Set $set de $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionPill extends StatelessWidget {
  const _DetectionPill({required this.quality});
  final PoseDetectionQuality quality;

  Color get _color {
    switch (quality) {
      case PoseDetectionQuality.excellent:
        return const Color(0xFF22C55E);
      case PoseDetectionQuality.good:
        return const Color(0xFFEAB308);
      case PoseDetectionQuality.poor:
        return const Color(0xFFF97316);
      case PoseDetectionQuality.lost:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              quality.label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.feedback});
  final ExerciseFeedback feedback;

  Color get _bg {
    switch (feedback.level) {
      case FeedbackLevel.good:
        return const Color(0xFF16A34A);
      case FeedbackLevel.warning:
        return const Color(0xFFF59E0B);
      case FeedbackLevel.error:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        feedback.message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
