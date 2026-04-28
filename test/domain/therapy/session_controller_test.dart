import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/exercises/analyzers/knee_extension_analyzer.dart';
import 'package:rehabtech/domain/pose_analysis/exercise_feedback.dart';
import 'package:rehabtech/domain/pose_analysis/pose_detection_quality.dart';
import 'package:rehabtech/domain/therapy/session_controller.dart';
import 'package:rehabtech/domain/therapy/session_state.dart';

void main() {
  group('SessionController (rep-based)', () {
    test('idle → countdown → active', () {
      fakeAsync((async) {
        final c = SessionController(
          analyzer: KneeExtensionAnalyzer(),
          totalSets: 2,
          targetReps: 3,
          countdownSeconds: 3,
        );
        expect(c.state, isA<SessionIdle>());
        c.start();
        expect(c.state, isA<SessionCountdown>());
        async.elapse(const Duration(seconds: 3));
        expect(c.state, isA<SessionActive>());
        c.dispose();
      });
    });

    test('completing target reps moves to resting', () {
      fakeAsync((async) {
        final c = SessionController(
          analyzer: KneeExtensionAnalyzer(),
          totalSets: 2,
          targetReps: 2,
          countdownSeconds: 1,
          restSeconds: 5,
        );
        c.start();
        async.elapse(const Duration(seconds: 1));
        expect(c.state, isA<SessionActive>());
        c.recordRep();
        c.recordRep();
        expect(c.state, isA<SessionResting>());
        async.elapse(const Duration(seconds: 5));
        expect(c.state, isA<SessionActive>(),
            reason: 'after rest, second set should begin');
        c.dispose();
      });
    });

    test('finishing all sets emits SessionCompleted with form score', () {
      fakeAsync((async) {
        final c = SessionController(
          analyzer: KneeExtensionAnalyzer(),
          totalSets: 1,
          targetReps: 1,
          countdownSeconds: 1,
        );
        c.start();
        async.elapse(const Duration(seconds: 1));
        c.recordFeedback(
          const ExerciseFeedback(level: FeedbackLevel.good, message: 'ok'),
          PoseDetectionQuality.excellent,
        );
        c.recordRep();
        expect(c.state, isA<SessionCompleted>());
        final completed = c.state as SessionCompleted;
        expect(completed.totalReps, 1);
        expect(completed.averageFormScore, 1.0);
        c.dispose();
      });
    });
  });

  group('SessionController (timed hold)', () {
    test('hold timer ticks down and completes the set', () {
      fakeAsync((async) {
        final c = SessionController(
          analyzer: KneeExtensionAnalyzer(),
          totalSets: 1,
          holdDurationSeconds: 3,
          countdownSeconds: 1,
        );
        c.start();
        async.elapse(const Duration(seconds: 1));
        expect(c.state, isA<SessionActive>());
        async.elapse(const Duration(seconds: 3));
        expect(c.state, isA<SessionCompleted>());
        c.dispose();
      });
    });
  });
}
