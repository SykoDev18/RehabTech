import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/pose_analysis/rep_phase_machine.dart';

void main() {
  group('RepPhaseMachine', () {
    test('counts one rep on full top→bottom→top cycle', () {
      var t = DateTime(2026);
      final m = RepPhaseMachine(
        bottomThreshold: 30,
        topThreshold: 90,
        now: () => t,
      );

      // Start at top.
      expect(m.update(95), isFalse);
      expect(m.phase, RepPhase.top);
      // Descending.
      expect(m.update(70), isFalse);
      expect(m.phase, RepPhase.descending);
      // Bottom.
      expect(m.update(20), isFalse);
      expect(m.phase, RepPhase.bottom);
      // Ascending.
      expect(m.update(60), isFalse);
      expect(m.phase, RepPhase.ascending);
      // Back to top → counts.
      t = t.add(const Duration(seconds: 2));
      expect(m.update(95), isTrue);
      expect(m.repCount, 1);
    });

    test('time gate prevents two reps within 500ms', () {
      var t = DateTime(2026);
      final m = RepPhaseMachine(
        bottomThreshold: 30,
        topThreshold: 90,
        now: () => t,
      );
      // First rep cycle, taking 2 seconds.
      m.update(95);
      m.update(20);
      m.update(60);
      t = t.add(const Duration(seconds: 2));
      expect(m.update(95), isTrue);
      expect(m.repCount, 1);

      // Second cycle within 500ms — should NOT count.
      m.update(20);
      m.update(60);
      t = t.add(const Duration(milliseconds: 500));
      expect(m.update(95), isFalse,
          reason: 'second rep within 500ms must be rejected by gate');
      expect(m.repCount, 1);
    });

    test('reset() returns to waiting and clears count', () {
      final m = RepPhaseMachine(bottomThreshold: 30, topThreshold: 90);
      m.update(95);
      m.update(20);
      m.update(60);
      m.update(95);
      m.reset();
      expect(m.phase, RepPhase.waiting);
      expect(m.repCount, 0);
    });
  });
}
