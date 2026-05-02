import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/entities/routine_entity.dart';

RoutineExerciseEntity _ex({
  String id = 'e1',
  String name = 'Sentadilla',
  int series = 3,
  int reps = 10,
  int? durationSeconds,
  int order = 0,
}) =>
    RoutineExerciseEntity(
      id: id,
      name: name,
      series: series,
      reps: reps,
      durationSeconds: durationSeconds,
      order: order,
    );

RoutineEntity _routine({
  String id = 'r1',
  String name = 'Rutina semanal',
  String patientId = 'p1',
  String patientName = 'Marco',
  String therapistId = 't1',
  List<RoutineExerciseEntity>? exercises,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    RoutineEntity(
      id: id,
      name: name,
      patientId: patientId,
      patientName: patientName,
      therapistId: therapistId,
      exercises: exercises ?? const [],
      createdAt: createdAt ?? DateTime(2026, 5, 1),
      updatedAt: updatedAt,
    );

void main() {
  group('RoutineEntity — exerciseCount', () {
    test('returns 0 when exercises list is empty', () {
      expect(_routine(exercises: const []).exerciseCount, equals(0));
    });

    test('returns the length of the exercises list', () {
      final r = _routine(exercises: [
        _ex(id: 'a'),
        _ex(id: 'b'),
        _ex(id: 'c'),
      ]);
      expect(r.exerciseCount, equals(3));
    });
  });

  group('RoutineEntity — copyWith / equality', () {
    test('copyWith overrides only the fields that are passed', () {
      final original = _routine(name: 'Original');
      final renamed = original.copyWith(name: 'Renombrada');

      expect(renamed.name, equals('Renombrada'));
      expect(renamed.id, equals(original.id));
      expect(renamed.patientId, equals(original.patientId));
      expect(renamed.therapistId, equals(original.therapistId));
      expect(renamed.createdAt, equals(original.createdAt));
    });

    test('copyWith updates exercises list', () {
      final empty = _routine(exercises: const []);
      final withTwo = empty.copyWith(exercises: [_ex(id: 'a'), _ex(id: 'b')]);

      expect(empty.exerciseCount, equals(0));
      expect(withTwo.exerciseCount, equals(2));
      expect(empty.id, equals(withTwo.id));
    });

    test('copyWith updates updatedAt independently of createdAt', () {
      final r = _routine(
        createdAt: DateTime(2026, 5, 1),
      );
      final updated = r.copyWith(updatedAt: DateTime(2026, 5, 2));

      expect(updated.createdAt, equals(DateTime(2026, 5, 1)));
      expect(updated.updatedAt, equals(DateTime(2026, 5, 2)));
    });

    test('equality is based on id only', () {
      final a = _routine(id: 'same', name: 'A');
      final b = _routine(id: 'same', name: 'B');
      final c = _routine(id: 'other', name: 'A');

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('RoutineExerciseEntity — formattedSetsReps', () {
    test('formats series and reps with × separator', () {
      expect(_ex(series: 3, reps: 10).formattedSetsReps,
          equals('3 series × 10 reps'));
      expect(_ex(series: 1, reps: 1).formattedSetsReps,
          equals('1 series × 1 reps'));
    });
  });

  group('RoutineExerciseEntity — formattedDuration', () {
    test('returns null when durationSeconds is null', () {
      expect(_ex().formattedDuration, isNull);
    });

    test('formats whole minutes only when seconds == 0', () {
      expect(_ex(durationSeconds: 60).formattedDuration, equals('1m'));
      expect(_ex(durationSeconds: 180).formattedDuration, equals('3m'));
    });

    test('formats minutes and seconds when both are non-zero', () {
      expect(_ex(durationSeconds: 75).formattedDuration, equals('1m 15s'));
      expect(_ex(durationSeconds: 125).formattedDuration, equals('2m 5s'));
    });

    test('formats whole seconds when below one minute', () {
      expect(_ex(durationSeconds: 30).formattedDuration, equals('30s'));
      expect(_ex(durationSeconds: 1).formattedDuration, equals('1s'));
    });

    test('zero seconds returns "0s"', () {
      expect(_ex(durationSeconds: 0).formattedDuration, equals('0s'));
    });
  });

  group('RoutineExerciseEntity — copyWith / equality', () {
    test('copyWith preserves untouched fields', () {
      final original = _ex(name: 'Sentadilla', series: 3, reps: 10);
      final updated = original.copyWith(reps: 12);

      expect(updated.reps, equals(12));
      expect(updated.series, equals(3));
      expect(updated.name, equals('Sentadilla'));
      expect(updated.id, equals(original.id));
    });

    test('equality is based on id only', () {
      final a = _ex(id: 'same', name: 'A');
      final b = _ex(id: 'same', name: 'B');
      final c = _ex(id: 'other', name: 'A');

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('RoutineEntity — exercise array integrity', () {
    test('passing a list with mixed orders preserves them', () {
      final r = _routine(exercises: [
        _ex(id: 'a', order: 0),
        _ex(id: 'b', order: 1),
        _ex(id: 'c', order: 2),
      ]);
      expect(r.exercises.map((e) => e.order).toList(), equals([0, 1, 2]));
    });

    test('exercises default to empty when not provided', () {
      final r = RoutineEntity(
        id: 'r1',
        name: 'X',
        patientId: 'p',
        patientName: 'n',
        therapistId: 't',
        createdAt: DateTime(2026, 5, 1),
      );
      expect(r.exercises, isEmpty);
      expect(r.exerciseCount, equals(0));
    });
  });
}
