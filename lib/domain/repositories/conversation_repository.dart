import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Storage and real-time observation contract for human↔human chats
/// (patient ↔ therapist). Completely separate from the Nora AI chat
/// system — that lives in [ChatRepository].
///
/// The role-specific schema (`therapistId`/`patientId`,
/// `therapistUnreadCount`/`patientUnreadCount`) is hidden behind this
/// API: callers pass `myUid` and `otherUserId` and the implementation
/// resolves who is therapist vs patient by reading
/// `users/{uid}.userType`. This keeps screen code symmetric across both
/// roles and lets the deployed `onConversationMessageCreated` Cloud
/// Function continue to read `therapistId`/`patientId` directly.
abstract class ConversationRepository {
  // ── Conversation management ────────────────────────────────────────

  /// Find existing conversation between two users. Returns `null` if no
  /// conversation has been created yet.
  Future<Conversation?> findConversation(String uid1, String uid2);

  /// Get or create a conversation between two users. If one already
  /// exists it is returned unchanged; otherwise a new document is
  /// created with both unread counts zeroed and a denormalised
  /// `patientName` for cheap list rendering.
  ///
  /// Idempotent — safe to call from `initState` on every chat open.
  Future<Conversation> getOrCreateConversation(String uid1, String uid2);

  /// Stream of all conversations the user participates in, ordered by
  /// `lastMessageAt` DESC. Backed by either the
  /// `(therapistId, lastMessageAt DESC)` or `(patientId, lastMessageAt DESC)`
  /// composite index — the implementation picks based on the user's
  /// `userType`.
  Stream<List<Conversation>> watchConversations(String uid);

  // ── Messages ───────────────────────────────────────────────────────

  /// Stream of the most recent 50 messages in a conversation, in
  /// chronological order (oldest first). UIs that display newest at
  /// the bottom should keep `reverse: true` and render the list as-is.
  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Send a text message. Atomically:
  ///   1. appends a new message doc to `conversations/{id}/messages`
  ///   2. updates the parent conversation's `lastMessage`,
  ///      `lastMessageAt`, and increments the recipient's unread count
  ///
  /// Throws [StateError] if the conversation does not exist.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });

  /// Reset [uid]'s unread count for the given conversation to 0.
  /// No-op if the count is already 0 (avoids a wasted Firestore write
  /// on every chat open).
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  });
}
