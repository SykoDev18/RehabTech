import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/data/repositories/firestore_appointment_repository.dart';
import 'package:rehabtech/domain/exceptions/appointment_exception.dart';
import 'package:rehabtech/domain/models/appointment.dart';

void main() {
  late FakeFirebaseFirestore fake;
  late FirestoreAppointmentRepository repo;

  Appointment build({
    String id = '',
    String therapistId = 't1',
    String patientId = 'p1',
    DateTime? dateTime,
    AppointmentStatus status = AppointmentStatus.pending,
    AppointmentType? type,
  }) {
    return Appointment(
      id: id,
      therapistId: therapistId,
      patientId: patientId,
      dateTime: dateTime ?? DateTime.now().add(const Duration(days: 2)),
      durationMinutes: 60,
      status: status,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
    repo = FirestoreAppointmentRepository(firestore: fake);
  });

  group('createAppointment', () {
    test('writes correct fields and returns the new id', () async {
      final id = await repo.createAppointment(build(
        type: AppointmentType.virtual,
      ));
      final doc = await fake.collection('appointments').doc(id).get();
      final data = doc.data()!;
      expect(data['therapistId'], 't1');
      expect(data['patientId'], 'p1');
      expect(data['status'], 'pending');
      expect(data['type'], 'virtual');
      expect(data['durationMinutes'], 60);
      expect(data['dateTime'], isA<Timestamp>());
    });

    test('rejects non-pending creates', () async {
      expect(
        () => repo.createAppointment(
          build(status: AppointmentStatus.confirmed),
        ),
        throwsA(isA<AppointmentException>()),
      );
    });
  });

  group('watchNextAppointment', () {
    test('returns null when there are no upcoming appointments', () async {
      final stream = repo.watchNextAppointment('p1');
      final first = await stream.first;
      expect(first, isNull);
    });

    test('returns soonest future pending appointment', () async {
      final near = DateTime.now().add(const Duration(days: 1));
      final far = DateTime.now().add(const Duration(days: 7));
      await repo.createAppointment(build(dateTime: far));
      await repo.createAppointment(build(dateTime: near));

      final got = await repo.watchNextAppointment('p1').first;
      expect(got, isNotNull);
      // The returned doc should be the one closer to now.
      expect(
        got!.dateTime.difference(near).inMinutes.abs() <
            got.dateTime.difference(far).inMinutes.abs(),
        isTrue,
      );
    });

    test('skips cancelled appointments', () async {
      final id = await repo.createAppointment(
        build(dateTime: DateTime.now().add(const Duration(days: 1))),
      );
      await repo.cancelAppointment(id, cancellerId: 'p1');

      final got = await repo.watchNextAppointment('p1').first;
      expect(got, isNull);
    });

    test('ignores past appointments via the dateTime filter', () async {
      // We cannot insert a past pending appointment via createAppointment
      // because the model requires future-friendly state, but we can
      // write directly to verify the query.
      final past = DateTime.now().subtract(const Duration(days: 1));
      await fake.collection('appointments').add({
        'therapistId': 't1',
        'patientId': 'p1',
        'dateTime': Timestamp.fromDate(past),
        'durationMinutes': 60,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(past),
        'updatedAt': Timestamp.fromDate(past),
      });

      final got = await repo.watchNextAppointment('p1').first;
      expect(got, isNull);
    });
  });

  group('confirmAppointment', () {
    test('flips status to confirmed', () async {
      final id = await repo.createAppointment(build());
      await repo.confirmAppointment(id);

      final doc = await fake.collection('appointments').doc(id).get();
      expect(doc.data()!['status'], 'confirmed');
    });
  });

  group('cancelAppointment', () {
    test('writes status, cancellerId and reason', () async {
      final id = await repo.createAppointment(build());
      await repo.cancelAppointment(id,
          cancellerId: 't1', reason: 'agenda llena');

      final data = (await fake.collection('appointments').doc(id).get())
          .data()!;
      expect(data['status'], 'cancelled');
      expect(data['cancellerId'], 't1');
      expect(data['cancellationReason'], 'agenda llena');
    });

    test('omits reason field when null', () async {
      final id = await repo.createAppointment(build());
      await repo.cancelAppointment(id, cancellerId: 'p1');

      final data = (await fake.collection('appointments').doc(id).get())
          .data()!;
      expect(data.containsKey('cancellationReason'), isFalse);
    });
  });

  group('completeAppointment', () {
    test('flips status and writes notes', () async {
      final id = await repo.createAppointment(build());
      await repo.completeAppointment(id, notes: 'Buen progreso');

      final data = (await fake.collection('appointments').doc(id).get())
          .data()!;
      expect(data['status'], 'completed');
      expect(data['notes'], 'Buen progreso');
    });
  });

  group('updateAppointment', () {
    test('merges arbitrary fields', () async {
      final id = await repo.createAppointment(build());
      await repo.updateAppointment(id, {
        'sessionType': 'Reevaluación',
      });
      final data = (await fake.collection('appointments').doc(id).get())
          .data()!;
      expect(data['sessionType'], 'Reevaluación');
    });
  });

  group('watchPatientAppointments', () {
    test('returns docs scoped to the patient', () async {
      await repo.createAppointment(build());
      await repo.createAppointment(build(patientId: 'someone-else'));

      final list = await repo.watchPatientAppointments('p1').first;
      expect(list, hasLength(1));
      expect(list.single.patientId, 'p1');
    });
  });
}
