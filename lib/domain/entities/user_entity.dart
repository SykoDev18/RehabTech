/// User entity representing a user in the domain layer
class UserEntity {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String? photoUrl;
  final String userType; // 'patient' or 'therapist'
  final String? therapistId;
  final String? therapistName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    this.lastName = '',
    required this.email,
    this.photoUrl,
    required this.userType,
    this.therapistId,
    this.therapistName,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$name $lastName'.trim();
  
  String get initials {
    if (name.isEmpty) return '';
    if (lastName.isEmpty) return name[0].toUpperCase();
    return '${name[0]}${lastName[0]}'.toUpperCase();
  }

  bool get isPatient => userType == 'patient';
  bool get isTherapist => userType == 'therapist';
  bool get hasTherapist => therapistId != null && therapistId!.isNotEmpty;

  UserEntity copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    String? photoUrl,
    String? userType,
    String? therapistId,
    String? therapistName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
