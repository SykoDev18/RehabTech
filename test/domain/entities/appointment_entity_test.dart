import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/entities/appointment_entity.dart';

AppointmentEntity _make({
  String id = 'a1',
  String patientId = 'p1',
  String patientName = 'Marco',
  String therapistId = 't1',
  DateTime? dateTime,
  String sessionType = 'Evaluación',
  String? notes,
  String status = 'scheduled',
  DateTime? createdAt,
}) {
  return AppointmentEntity(
    id: id,
    patientId: patientId,
    patientName: patientName,
    therapistId: therapistId,
    dateTime: dateTime ?? DateTime(2026, 5, 10, 14, 30),
    sessionType: sessionType,
    notes: notes,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 5, 1),
  );
}

void main() {
  group('AppointmentEntity — status flags', () {
    test('isScheduled is true only when status == "scheduled"', () {
      expect(_make(status: 'scheduled').isScheduled, isTrue);
      expect(_make(status: 'completed').isScheduled, isFalse);
      expect(_make(status: 'cancelled').isScheduled, isFalse);
    });

    test('isCompleted is true only when status == "completed"', () {
      expect(_make(status: 'completed').isCompleted, isTrue);
      expect(_make(status: 'scheduled').isCompleted, isFalse);
      expect(_make(status: 'cancelled').isCompleted, isFalse);
    });

    test('isCancelled is true only when status == "cancelled"', () {
      expect(_make(status: 'cancelled').isCancelled, isTrue);
      expect(_make(status: 'scheduled').isCancelled, isFalse);
      expect(_make(status: 'completed').isCancelled, isFalse);
    });

    test('flags are mutually exclusive across the canonical states', () {
      for (final s in ['scheduled', 'completed', 'cancelled']) {
        final a = _make(status: s);
        final flags = [a.isScheduled, a.isCompleted, a.isCancelled];
        expect(flags.where((f) => f).length, equals(1),
            reason: 'exactly one flag must be true for status "$s"');
      }
    });

    test('default status is "scheduled" when omitted', () {
      final a = AppointmentEntity(
        id: 'x',
        patientId: 'p',
        patientName: 'n',
        therapistId: 't',
        dateTime: DateTime(2026, 6, 1),
        sessionType: 'Eval',
        createdAt: DateTime(2026, 5, 30),
      );
      expect(a.status, equals('scheduled'));
      expect(a.isScheduled, isTrue);
    });
  });

  group('AppointmentEntity — temporal getters', () {
    test('isPast is true when dateTime is in the past', () {
      final past = _make(
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(past.isPast, isTrue);
    });

    test('isPast is false when dateTime is in the future', () {
      final future = _make(
        dateTime: DateTime.now().add(const Duration(days: 1)),
      );
      expect(future.isPast, isFalse);
    });

    test('isToday is true for an appointment scheduled today', () {
      final now = DateTime.now();
      final today = _make(
        dateTime: DateTime(now.year, now.month, now.day, 12, 0),
      );
      expect(today.isToday, isTrue);
    });

    test('isToday is false for tomorrow and yesterday', () {
      final now = DateTime.now();
      final tomorrow = _make(
        dateTime: DateTime(now.year, now.month, now.day, 12, 0)
            .add(const Duration(days: 1)),
      );
      final yesterday = _make(
        dateTime: DateTime(now.year, now.month, now.day, 12, 0)
            .subtract(const Duration(days: 1)),
      );
      expect(tomorrow.isToday, isFalse);
      expect(yesterday.isToday, isFalse);
    });
  });

  group('AppointmentEntity — formatted strings', () {
    test('formattedTime zero-pads hours and minutes', () {
      final a = _make(dateTime: DateTime(2026, 5, 10, 9, 5));
      expect(a.formattedTime, equals('09:05'));
    });

    test('formattedTime preserves two-digit values', () {
      final a = _make(dateTime: DateTime(2026, 5, 10, 14, 30));
      expect(a.formattedTime, equals('14:30'));
    });

    test('formattedDate uses the Spanish month abbreviation', () {
      expect(_make(dateTime: DateTime(2026, 1, 15)).formattedDate,
          equals('15 ene'));
      expect(_make(dateTime: DateTime(2026, 5, 1)).formattedDate,
          equals('1 may'));
      expect(_make(dateTime: DateTime(2026, 12, 31)).formattedDate,
          equals('31 dic'));
    });

    test('formattedDate covers all 12 month abbreviations', () {
      const expected = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      for (var m = 1; m <= 12; m++) {
        final a = _make(dateTime: DateTime(2026, m, 5));
        expect(a.formattedDate, equals('5 ${expected[m - 1]}'));
      }
    });
  });

  group('AppointmentEntity — copyWith / equality', () {
    test('copyWith preserves untouched fields and overrides given ones', () {
      final original = _make();
      final cancelled = original.copyWith(status: 'cancelled');

      expect(cancelled.status, equals('cancelled'));
      expect(cancelled.id, equals(original.id));
      expect(cancelled.patientId, equals(original.patientId));
      expect(cancelled.dateTime, equals(original.dateTime));
      expect(cancelled.createdAt, equals(original.createdAt));
    });

    test('copyWith allows status transition scheduled → completed → cancelled',
        () {
      final scheduled = _make(status: 'scheduled');
      final completed = scheduled.copyWith(status: 'completed');
      final cancelled = completed.copyWith(status: 'cancelled');

      expect(scheduled.isScheduled, isTrue);
      expect(completed.isCompleted, isTrue);
      expect(cancelled.isCancelled, isTrue);
      // All share the same id — they are the same logical appointment.
      expect(scheduled.id, equals(completed.id));
      expect(completed.id, equals(cancelled.id));
    });

    test('equality is based on id only', () {
      final a = _make(id: 'same', status: 'scheduled');
      final b = _make(id: 'same', status: 'cancelled');
      final c = _make(id: 'other', status: 'scheduled');

      expect(a == b, isTrue,
          reason: 'same id ⇒ equal even if other fields differ');
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith with no args returns an instance equal to the original', () {
      final a = _make();
      final b = a.copyWith();
      expect(b, equals(a));
      expect(identical(a, b), isFalse);
    });
  });
}
