import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/models/appointment.dart';

Appointment _make({
  String id = 'a1',
  String therapistId = 't1',
  String patientId = 'p1',
  DateTime? dateTime,
  int durationMinutes = 60,
  AppointmentStatus status = AppointmentStatus.confirmed,
  AppointmentType? type,
  String? sessionType,
  String? notes,
  String? patientNotes,
  String? patientName,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final dt = dateTime ?? DateTime(2026, 6, 1, 10);
  return Appointment(
    id: id,
    therapistId: therapistId,
    patientId: patientId,
    dateTime: dt,
    durationMinutes: durationMinutes,
    status: status,
    type: type,
    sessionType: sessionType,
    notes: notes,
    patientNotes: patientNotes,
    patientName: patientName,
    createdAt: createdAt ?? DateTime(2026, 5, 1),
    updatedAt: updatedAt ?? DateTime(2026, 5, 1),
  );
}

void main() {
  group('AppointmentStatus.fromString', () {
    test('maps canonical values', () {
      expect(AppointmentStatus.fromString('pending'),
          AppointmentStatus.pending);
      expect(AppointmentStatus.fromString('confirmed'),
          AppointmentStatus.confirmed);
      expect(AppointmentStatus.fromString('cancelled'),
          AppointmentStatus.cancelled);
      expect(AppointmentStatus.fromString('completed'),
          AppointmentStatus.completed);
    });

    test('legacy "scheduled" folds into confirmed', () {
      expect(AppointmentStatus.fromString('scheduled'),
          AppointmentStatus.confirmed);
    });

    test('unknown / null defaults to pending', () {
      expect(AppointmentStatus.fromString(null), AppointmentStatus.pending);
      expect(AppointmentStatus.fromString('weird'), AppointmentStatus.pending);
      expect(AppointmentStatus.fromString(''), AppointmentStatus.pending);
    });

    test('toFirestore round-trips canonical values', () {
      for (final s in AppointmentStatus.values) {
        expect(AppointmentStatus.fromString(s.toFirestore()), s);
      }
    });
  });

  group('AppointmentType.fromString', () {
    test('parses presencial / virtual', () {
      expect(AppointmentType.fromString('presencial'),
          AppointmentType.presencial);
      expect(
          AppointmentType.fromString('virtual'), AppointmentType.virtual);
    });

    test('legacy / unknown values become null', () {
      expect(AppointmentType.fromString(null), isNull);
      expect(AppointmentType.fromString('something'), isNull);
    });
  });

  group('Appointment — derived fields', () {
    test('endTime adds durationMinutes', () {
      final a = _make(
        dateTime: DateTime(2026, 6, 1, 10),
        durationMinutes: 45,
      );
      expect(a.endTime, DateTime(2026, 6, 1, 10, 45));
    });

    test('isUpcoming true for future confirmed appointment', () {
      final a = _make(
        dateTime: DateTime.now().add(const Duration(days: 2)),
        status: AppointmentStatus.confirmed,
      );
      expect(a.isUpcoming, isTrue);
    });

    test('isUpcoming true for future pending appointment', () {
      final a = _make(
        dateTime: DateTime.now().add(const Duration(days: 2)),
        status: AppointmentStatus.pending,
      );
      expect(a.isUpcoming, isTrue);
    });

    test('isUpcoming false for cancelled even if future', () {
      final a = _make(
        dateTime: DateTime.now().add(const Duration(days: 2)),
        status: AppointmentStatus.cancelled,
      );
      expect(a.isUpcoming, isFalse);
    });

    test('isUpcoming false for completed', () {
      final a = _make(
        dateTime: DateTime.now().add(const Duration(days: 2)),
        status: AppointmentStatus.completed,
      );
      expect(a.isUpcoming, isFalse);
    });

    test('isUpcoming false for past appointment', () {
      final a = _make(
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        status: AppointmentStatus.confirmed,
      );
      expect(a.isUpcoming, isFalse);
    });

    test('isToday true when dateTime is today', () {
      final now = DateTime.now();
      final a = _make(
        dateTime: DateTime(now.year, now.month, now.day, 16),
      );
      expect(a.isToday, isTrue);
    });

    test('isToday false for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final a = _make(dateTime: tomorrow);
      expect(a.isToday, isFalse);
    });
  });

  group('Appointment.fromMap / toMap', () {
    test('round-trips full payload', () {
      final created = DateTime(2026, 5, 1, 12);
      final updated = DateTime(2026, 5, 2, 12);
      final a = _make(
        type: AppointmentType.virtual,
        sessionType: 'Evaluación',
        notes: 'thoughts',
        patientNotes: 'me duele la rodilla',
        patientName: 'Marco T.',
        createdAt: created,
        updatedAt: updated,
      );

      final map = a.toMap();
      final back = Appointment.fromMap(map, a.id);

      expect(back.id, a.id);
      expect(back.therapistId, a.therapistId);
      expect(back.patientId, a.patientId);
      expect(back.dateTime, a.dateTime);
      expect(back.durationMinutes, a.durationMinutes);
      expect(back.status, a.status);
      expect(back.type, a.type);
      expect(back.sessionType, a.sessionType);
      expect(back.notes, a.notes);
      expect(back.patientNotes, a.patientNotes);
      expect(back.patientName, a.patientName);
      expect(back.createdAt, a.createdAt);
      expect(back.updatedAt, a.updatedAt);
    });

    test('legacy doc with sessionType but no type is parsed cleanly', () {
      final map = {
        'therapistId': 't1',
        'patientId': 'p1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 1, 10)),
        'sessionType': 'Fortalecimiento',
        'status': 'scheduled',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        // no `type`, no `durationMinutes`, no `updatedAt`
      };
      final a = Appointment.fromMap(map, 'legacy1');
      expect(a.status, AppointmentStatus.confirmed,
          reason: 'scheduled folds into confirmed');
      expect(a.type, isNull);
      expect(a.durationMinutes, 60);
      expect(a.sessionType, 'Fortalecimiento');
      expect(a.updatedAt, a.createdAt,
          reason: 'when missing, updatedAt mirrors createdAt');
    });

    test('toCreateMap omits null optional fields', () {
      final a = _make();
      final map = a.toCreateMap();
      expect(map.containsKey('type'), isFalse);
      expect(map.containsKey('sessionType'), isFalse);
      expect(map.containsKey('notes'), isFalse);
      expect(map.containsKey('patientNotes'), isFalse);
    });
  });

  group('Appointment — copyWith / equality', () {
    test('copyWith overrides given fields and preserves the rest', () {
      final a = _make();
      final b = a.copyWith(status: AppointmentStatus.cancelled);
      expect(b.status, AppointmentStatus.cancelled);
      expect(b.id, a.id);
      expect(b.dateTime, a.dateTime);
    });

    test('equality is id-based', () {
      final a = _make(id: 'same');
      final b = _make(id: 'same', status: AppointmentStatus.cancelled);
      final c = _make(id: 'other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
