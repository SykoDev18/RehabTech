import 'package:cloud_firestore/cloud_firestore.dart';

/// A patient↔therapist conversation document at top-level
/// `conversations/{id}`.
///
/// Internally the Firestore schema is role-specific (`therapistId`,
/// `patientId`, `therapistUnreadCount`, `patientUnreadCount`) — required by
/// the deployed `onConversationMessageCreated` Cloud Function and the
/// existing security rules. This class exposes role-agnostic helpers
/// (`unreadFor(uid)`, `otherParticipantId(uid)`) so callers don't need to
/// branch on therapist/patient.
class Conversation {
  final String id;
  final String therapistId;
  final String patientId;
  final String? patientName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int therapistUnreadCount;
  final int patientUnreadCount;

  const Conversation({
    required this.id,
    required this.therapistId,
    required this.patientId,
    required this.createdAt,
    this.patientName,
    this.lastMessage,
    this.lastMessageAt,
    this.therapistUnreadCount = 0,
    this.patientUnreadCount = 0,
  });

  /// Unread message count for [uid]. Returns 0 if [uid] is neither
  /// participant — defensive for callers that may pass a stale auth uid.
  int unreadFor(String uid) {
    if (uid == therapistId) return therapistUnreadCount;
    if (uid == patientId) return patientUnreadCount;
    return 0;
  }

  /// The participant that is NOT [myUid]. Falls back to [patientId] if
  /// [myUid] matches neither — should never happen in practice but
  /// avoids a throw inside a builder.
  String otherParticipantId(String myUid) {
    if (myUid == therapistId) return patientId;
    return therapistId;
  }

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    return Conversation(
      id: id,
      therapistId: map['therapistId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      patientName: map['patientName'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      therapistUnreadCount: (map['therapistUnreadCount'] as num?)?.toInt() ?? 0,
      patientUnreadCount: (map['patientUnreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Conversation.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'lastMessage': lastMessage ?? '',
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'therapistUnreadCount': therapistUnreadCount,
      'patientUnreadCount': patientUnreadCount,
    };
  }
}
