import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';

/// Firestore implementation of [ConversationRepository].
///
/// Schema (top-level `conversations/{id}`):
///   - therapistId: String
///   - patientId: String
///   - patientName: String           (denormalised for the list)
///   - lastMessage: String
///   - lastMessageAt: Timestamp
///   - createdAt: Timestamp
///   - therapistUnreadCount: int
///   - patientUnreadCount: int
///
/// Messages live in `conversations/{id}/messages/{msgId}`:
///   - senderId, text, timestamp, read, type, [mediaUrl]
class FirestoreConversationRepository implements ConversationRepository {
  FirestoreConversationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _messageWindow = 50;
  static const int _previewMaxLength = 60;
  static const String _therapistType = 'therapist';

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ── Role resolution ────────────────────────────────────────────────

  Future<String> _readUserType(String uid) async {
    final doc = await _users.doc(uid).get();
    return (doc.data()?['userType'] as String?) ?? 'patient';
  }

  /// Resolve which uid is the therapist and which is the patient. We
  /// only need to read one of the two user docs because the pair must
  /// always contain exactly one therapist; whichever isn't is the patient.
  Future<({String therapistId, String patientId})> _resolveRoles(
    String uid1,
    String uid2,
  ) async {
    final type1 = await _readUserType(uid1);
    final isTherapist1 = type1 == _therapistType;
    return (
      therapistId: isTherapist1 ? uid1 : uid2,
      patientId: isTherapist1 ? uid2 : uid1,
    );
  }

  // ── Conversation management ────────────────────────────────────────

  @override
  Future<Conversation?> findConversation(String uid1, String uid2) async {
    final roles = await _resolveRoles(uid1, uid2);
    return _findByPair(roles.therapistId, roles.patientId);
  }

  Future<Conversation?> _findByPair(
    String therapistId,
    String patientId,
  ) async {
    final query = await _conversations
        .where('therapistId', isEqualTo: therapistId)
        .where('patientId', isEqualTo: patientId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Conversation.fromDoc(query.docs.first);
  }

  @override
  Future<Conversation> getOrCreateConversation(
    String uid1,
    String uid2,
  ) async {
    final roles = await _resolveRoles(uid1, uid2);
    final therapistId = roles.therapistId;
    final patientId = roles.patientId;

    // Cheap fast-path: existing conv (random or deterministic id).
    final existing = await _findByPair(therapistId, patientId);
    if (existing != null) return existing;

    // Denormalise patient display name for the list UI.
    final patientDoc = await _users.doc(patientId).get();
    final pData = patientDoc.data() ?? const <String, dynamic>{};
    final patientName = '${pData['name'] ?? ''} ${pData['lastName'] ?? ''}'
        .trim();

    // Deterministic id makes the create idempotent under concurrent
    // first-opens from both devices: whoever loses the transaction race
    // re-reads the doc the winner just created.
    final convId = '${therapistId}_$patientId';
    final ref = _conversations.doc(convId);
    final now = Timestamp.now();

    return _firestore.runTransaction<Conversation>((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        return Conversation.fromDoc(snap);
      }
      final data = <String, dynamic>{
        'therapistId': therapistId,
        'patientId': patientId,
        'patientName': patientName.isEmpty ? 'Paciente' : patientName,
        'lastMessage': '',
        'lastMessageAt': now,
        'createdAt': now,
        'therapistUnreadCount': 0,
        'patientUnreadCount': 0,
      };
      tx.set(ref, data);
      return Conversation.fromMap(convId, data);
    });
  }

  @override
  Stream<List<Conversation>> watchConversations(String uid) async* {
    final userType = await _readUserType(uid);
    final field = userType == _therapistType ? 'therapistId' : 'patientId';
    yield* _conversations
        .where(field, isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Conversation.fromDoc).toList());
  }

  // ── Messages ───────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageWindow)
        .snapshots()
        .map((snap) {
      final newestFirst = snap.docs
          .map((d) => ChatMessage.fromMap(d.data(), d.id))
          .toList();
      // Reverse to chronological order so the screen can use
      // `reverse: true` in ListView and not have to re-sort.
      return newestFirst.reversed.toList(growable: false);
    });
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final convRef = _conversations.doc(conversationId);
    final convSnap = await convRef.get();
    if (!convSnap.exists) {
      throw StateError(
        'sendMessage: conversation $conversationId does not exist',
      );
    }
    final conv = Conversation.fromDoc(convSnap);

    final recipientId = conv.otherParticipantId(senderId);
    final unreadField = recipientId == conv.therapistId
        ? 'therapistUnreadCount'
        : 'patientUnreadCount';

    final preview = text.length > _previewMaxLength
        ? '${text.substring(0, _previewMaxLength)}…'
        : text;

    final batch = _firestore.batch();
    final msgRef = convRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': MessageType.text.wireValue,
    });
    batch.update(convRef, {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
      unreadField: FieldValue.increment(1),
    });
    await batch.commit();
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  }) async {
    final convRef = _conversations.doc(conversationId);
    final snap = await convRef.get();
    if (!snap.exists) return;
    final conv = Conversation.fromDoc(snap);

    if (conv.unreadFor(uid) == 0) return;

    final field = uid == conv.therapistId
        ? 'therapistUnreadCount'
        : 'patientUnreadCount';
    await convRef.update({field: 0});
  }
}
