import '../entities/chat_entity.dart';

/// Chat repository interface for Nora AI and therapist chats
abstract class ChatRepository {
  // ============ Conversations ============
  
  /// Get all conversations for user
  Future<List<ConversationEntity>> getConversations(String userId);
  
  /// Get conversation by ID
  Future<ConversationEntity?> getConversationById(String userId, String conversationId);
  
  /// Create new conversation
  Future<String> createConversation(String userId, String title, String type);
  
  /// Update conversation
  Future<void> updateConversation(String userId, ConversationEntity conversation);
  
  /// Delete conversation
  Future<void> deleteConversation(String userId, String conversationId);
  
  /// Stream of conversations
  Stream<List<ConversationEntity>> watchConversations(String userId);
  
  // ============ Messages ============
  
  /// Get messages for conversation
  Future<List<MessageEntity>> getMessages(String userId, String conversationId);
  
  /// Send message
  Future<void> sendMessage(String userId, String conversationId, MessageEntity message);
  
  /// Stream of messages
  Stream<List<MessageEntity>> watchMessages(String userId, String conversationId);
  
  /// Mark messages as read
  Future<void> markAsRead(String userId, String conversationId);
  
  // ============ Patient Context ============
  
  /// Get patient context for AI
  Future<PatientContextEntity?> getPatientContext(String userId);
  
  /// Update patient context
  Future<void> updatePatientContext(String userId, String context);
  
  // ============ AI Chat ============
  
  /// Send message to Nora AI and get response
  Future<String> sendToNora(String message, String? patientContext);
}
