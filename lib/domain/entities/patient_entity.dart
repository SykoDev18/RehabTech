/// Patient entity for therapist's view
class PatientEntity {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String condition; // Diagnóstico o condición
  final int? age;
  final String status; // 'in_progress' | 'attention_required'
  final String therapistId;
  final double progressPercentage;
  final int completedSessions;
  final int totalSessions;
  final int pendingQuestions;
  final String? notes; // Notas clínicas del terapeuta
  final DateTime createdAt;
  final DateTime? lastSessionAt;

  const PatientEntity({
    required this.id,
    required this.name,
    this.lastName = '',
    required this.email,
    this.phone,
    this.photoUrl,
    required this.condition,
    this.age,
    this.status = 'in_progress',
    required this.therapistId,
    this.progressPercentage = 0,
    this.completedSessions = 0,
    this.totalSessions = 0,
    this.pendingQuestions = 0,
    this.notes,
    required this.createdAt,
    this.lastSessionAt,
  });

  String get fullName => '$name $lastName'.trim();

  String get initials {
    if (name.isEmpty) return '';
    final words = fullName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 3 ? 3 : name.length).toUpperCase();
  }

  bool get isInProgress => status == 'in_progress';
  bool get needsAttention => status == 'attention_required';

  String get statusLabel => needsAttention ? 'Atención Requerida' : 'En Progreso';

  PatientEntity copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    String? condition,
    int? age,
    String? status,
    String? therapistId,
    double? progressPercentage,
    int? completedSessions,
    int? totalSessions,
    int? pendingQuestions,
    String? notes,
    DateTime? createdAt,
    DateTime? lastSessionAt,
  }) {
    return PatientEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      condition: condition ?? this.condition,
      age: age ?? this.age,
      status: status ?? this.status,
      therapistId: therapistId ?? this.therapistId,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      completedSessions: completedSessions ?? this.completedSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      pendingQuestions: pendingQuestions ?? this.pendingQuestions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
