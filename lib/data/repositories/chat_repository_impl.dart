import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/constants/api_constants.dart';

/// Firebase implementation of ChatRepository
class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;
  GenerativeModel? _aiModel;

  ChatRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  GenerativeModel get _model {
    _aiModel ??= GenerativeModel(
      model: ApiConstants.geminiModel,
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
    return _aiModel!;
  }

  // ============ Conversations ============

  @override
  Future<List<ConversationEntity>> getConversations(String userId) async {
    final snapshot = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .orderBy('lastMessageAt', descending: true)
        .get();
    
    return snapshot.docs.map(_mapConversationToEntity).toList();
  }

  @override
  Future<ConversationEntity?> getConversationById(String userId, String conversationId) async {
    final doc = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .get();
    
    if (!doc.exists) return null;
    return _mapConversationToEntity(doc);
  }

  @override
  Future<String> createConversation(String userId, String title, String type) async {
    final docRef = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .add({
          'title': title,
          'conversationType': type,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'unreadCount': 0,
        });
    
    return docRef.id;
  }

  @override
  Future<void> updateConversation(String userId, ConversationEntity conversation) async {
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversation.id)
        .update({
          'title': conversation.title,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': conversation.lastMessage,
          'unreadCount': conversation.unreadCount,
        });
  }

  @override
  Future<void> deleteConversation(String userId, String conversationId) async {
    // Delete all messages first
    final messagesSnapshot = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .collection(ApiConstants.messagesCollection)
        .get();
    
    for (final doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Delete conversation
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .delete();
  }

  @override
  Stream<List<ConversationEntity>> watchConversations(String userId) {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapConversationToEntity).toList());
  }

  // ============ Messages ============

  @override
  Future<List<MessageEntity>> getMessages(String userId, String conversationId) async {
    final snapshot = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .collection(ApiConstants.messagesCollection)
        .orderBy('timestamp')
        .get();
    
    return snapshot.docs.map(_mapMessageToEntity).toList();
  }

  @override
  Future<void> sendMessage(String userId, String conversationId, MessageEntity message) async {
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .collection(ApiConstants.messagesCollection)
        .add(_mapMessageToFirestore(message));
    
    // Update conversation
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .update({
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': message.text.length > 50 
              ? '${message.text.substring(0, 50)}...' 
              : message.text,
        });
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String userId, String conversationId) {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .collection(ApiConstants.messagesCollection)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapMessageToEntity).toList());
  }

  @override
  Future<void> markAsRead(String userId, String conversationId) async {
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.noraChatsCollection)
        .doc(conversationId)
        .update({'unreadCount': 0});
  }

  // ============ Patient Context ============

  @override
  Future<PatientContextEntity?> getPatientContext(String userId) async {
    final doc = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.patientContextCollection)
        .doc('summary')
        .get();
    
    if (!doc.exists) return null;
    
    return PatientContextEntity(
      userId: userId,
      context: doc.data()?['context'] ?? '',
      updatedAt: (doc.data()?['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<void> updatePatientContext(String userId, String context) async {
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.patientContextCollection)
        .doc('summary')
        .set({
          'context': context,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // ============ AI Chat ============

  @override
  Future<String> sendToNora(String message, String? patientContext) async {
    final chat = _model.startChat(
      history: [
        Content.text(_getNoraSystemPrompt(patientContext)),
      ],
    );
    
    final response = await chat.sendMessage(Content.text(message));
    return response.text ?? 'No obtuve respuesta. Intenta de nuevo.';
  }

  String _getNoraSystemPrompt(String? patientContext) {
    String contextSection = '';
    if (patientContext != null && patientContext.isNotEmpty) {
      contextSection = '''

# CONTEXTO DEL PACIENTE
$patientContext
''';
    }

    return '''
Eres "Nora", una asistente de IA especializada en apoyo fisioterapéutico.
$contextSection
# IDENTIDAD Y TONO
- Personalidad: Empática, motivadora y profesional
- Comunícate en un tono cálido pero competente
- Sé concisa pero completa en tus respuestas

# LÍMITES CRÍTICOS DE SEGURIDAD
⚠️ NUNCA diagnostiques condiciones médicas ni prescribas tratamientos.
⚠️ Ante dolor severo o síntomas de alarma, recomienda consultar al profesional.
''';
  }

  // ============ Mapping helpers ============

  ConversationEntity _mapConversationToEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ConversationEntity(
      id: doc.id,
      title: data['title'] ?? 'Conversación',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      unreadCount: data['unreadCount'] ?? 0,
      conversationType: data['conversationType'] ?? 'nora',
    );
  }

  MessageEntity _mapMessageToEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageEntity(
      id: doc.id,
      text: data['text'] ?? '',
      author: _parseAuthor(data['author']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> _mapMessageToFirestore(MessageEntity message) {
    return {
      'text': message.text,
      'author': message.author.name,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'isRead': message.isRead,
      'metadata': message.metadata,
    };
  }

  MessageAuthor _parseAuthor(String? author) {
    switch (author) {
      case 'user':
        return MessageAuthor.user;
      case 'nora':
        return MessageAuthor.nora;
      case 'therapist':
        return MessageAuthor.therapist;
      default:
        return MessageAuthor.user;
    }
  }
}
