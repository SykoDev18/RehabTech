import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/models/chat_message.dart';

void main() {
  group('MessageType.fromString', () {
    test('maps known values', () {
      expect(MessageType.fromString('text'), MessageType.text);
      expect(MessageType.fromString('image'), MessageType.image);
      expect(MessageType.fromString('file'), MessageType.file);
    });

    test('unknown / null falls back to text', () {
      expect(MessageType.fromString(null), MessageType.text);
      expect(MessageType.fromString(''), MessageType.text);
      expect(MessageType.fromString('weird'), MessageType.text);
    });
  });

  group('ChatMessage.isSentBy', () {
    final msg = ChatMessage(
      id: 'm1',
      senderId: 'u1',
      text: 'hi',
      timestamp: DateTime(2026, 5, 5, 12),
      read: false,
      type: MessageType.text,
    );

    test('returns true for sender uid', () {
      expect(msg.isSentBy('u1'), isTrue);
    });

    test('returns false for any other uid', () {
      expect(msg.isSentBy('u2'), isFalse);
      expect(msg.isSentBy(''), isFalse);
    });
  });

  group('ChatMessage.fromMap (lenient on missing fields)', () {
    test('full map roundtrips through toMap/fromMap', () {
      final original = ChatMessage(
        id: 'm1',
        senderId: 'u1',
        text: 'hello',
        timestamp: DateTime(2026, 5, 5, 12),
        read: true,
        type: MessageType.image,
        mediaUrl: 'https://example.com/x.png',
      );
      final round = ChatMessage.fromMap(original.toMap(), original.id);
      expect(round.senderId, 'u1');
      expect(round.text, 'hello');
      expect(round.read, isTrue);
      expect(round.type, MessageType.image);
      expect(round.mediaUrl, 'https://example.com/x.png');
      expect(round.timestamp, DateTime(2026, 5, 5, 12));
    });

    test('missing read field defaults to false', () {
      final m = ChatMessage.fromMap({
        'senderId': 'u1',
        'text': 'hi',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 5)),
      }, 'id');
      expect(m.read, isFalse);
    });

    test('missing type field defaults to MessageType.text', () {
      final m = ChatMessage.fromMap({
        'senderId': 'u1',
        'text': 'hi',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 5)),
      }, 'id');
      expect(m.type, MessageType.text);
    });

    test('completely empty map yields safe defaults instead of throwing', () {
      final m = ChatMessage.fromMap(const {}, 'id');
      expect(m.senderId, '');
      expect(m.text, '');
      expect(m.read, isFalse);
      expect(m.type, MessageType.text);
      expect(m.mediaUrl, isNull);
    });
  });
}
