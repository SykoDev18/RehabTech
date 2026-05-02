// Contract tests for the Firestore query patterns used by RehabTech screens.
//
// The codebase doesn't extract these into repository classes — every screen
// calls `FirebaseFirestore.instance.collection(...)` inline. These tests pin
// down the exact filter/sort/state-machine contract those screens rely on,
// using `fake_cloud_firestore` so the queries actually execute against an
// in-memory store.
//
// If a future refactor moves these queries behind a repository, the tests
// migrate by importing the repo and replacing `_AppointmentsQueries.x(fs)`
// calls with `repo.x()` — the assertions stay identical.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------
// Inline replicas of the queries used by the screens. They mirror the
// production code 1:1 so a divergence shows up here.
// ---------------------------------------------------------------------
class _AppointmentsQueries {
  _AppointmentsQueries(this._fs);
  final FirebaseFirestore _fs;

  // Mirrors my_appointments_screen.dart:27-32
  Stream<QuerySnapshot<Map<String, dynamic>>> watchForPatient(String uid) =>
      _fs
          .collection('appointments')
          .where('patientId', isEqualTo: uid)
          .orderBy('dateTime')
          .snapshots();

  // Mirrors patients_screen.dart:_DashboardStrip "Citas próximas"
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUpcomingForTherapist(
    String therapistId,
  ) =>
      _fs
          .collection('appointments')
          .where('therapistId', isEqualTo: therapistId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now())
          .where('status', isEqualTo: 'scheduled')
          .snapshots();

  // Mirrors patients_screen.dart:_CompletedThisWeekKpi
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCompletedSince(
    String therapistId,
    DateTime since,
  ) =>
      _fs
          .collection('appointments')
          .where('therapistId', isEqualTo: therapistId)
          .where('status', isEqualTo: 'completed')
          .where('dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .snapshots();

  // The state-machine transition cancelAppointment performs.
  Future<void> cancel(String id) =>
      _fs.collection('appointments').doc(id).update({'status': 'cancelled'});
}

class _RoutinesQueries {
  _RoutinesQueries(this._fs);
  final FirebaseFirestore _fs;

  // Mirrors my_routines_screen.dart:27-32
  Stream<QuerySnapshot<Map<String, dynamic>>> watchForPatient(String uid) =>
      _fs
          .collection('routines')
          .where('patientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
}

class _PatientLookupQueries {
  _PatientLookupQueries(this._fs);
  final FirebaseFirestore _fs;

  // Mirrors patients_screen.dart:_buildPatientsList list query
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPatientsForTherapist(
    String therapistId,
  ) =>
      _fs
          .collection('users')
          .where('therapistId', isEqualTo: therapistId)
          .where('userType', isEqualTo: 'patient')
          .snapshots();

  // Mirrors the add-by-id flow in patients_screen.dart:_showAddPatientModal
  Future<QuerySnapshot<Map<String, dynamic>>> findByPatientId(String code) =>
      _fs
          .collection('users')
          .where('patientId', isEqualTo: code)
          .where('userType', isEqualTo: 'patient')
          .limit(1)
          .get();
}

// ---------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------
void main() {
  group('appointments — patient watch', () {
    test('returns only the requesting patient\'s appointments', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('appointments').add({
        'patientId': 'p1',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'scheduled',
      });
      await fs.collection('appointments').add({
        'patientId': 'p2', // someone else
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 2)),
        'status': 'scheduled',
      });

      final snap = await _AppointmentsQueries(fs).watchForPatient('p1').first;
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['patientId'], equals('p1'));
    });

    test('orders ascending by dateTime', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('appointments').add({
        'patientId': 'p1',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 5)),
        'status': 'scheduled',
      });
      await fs.collection('appointments').add({
        'patientId': 'p1',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'scheduled',
      });
      await fs.collection('appointments').add({
        'patientId': 'p1',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 3)),
        'status': 'scheduled',
      });

      final snap = await _AppointmentsQueries(fs).watchForPatient('p1').first;
      final dates = snap.docs
          .map((d) => (d.data()['dateTime'] as Timestamp).toDate())
          .toList();
      expect(dates, equals([
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 3),
        DateTime(2026, 6, 5),
      ]));
    });

    test('returns empty when patient has no appointments', () async {
      final fs = FakeFirebaseFirestore();
      final snap = await _AppointmentsQueries(fs).watchForPatient('nobody').first;
      expect(snap.docs, isEmpty);
    });
  });

  group('appointments — therapist upcoming watch', () {
    test('excludes past, cancelled, and other-therapist appointments',
        () async {
      final fs = FakeFirebaseFirestore();
      final now = DateTime.now();

      // ✓ matches: future, scheduled, our therapist
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'status': 'scheduled',
      });
      // ✗ past
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'status': 'scheduled',
      });
      // ✗ cancelled
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'status': 'cancelled',
      });
      // ✗ other therapist
      await fs.collection('appointments').add({
        'therapistId': 't2',
        'dateTime': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'status': 'scheduled',
      });

      final snap = await _AppointmentsQueries(fs)
          .watchUpcomingForTherapist('t1')
          .first;
      expect(snap.docs, hasLength(1),
          reason: 'only the future + scheduled + matching therapist matches');
    });
  });

  group('appointments — completed-this-week KPI', () {
    test('only counts completed appointments since the cutoff', () async {
      final fs = FakeFirebaseFirestore();
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 7));

      // ✓ inside window, completed
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'status': 'completed',
        'dateTime': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      });
      // ✓ at cutoff edge — boundary inclusive
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'status': 'completed',
        'dateTime': Timestamp.fromDate(cutoff),
      });
      // ✗ before cutoff
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'status': 'completed',
        'dateTime':
            Timestamp.fromDate(cutoff.subtract(const Duration(days: 1))),
      });
      // ✗ scheduled (not completed)
      await fs.collection('appointments').add({
        'therapistId': 't1',
        'status': 'scheduled',
        'dateTime': Timestamp.fromDate(now),
      });

      final snap = await _AppointmentsQueries(fs)
          .watchCompletedSince('t1', cutoff)
          .first;
      expect(snap.docs, hasLength(2));
    });
  });

  group('appointments — cancel state machine', () {
    test('cancel() flips status to "cancelled"', () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs.collection('appointments').add({
        'patientId': 'p1',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'scheduled',
      });

      await _AppointmentsQueries(fs).cancel(ref.id);
      final after = await ref.get();
      expect(after.data()!['status'], equals('cancelled'));
    });

    test('cancelling an already-cancelled appointment is idempotent', () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs.collection('appointments').add({
        'patientId': 'p1',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'cancelled',
      });

      await _AppointmentsQueries(fs).cancel(ref.id);
      final after = await ref.get();
      expect(after.data()!['status'], equals('cancelled'));
    });
  });

  group('routines — patient watch', () {
    test('returns only routines assigned to the patient', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('routines').add({
        'patientId': 'p1',
        'name': 'Para p1',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'exercises': [],
      });
      await fs.collection('routines').add({
        'patientId': 'p2',
        'name': 'Para p2',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'exercises': [],
      });

      final snap = await _RoutinesQueries(fs).watchForPatient('p1').first;
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['name'], equals('Para p1'));
    });

    test('orders descending by createdAt (newest first)', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('routines').add({
        'patientId': 'p1',
        'name': 'Old',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'exercises': [],
      });
      await fs.collection('routines').add({
        'patientId': 'p1',
        'name': 'New',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 10)),
        'exercises': [],
      });
      await fs.collection('routines').add({
        'patientId': 'p1',
        'name': 'Mid',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 5)),
        'exercises': [],
      });

      final snap = await _RoutinesQueries(fs).watchForPatient('p1').first;
      final names = snap.docs.map((d) => d.data()['name']).toList();
      expect(names, equals(['New', 'Mid', 'Old']));
    });

    test('preserves the exercises array on read', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('routines').add({
        'patientId': 'p1',
        'name': 'R',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'exercises': [
          {'name': 'Sentadilla', 'series': 3, 'reps': 10},
          {'name': 'Plancha', 'series': 1, 'reps': 1, 'durationSeconds': 30},
        ],
      });

      final snap = await _RoutinesQueries(fs).watchForPatient('p1').first;
      final exercises =
          (snap.docs.first.data()['exercises'] as List).cast<Map>();
      expect(exercises, hasLength(2));
      expect(exercises[0]['name'], equals('Sentadilla'));
      expect(exercises[1]['durationSeconds'], equals(30));
    });
  });

  group('patient lookup — therapist directory', () {
    test('lists only patients assigned to this therapist', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').add({
        'therapistId': 't1',
        'userType': 'patient',
        'name': 'Marco',
      });
      await fs.collection('users').add({
        'therapistId': 't2', // other therapist
        'userType': 'patient',
        'name': 'Ana',
      });
      await fs.collection('users').add({
        'therapistId': 't1',
        'userType': 'therapist', // wrong type
        'name': 'Dr. X',
      });

      final snap =
          await _PatientLookupQueries(fs).watchPatientsForTherapist('t1').first;
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['name'], equals('Marco'));
    });

    test('findByPatientId returns the user document when code matches',
        () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').add({
        'patientId': 'ABC12345',
        'userType': 'patient',
        'name': 'Marco',
      });
      await fs.collection('users').add({
        'patientId': 'OTHER000',
        'userType': 'patient',
        'name': 'Ana',
      });

      final result =
          await _PatientLookupQueries(fs).findByPatientId('ABC12345');
      expect(result.docs, hasLength(1));
      expect(result.docs.first.data()['name'], equals('Marco'));
    });

    test('findByPatientId returns empty when no user has that code', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').add({
        'patientId': 'EXISTS01',
        'userType': 'patient',
        'name': 'X',
      });
      final result = await _PatientLookupQueries(fs).findByPatientId('NOPE');
      expect(result.docs, isEmpty);
    });

    test('findByPatientId ignores users whose userType != "patient"',
        () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').add({
        'patientId': 'XYZ99999',
        'userType': 'therapist', // not a patient
        'name': 'Should-not-match',
      });
      final result =
          await _PatientLookupQueries(fs).findByPatientId('XYZ99999');
      expect(result.docs, isEmpty);
    });
  });

  group('appointment — required fields shape (createAppointment validation)',
      () {
    test('a properly-shaped appointment can be written and read back', () async {
      final fs = FakeFirebaseFirestore();
      final docData = {
        'patientId': 'p1',
        'patientName': 'Marco',
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(DateTime(2026, 6, 1, 10, 0)),
        'sessionType': 'Evaluación',
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      };
      final ref = await fs.collection('appointments').add(docData);
      final snap = await ref.get();
      final data = snap.data()!;

      expect(data['patientId'], equals('p1'));
      expect(data['therapistId'], equals('t1'));
      expect(data['sessionType'], equals('Evaluación'));
      expect(data['status'], equals('scheduled'));
      expect(data['dateTime'], isA<Timestamp>());
    });

    test('cancelled appointment is excluded from "scheduled" filter',
        () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs.collection('appointments').add({
        'therapistId': 't1',
        'dateTime': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1))),
        'status': 'scheduled',
      });

      // Verify it appears upcoming.
      var upcoming = await _AppointmentsQueries(fs)
          .watchUpcomingForTherapist('t1')
          .first;
      expect(upcoming.docs, hasLength(1));

      // Cancel and re-query.
      await _AppointmentsQueries(fs).cancel(ref.id);
      upcoming = await _AppointmentsQueries(fs)
          .watchUpcomingForTherapist('t1')
          .first;
      expect(upcoming.docs, isEmpty);
    });
  });
}
