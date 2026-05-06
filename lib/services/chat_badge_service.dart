import '../data/repositories/firestore_conversation_repository.dart';
import '../domain/repositories/conversation_repository.dart';

/// Aggregates unread counts across the user's conversations into a
/// single stream that nav bars can subscribe to for badge display.
///
/// Backed by [ConversationRepository.watchConversations] — no extra
/// Firestore reads, just a fold over the same stream the conversations
/// list uses.
class ChatBadgeService {
  ChatBadgeService({ConversationRepository? repository})
      : _repository = repository ?? FirestoreConversationRepository();

  final ConversationRepository _repository;

  /// Total unread messages for [uid] across all conversations.
  /// Emits a fresh value whenever any conversation's unread count
  /// changes.
  Stream<int> watchTotalUnread(String uid) {
    return _repository.watchConversations(uid).map(
          (conversations) => conversations.fold<int>(
            0,
            (total, conv) => total + conv.unreadFor(uid),
          ),
        );
  }
}
