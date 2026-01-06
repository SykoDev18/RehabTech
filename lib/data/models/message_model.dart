import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';

/// Message model (DTO) for data layer
class MessageModel {
  final String id;
  final String text;
  final String author;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const MessageModel({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  /// Create from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageModel(
      id: doc.id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'user',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  /// Create from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? 'user',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'author': author,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  /// Convert to domain entity
  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      text: text,
      author: _parseAuthor(author),
      timestamp: timestamp,
      isRead: isRead,
      metadata: metadata,
    );
  }

  /// Create from domain entity
  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      text: entity.text,
      author: entity.author.name,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      metadata: entity.metadata,
    );
  }

  static MessageAuthor _parseAuthor(String author) {
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

/// Conversation model (DTO) for data layer
class ConversationModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final int unreadCount;
  final String conversationType;

  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    required this.conversationType,
  });

  /// Create from Firestore document
  factory ConversationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ConversationModel(
      id: doc.id,
      title: data['title'] ?? 'Conversación',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      unreadCount: data['unreadCount'] ?? 0,
      conversationType: data['conversationType'] ?? 'nora',
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': createdAt,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'conversationType': conversationType,
    };
  }

  /// Convert to domain entity
  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      title: title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      conversationType: conversationType,
    );
  }

  /// Create from domain entity
  factory ConversationModel.fromEntity(ConversationEntity entity) {
    return ConversationModel(
      id: entity.id,
      title: entity.title,
      createdAt: entity.createdAt,
      lastMessageAt: entity.lastMessageAt,
      lastMessage: entity.lastMessage,
      unreadCount: entity.unreadCount,
      conversationType: entity.conversationType,
    );
  }
}
