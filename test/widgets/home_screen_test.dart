// Tests adjacent to HomeScreen.
//
// HomeScreen itself can't be widget-tested without significant refactoring:
// it depends on `ProgressService()` (a singleton initialised in main.dart),
// the `intl` 'es_ES' locale (loaded by `initializeDateFormatting`), and the
// `StreakWidget` which reads from FirebaseAuth + Firestore. Calling
// `pumpWidget(HomeScreen(...))` blows up before any assertion can run.
//
// Instead we cover the INPUT MODEL the screen depends on — `allExercises`
// from lib/models/exercise.dart — which it indexes by day-of-week to pick
// "today's exercise". If that list shrinks to empty or loses required fields
// HomeScreen breaks; the assertions below pin that contract down.

import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/models/exercise.dart';

void main() {
  group('allExercises catalogue (HomeScreen input contract)', () {
    test('catalogue is non-empty so weekday indexing is safe', () {
      // HomeScreen does `(weekday - 1) % allExercises.length` — if length
      // were 0 this would throw IntegerDivisionByZeroException.
      expect(allExercises, isNotEmpty);
      expect(allExercises.length, greaterThanOrEqualTo(1));
    });

    test('every exercise has a non-empty id and title', () {
      for (final e in allExercises) {
        expect(e.id, isNotEmpty, reason: 'exercise id must be set');
        expect(e.title, isNotEmpty, reason: 'exercise title must be set');
      }
    });

    test('every exercise has at least one instruction step', () {
      for (final e in allExercises) {
        expect(e.instructions, isNotEmpty,
            reason: 'exercise "${e.title}" needs at least one instruction');
      }
    });

    test('series and reps are positive integers', () {
      for (final e in allExercises) {
        expect(e.series, greaterThan(0));
        expect(e.reps, greaterThan(0));
      }
    });

    test('exercise ids are unique across the catalogue', () {
      final ids = allExercises.map((e) => e.id).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, equals(ids.length),
          reason: 'duplicate exercise ids would break id-based deep links');
    });

    test('weekday indexing yields a valid exercise for every day', () {
      // Mirrors HomeScreen.todayExercise: (weekday - 1) % length.
      for (var weekday = 1; weekday <= 7; weekday++) {
        final idx = (weekday - 1) % allExercises.length;
        expect(idx, greaterThanOrEqualTo(0));
        expect(idx, lessThan(allExercises.length));
        // Should not throw.
        final picked = allExercises[idx];
        expect(picked.title, isNotEmpty);
      }
    });
  });
}
