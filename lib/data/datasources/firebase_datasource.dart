import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase data source for centralized Firebase operations
class FirebaseDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => auth.currentUser != null;

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference<Map<String, dynamic>> document(String path) {
    return firestore.doc(path);
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) {
    return firestore.runTransaction(transactionHandler);
  }

  /// Run a batch write
  Future<void> runBatch(void Function(WriteBatch batch) batchHandler) async {
    final batch = firestore.batch();
    batchHandler(batch);
    await batch.commit();
  }
}
