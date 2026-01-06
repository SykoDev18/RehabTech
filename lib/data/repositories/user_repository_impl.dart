import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/constants/api_constants.dart';

/// Firebase implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(ApiConstants.usersCollection);

  @override
  Future<UserEntity?> getUserById(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return _mapToEntity(doc);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await getUserById(user.uid);
  }

  @override
  Future<void> createUser(UserEntity user) async {
    await _usersCollection.doc(user.id).set(_mapToFirestore(user));
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    await _usersCollection.doc(user.id).update(_mapToFirestore(user));
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  @override
  Stream<UserEntity?> watchUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _mapToEntity(doc);
    });
  }

  @override
  Future<String> uploadUserPhoto(String userId, String filePath) async {
    // TODO: Implement with Firebase Storage
    throw UnimplementedError();
  }

  @override
  Future<UserEntity?> getTherapist(String therapistId) async {
    final doc = await _usersCollection.doc(therapistId).get();
    if (!doc.exists) return null;
    final entity = _mapToEntity(doc);
    if (!entity.isTherapist) return null;
    return entity;
  }

  @override
  Future<List<UserEntity>> getAllTherapists() async {
    final snapshot = await _usersCollection
        .where('userType', isEqualTo: 'therapist')
        .get();
    return snapshot.docs.map(_mapToEntity).toList();
  }

  @override
  Future<void> assignTherapist(String patientId, String therapistId) async {
    final therapist = await getTherapist(therapistId);
    await _usersCollection.doc(patientId).update({
      'therapistId': therapistId,
      'therapistName': therapist?.fullName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ Mapping helpers ============

  UserEntity _mapToEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserEntity(
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

  Map<String, dynamic> _mapToFirestore(UserEntity user) {
    return {
      'name': user.name,
      'lastName': user.lastName,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'userType': user.userType,
      'therapistId': user.therapistId,
      'therapistName': user.therapistName,
      'createdAt': user.createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
