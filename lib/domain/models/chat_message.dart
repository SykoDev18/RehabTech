import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of a message in a patient↔therapist conversation.
///
/// `text` is the only type currently produced by the app. `image` and `file`
/// are placeholders for future media support and are accepted on read so
/// older / experimental docs don't crash the parser.
enum MessageType {
  text,
  image,
  file;

  static MessageType fromString(String? value) => switch (value) {
        'image' => image,
        'file' => file,
        _ => text,
      };

  String get wireValue => name;
}

/// A single message inside `conversations/{conversationId}/messages/{id}`.
///
/// Tolerant on read: missing `read`/`type`/`mediaUrl` fields default to
/// safe values rather than throwing — older messages were written without
/// them and we don't want a single bad doc to break the entire stream.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;
  final MessageType type;
  final String? mediaUrl;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.read,
    required this.type,
    this.mediaUrl,
  });

  bool isSentBy(String uid) => senderId == uid;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] as bool? ?? false,
      type: MessageType.fromString(map['type'] as String?),
      mediaUrl: map['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'type': type.wireValue,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
  }
}
