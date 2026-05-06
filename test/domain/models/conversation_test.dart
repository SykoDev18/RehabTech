import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/models/conversation.dart';

Conversation _make({
  String id = 'c1',
  String therapistId = 't1',
  String patientId = 'p1',
  int therapistUnread = 0,
  int patientUnread = 0,
  String? lastMessage,
  DateTime? lastMessageAt,
}) {
  return Conversation(
    id: id,
    therapistId: therapistId,
    patientId: patientId,
    therapistUnreadCount: therapistUnread,
    patientUnreadCount: patientUnread,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  group('Conversation.unreadFor', () {
    test('returns therapist count for therapist uid', () {
      final c = _make(therapistUnread: 3, patientUnread: 7);
      expect(c.unreadFor('t1'), 3);
    });

    test('returns patient count for patient uid', () {
      final c = _make(therapistUnread: 3, patientUnread: 7);
      expect(c.unreadFor('p1'), 7);
    });

    test('returns 0 for an unrelated uid (does not throw)', () {
      final c = _make(therapistUnread: 3, patientUnread: 7);
      expect(c.unreadFor('stranger'), 0);
    });
  });

  group('Conversation.otherParticipantId', () {
    test('therapist sees patient', () {
      expect(_make().otherParticipantId('t1'), 'p1');
    });

    test('patient sees therapist', () {
      expect(_make().otherParticipantId('p1'), 't1');
    });

    test('unrelated uid falls back to therapistId rather than throwing', () {
      expect(_make().otherParticipantId('stranger'), 't1');
    });
  });

  group('Conversation.fromMap', () {
    test('parses a complete map', () {
      final map = <String, dynamic>{
        'therapistId': 't1',
        'patientId': 'p1',
        'patientName': 'Juan Pérez',
        'lastMessage': 'hola',
        'lastMessageAt': Timestamp.fromDate(DateTime(2026, 5, 5, 12)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'therapistUnreadCount': 2,
        'patientUnreadCount': 0,
      };
      final c = Conversation.fromMap('c1', map);
      expect(c.id, 'c1');
      expect(c.therapistId, 't1');
      expect(c.patientId, 'p1');
      expect(c.patientName, 'Juan Pérez');
      expect(c.lastMessage, 'hola');
      expect(c.therapistUnreadCount, 2);
      expect(c.patientUnreadCount, 0);
      expect(c.lastMessageAt, DateTime(2026, 5, 5, 12));
    });

    test('unread counts default to 0 when missing', () {
      final c = Conversation.fromMap('c1', const <String, dynamic>{
        'therapistId': 't1',
        'patientId': 'p1',
      });
      expect(c.therapistUnreadCount, 0);
      expect(c.patientUnreadCount, 0);
      expect(c.lastMessage, isNull);
      expect(c.lastMessageAt, isNull);
    });

    test('coerces num unread counts to int', () {
      final c = Conversation.fromMap('c1', <String, dynamic>{
        'therapistId': 't1',
        'patientId': 'p1',
        'therapistUnreadCount': 1.0,
        'patientUnreadCount': 2,
      });
      expect(c.therapistUnreadCount, 1);
      expect(c.patientUnreadCount, 2);
    });
  });
}
