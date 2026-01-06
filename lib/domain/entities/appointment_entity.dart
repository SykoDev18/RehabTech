/// Appointment entity for calendar
class AppointmentEntity {
  final String id;
  final String patientId;
  final String patientName;
  final String therapistId;
  final DateTime dateTime;
  final String sessionType; // Tipo de sesión: Evaluación, Fortalecimiento, etc.
  final String? notes;
  final String status; // 'scheduled' | 'completed' | 'cancelled'
  final DateTime createdAt;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.therapistId,
    required this.dateTime,
    required this.sessionType,
    this.notes,
    this.status = 'scheduled',
    required this.createdAt,
  });

  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  String get formattedTime {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    final day = dateTime.day;
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '$day ${months[dateTime.month - 1]}';
  }

  AppointmentEntity copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? therapistId,
    DateTime? dateTime,
    String? sessionType,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return AppointmentEntity(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      therapistId: therapistId ?? this.therapistId,
      dateTime: dateTime ?? this.dateTime,
      sessionType: sessionType ?? this.sessionType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
