import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// User model (DTO) for data layer
class UserModel {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String? photoUrl;
  final String userType;
  final String? therapistId;
  final String? therapistName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
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

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      userType: data['userType'] ?? 'patient',
      therapistId: data['therapistId'],
      therapistName: data['therapistName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      userType: json['userType'] ?? 'patient',
      therapistId: json['therapistId'],
      therapistName: json['therapistName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
      'userType': userType,
      'therapistId': therapistId,
      'therapistName': therapistName,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
      'userType': userType,
      'therapistId': therapistId,
      'therapistName': therapistName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      photoUrl: photoUrl,
      userType: userType,
      therapistId: therapistId,
      therapistName: therapistName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      lastName: entity.lastName,
      email: entity.email,
      photoUrl: entity.photoUrl,
      userType: entity.userType,
      therapistId: entity.therapistId,
      therapistName: entity.therapistName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
