import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lifecycle status for an appointment document.
///
/// `scheduled` is a legacy value written by the therapist-driven flow that
/// predates patient self-booking. Treat it as equivalent to [confirmed] in
/// queries and UI; [fromString] folds it into [confirmed] so the rest of the
/// codebase only deals with the canonical four states.
enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  static AppointmentStatus fromString(String? value) => switch (value) {
        'confirmed' => confirmed,
        'scheduled' => confirmed, // legacy therapist-created docs
        'cancelled' => cancelled,
        'completed' => completed,
        'pending' => pending,
        _ => pending,
      };

  String toFirestore() => name;

  String get displayName => switch (this) {
        AppointmentStatus.pending => 'Pendiente',
        AppointmentStatus.confirmed => 'Confirmada',
        AppointmentStatus.cancelled => 'Cancelada',
        AppointmentStatus.completed => 'Completada',
      };

  Color get color => switch (this) {
        AppointmentStatus.pending => const Color(0xFFFFA000),
        AppointmentStatus.confirmed => const Color(0xFF43A047),
        AppointmentStatus.cancelled => const Color(0xFFE53935),
        AppointmentStatus.completed => const Color(0xFF1E88E5),
      };
}

/// Modality of the visit. Orthogonal to `sessionType` (which is the clinical
/// nature of the session, e.g. "Evaluación", and is owned by the therapist).
enum AppointmentType {
  presencial,
  virtual;

  static AppointmentType? fromString(String? value) => switch (value) {
        'presencial' => presencial,
        'virtual' => virtual,
        _ => null,
      };

  String toFirestore() => name;

  String get displayName => switch (this) {
        AppointmentType.presencial => 'Presencial',
        AppointmentType.virtual => 'Virtual',
      };

  IconData get icon => switch (this) {
        AppointmentType.presencial => LucideIcons.mapPin,
        AppointmentType.virtual => LucideIcons.video,
      };
}

/// Domain model for an appointment.
///
/// Coexists additively with the therapist-driven flow: documents may have
/// been written without [type], [patientNotes], [durationMinutes] or
/// [updatedAt] (these default sensibly). The clinical [sessionType] field
/// is preserved as-is and stays optional here so legacy docs round-trip.
class Appointment {
  final String id;
  final String therapistId;
  final String patientId;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final AppointmentType? type;
  final String? sessionType;
  final String? notes;
  final String? patientNotes;
  final String? patientName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.therapistId,
    required this.patientId,
    required this.dateTime,
    this.durationMinutes = 60,
    required this.status,
    this.type,
    this.sessionType,
    this.notes,
    this.patientNotes,
    this.patientName,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get endTime =>
      dateTime.add(Duration(minutes: durationMinutes));

  /// True when the appointment is in the future and not cancelled.
  /// Confirmed and pending both count as upcoming so patients see their
  /// pending requests in the "Próximas" section.
  bool get isUpcoming =>
      dateTime.isAfter(DateTime.now()) &&
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed;

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['dateTime'];
    final created = map['createdAt'];
    final updated = map['updatedAt'];
    return Appointment(
      id: id,
      therapistId: (map['therapistId'] as String?) ?? '',
      patientId: (map['patientId'] as String?) ?? '',
      dateTime: ts is Timestamp ? ts.toDate() : DateTime.now(),
      durationMinutes: (map['durationMinutes'] as int?) ?? 60,
      status: AppointmentStatus.fromString(map['status'] as String?),
      type: AppointmentType.fromString(map['type'] as String?),
      sessionType: map['sessionType'] as String?,
      notes: map['notes'] as String?,
      patientNotes: map['patientNotes'] as String?,
      patientName: map['patientName'] as String?,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      updatedAt: updated is Timestamp
          ? updated.toDate()
          : (created is Timestamp ? created.toDate() : DateTime.now()),
    );
  }

  /// Map for `set()` on a brand-new patient-created appointment.
  /// Uses [FieldValue.serverTimestamp] for [createdAt] / [updatedAt].
  Map<String, dynamic> toCreateMap() {
    return {
      'therapistId': therapistId,
      'patientId': patientId,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'status': status.toFirestore(),
      if (type != null) 'type': type!.toFirestore(),
      if (sessionType != null) 'sessionType': sessionType,
      if (notes != null) 'notes': notes,
      if (patientNotes != null) 'patientNotes': patientNotes,
      if (patientName != null) 'patientName': patientName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Plain map for tests / fakes that don't accept [FieldValue].
  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'patientId': patientId,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'status': status.toFirestore(),
      if (type != null) 'type': type!.toFirestore(),
      if (sessionType != null) 'sessionType': sessionType,
      if (notes != null) 'notes': notes,
      if (patientNotes != null) 'patientNotes': patientNotes,
      if (patientName != null) 'patientName': patientName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Appointment copyWith({
    String? id,
    String? therapistId,
    String? patientId,
    DateTime? dateTime,
    int? durationMinutes,
    AppointmentStatus? status,
    AppointmentType? type,
    String? sessionType,
    String? notes,
    String? patientNotes,
    String? patientName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      type: type ?? this.type,
      sessionType: sessionType ?? this.sessionType,
      notes: notes ?? this.notes,
      patientNotes: patientNotes ?? this.patientNotes,
      patientName: patientName ?? this.patientName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Appointment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
