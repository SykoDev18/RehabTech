import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/exceptions/appointment_exception.dart';
import '../../domain/models/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Firestore-backed [AppointmentRepository].
///
/// Reads use `.snapshots()` so consumers (typically [StreamBuilder]) get
/// realtime updates and lifecycle handles itself. Writes funnel through
/// [_runWrite] which converts [FirebaseException] / generic errors into
/// [AppointmentException] with a Spanish, user-safe message.
///
/// The next-appointment query intentionally does NOT filter by status in
/// the Firestore call — adding `status whereIn ['pending','confirmed']`
/// alongside the `dateTime >=` range needs a separate composite index per
/// status combo, and would also miss legacy `scheduled` docs unless we add
/// it explicitly. Filtering is done client-side after the order-by-date
/// query, which is correct because the result set is tiny (limit 5) and
/// the existing `(patientId ASC, dateTime ASC)` index already covers it.
class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  // ── Patient queries ────────────────────────────────────────────────

  @override
  Stream<Appointment?> watchNextAppointment(String patientId) {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('patientId', isEqualTo: patientId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .orderBy('dateTime')
        .limit(5)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final appt = Appointment.fromMap(doc.data(), doc.id);
        if (appt.status != AppointmentStatus.cancelled) {
          return appt;
        }
      }
      return null;
    });
  }

  @override
  Stream<List<Appointment>> watchPatientAppointments(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromMap(d.data(), d.id))
            .toList());
  }

  @override
  Stream<Appointment?> watchAppointment(String appointmentId) {
    return _col.doc(appointmentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Appointment.fromMap(data, doc.id);
    });
  }

  // ── Therapist queries ──────────────────────────────────────────────

  @override
  Stream<List<Appointment>> watchAppointmentsForDate(
    String therapistId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _col
        .where('therapistId', isEqualTo: therapistId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromMap(d.data(), d.id))
            .toList());
  }

  @override
  Stream<List<Appointment>> watchUpcomingAppointments(String therapistId) {
    final now = Timestamp.fromDate(DateTime.now());
    final horizon = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 30)),
    );
    return _col
        .where('therapistId', isEqualTo: therapistId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .where('dateTime', isLessThan: horizon)
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromMap(d.data(), d.id))
            .where((a) => a.status != AppointmentStatus.cancelled)
            .toList());
  }

  // ── Mutations ──────────────────────────────────────────────────────

  @override
  Future<String> createAppointment(Appointment appointment) async {
    if (appointment.status != AppointmentStatus.pending) {
      throw const AppointmentException(
        'Solo se pueden crear citas pendientes desde la app.',
      );
    }
    return _runWrite<String>(
      'No se pudo agendar la cita',
      () async {
        final ref = await _col.add(appointment.toCreateMap());
        // TODO: implement push notifications for appointment status changes
        // (notify therapist of new pending request).
        return ref.id;
      },
    );
  }

  @override
  Future<void> confirmAppointment(String appointmentId) {
    return _runWrite<void>(
      'No se pudo confirmar la cita',
      () async {
        await _col.doc(appointmentId).update({
          'status': AppointmentStatus.confirmed.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // TODO: implement push notifications for appointment status changes
        // (notify patient: appointment confirmed).
      },
    );
  }

  @override
  Future<void> cancelAppointment(
    String appointmentId, {
    required String cancellerId,
    String? reason,
  }) {
    return _runWrite<void>(
      'No se pudo cancelar la cita',
      () async {
        await _col.doc(appointmentId).update({
          'status': AppointmentStatus.cancelled.toFirestore(),
          'cancellerId': cancellerId,
          if (reason != null && reason.isNotEmpty) 'cancellationReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // TODO: implement push notifications for appointment status changes
        // (notify the OTHER party that the appointment was cancelled).
      },
    );
  }

  @override
  Future<void> completeAppointment(
    String appointmentId, {
    String? notes,
  }) {
    return _runWrite<void>(
      'No se pudo marcar la cita como completada',
      () async {
        await _col.doc(appointmentId).update({
          'status': AppointmentStatus.completed.toFirestore(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
    );
  }

  @override
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> fields,
  ) {
    return _runWrite<void>(
      'No se pudo actualizar la cita',
      () async {
        await _col.doc(appointmentId).update({
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // TODO: implement push notifications for appointment status changes
        // (notify the other party when reschedule resets to pending).
      },
    );
  }

  // ── Internals ──────────────────────────────────────────────────────

  /// Runs [op] and converts thrown errors into [AppointmentException]
  /// with a Spanish message. Permission-denied errors get a clearer
  /// dedicated message because they usually mean the rule rejected the
  /// write and the user needs to know it wasn't a transient failure.
  Future<T> _runWrite<T>(String fallback, Future<T> Function() op) async {
    try {
      return await op();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AppointmentException(
          'No tienes permisos para realizar esta acción.',
        );
      }
      throw AppointmentException('$fallback. Inténtalo de nuevo.');
    } catch (_) {
      throw AppointmentException('$fallback. Inténtalo de nuevo.');
    }
  }
}
