import '../models/appointment.dart';

/// Abstract repository for appointment lifecycle.
///
/// Concrete implementations live in `lib/data/repositories/`. Streams are
/// backed by Firestore `.snapshots()` and update in real-time; mutations
/// throw [AppointmentException] with a Spanish, user-safe message.
abstract class AppointmentRepository {
  // ── Patient queries ────────────────────────────────────────────────

  /// Soonest upcoming appointment for [patientId] that is not cancelled
  /// or completed. Emits `null` when there is none.
  Stream<Appointment?> watchNextAppointment(String patientId);

  /// All appointments for [patientId], ordered by `dateTime` ascending.
  /// Callers split into upcoming/past based on [Appointment.isUpcoming].
  Stream<List<Appointment>> watchPatientAppointments(String patientId);

  /// Single document stream for [appointmentId]. Useful for detail
  /// screens that need to react to status changes (e.g. patient sees
  /// pending → confirmed live).
  Stream<Appointment?> watchAppointment(String appointmentId);

  // ── Therapist queries ──────────────────────────────────────────────

  /// All appointments for [therapistId] occurring on the calendar day
  /// of [date] (local time), ordered by time.
  Stream<List<Appointment>> watchAppointmentsForDate(
    String therapistId,
    DateTime date,
  );

  /// Upcoming appointments for [therapistId] within the next 30 days,
  /// ordered by `dateTime`. Used by the calendar dashboard and home
  /// "next 3" widget.
  Stream<List<Appointment>> watchUpcomingAppointments(String therapistId);

  // ── Mutations ──────────────────────────────────────────────────────

  /// Patient creates a new pending request.
  /// The status MUST be [AppointmentStatus.pending] when calling — the
  /// implementation enforces this and the Firestore rules also gate it.
  /// Returns the generated document id.
  Future<String> createAppointment(Appointment appointment);

  /// Therapist accepts a pending appointment.
  Future<void> confirmAppointment(String appointmentId);

  /// Either party cancels. [cancellerId] is recorded so the audit trail
  /// shows who triggered the cancellation; [reason] is optional and stored
  /// in `cancellationReason`.
  Future<void> cancelAppointment(
    String appointmentId, {
    required String cancellerId,
    String? reason,
  });

  /// Therapist marks the session done after it happens.
  /// Optional [notes] populate the therapist's `notes` field.
  Future<void> completeAppointment(
    String appointmentId, {
    String? notes,
  });

  /// Therapist updates arbitrary fields on an appointment (time, type,
  /// notes, etc). Used by reschedule and notes editing.
  /// Always stamps `updatedAt` with the server timestamp.
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> fields,
  );
}
