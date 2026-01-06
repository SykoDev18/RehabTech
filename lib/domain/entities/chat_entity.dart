/// Chat entities for the domain layer

enum MessageAuthor { user, nora, therapist }

/// Message entity
class MessageEntity {
  final String id;
  final String text;
  final MessageAuthor author;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const MessageEntity({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  bool get isFromUser => author == MessageAuthor.user;
  bool get isFromNora => author == MessageAuthor.nora;
  bool get isFromTherapist => author == MessageAuthor.therapist;

  MessageEntity copyWith({
    String? id,
    String? text,
    MessageAuthor? author,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Conversation entity
class ConversationEntity {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final int unreadCount;
  final String conversationType; // 'nora', 'therapist'

  const ConversationEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    required this.conversationType,
  });

  bool get isNoraChat => conversationType == 'nora';
  bool get isTherapistChat => conversationType == 'therapist';
  bool get hasUnread => unreadCount > 0;

  ConversationEntity copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    int? unreadCount,
    String? conversationType,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      conversationType: conversationType ?? this.conversationType,
    );
  }
}

/// Patient context for AI memory
class PatientContextEntity {
  final String userId;
  final String context;
  final DateTime updatedAt;

  const PatientContextEntity({
    required this.userId,
    required this.context,
    required this.updatedAt,
  });

  PatientContextEntity addContext(String newContext) {
    return PatientContextEntity(
      userId: userId,
      context: '$context\n$newContext',
      updatedAt: DateTime.now(),
    );
  }
}
