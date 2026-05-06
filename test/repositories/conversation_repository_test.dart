import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/data/repositories/firestore_conversation_repository.dart';
import 'package:rehabtech/domain/models/chat_message.dart';

void main() {
  late FakeFirebaseFirestore fake;
  late FirestoreConversationRepository repo;

  const therapistUid = 't1';
  const patientUid = 'p1';
  const otherPatientUid = 'p2';

  Future<void> seedUser(
    String uid, {
    required String userType,
    String name = 'Nombre',
    String lastName = 'Apellido',
  }) async {
    await fake.collection('users').doc(uid).set({
      'userType': userType,
      'name': name,
      'lastName': lastName,
    });
  }

  setUp(() async {
    fake = FakeFirebaseFirestore();
    repo = FirestoreConversationRepository(firestore: fake);
    await seedUser(therapistUid,
        userType: 'therapist', name: 'Elena', lastName: 'Garza');
    await seedUser(patientUid,
        userType: 'patient', name: 'Juan', lastName: 'Pérez');
    await seedUser(otherPatientUid,
        userType: 'patient', name: 'Ana', lastName: 'López');
  });

  group('getOrCreateConversation', () {
    test('creates a new conversation when none exists', () async {
      final conv = await repo.getOrCreateConversation(
        therapistUid,
        patientUid,
      );
      expect(conv.therapistId, therapistUid);
      expect(conv.patientId, patientUid);
      expect(conv.therapistUnreadCount, 0);
      expect(conv.patientUnreadCount, 0);
      expect(conv.patientName, 'Juan Pérez');

      final stored = await fake.collection('conversations').doc(conv.id).get();
      expect(stored.exists, isTrue);
      expect(stored.data()!['therapistId'], therapistUid);
      expect(stored.data()!['patientId'], patientUid);
    });

    test('is idempotent — second call returns the same id', () async {
      final first = await repo.getOrCreateConversation(
        therapistUid,
        patientUid,
      );
      final second = await repo.getOrCreateConversation(
        therapistUid,
        patientUid,
      );
      expect(second.id, first.id);

      final all = await fake
          .collection('conversations')
          .where('patientId', isEqualTo: patientUid)
          .get();
      expect(all.docs, hasLength(1));
    });

    test('order of args does not matter (patient-first or therapist-first)',
        () async {
      final a = await repo.getOrCreateConversation(therapistUid, patientUid);
      final b = await repo.getOrCreateConversation(patientUid, therapistUid);
      expect(b.id, a.id);
    });

    test('keeps separate conversations for different patients', () async {
      final c1 =
          await repo.getOrCreateConversation(therapistUid, patientUid);
      final c2 = await repo.getOrCreateConversation(
        therapistUid,
        otherPatientUid,
      );
      expect(c2.id, isNot(c1.id));
    });
  });

  group('sendMessage', () {
    test('adds message to subcollection and updates the parent', () async {
      final conv =
          await repo.getOrCreateConversation(therapistUid, patientUid);

      await repo.sendMessage(
        conversationId: conv.id,
        senderId: therapistUid,
        text: 'hola',
      );

      final messages = await fake
          .collection('conversations')
          .doc(conv.id)
          .collection('messages')
          .get();
      expect(messages.docs, hasLength(1));
      expect(messages.docs.first.data()['text'], 'hola');
      expect(messages.docs.first.data()['senderId'], therapistUid);
      expect(messages.docs.first.data()['read'], isFalse);
      expect(messages.docs.first.data()['type'], 'text');

      final stored = await fake.collection('conversations').doc(conv.id).get();
      expect(stored.data()!['lastMessage'], 'hola');
      // Recipient is the patient → patientUnreadCount goes to 1, therapist
      // count stays 0 (sender doesn't get an unread bump).
      expect(stored.data()!['patientUnreadCount'], 1);
      expect(stored.data()!['therapistUnreadCount'], 0);
    });

    test('truncates lastMessage preview at 60 chars', () async {
      final conv =
          await repo.getOrCreateConversation(therapistUid, patientUid);
      final longText = 'a' * 200;

      await repo.sendMessage(
        conversationId: conv.id,
        senderId: patientUid,
        text: longText,
      );

      final stored = await fake.collection('conversations').doc(conv.id).get();
      final preview = stored.data()!['lastMessage'] as String;
      expect(preview.length, lessThanOrEqualTo(61)); // 60 + 1 ellipsis char
      expect(preview.endsWith('…'), isTrue);
    });

    test('subsequent sends from the same user keep incrementing recipient',
        () async {
      final conv =
          await repo.getOrCreateConversation(therapistUid, patientUid);

      for (var i = 0; i < 3; i++) {
        await repo.sendMessage(
          conversationId: conv.id,
          senderId: therapistUid,
          text: 'msg $i',
        );
      }

      final stored = await fake.collection('conversations').doc(conv.id).get();
      expect(stored.data()!['patientUnreadCount'], 3);
      expect(stored.data()!['therapistUnreadCount'], 0);
    });

    test('throws StateError on missing conversation', () async {
      expect(
        () => repo.sendMessage(
          conversationId: 'does-not-exist',
          senderId: therapistUid,
          text: 'x',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('markAsRead', () {
    test('resets only the calling user\'s unread count', () async {
      final conv =
          await repo.getOrCreateConversation(therapistUid, patientUid);
      await repo.sendMessage(
        conversationId: conv.id,
        senderId: therapistUid,
        text: 'x',
      );
      // Patient has 1 unread, therapist has 0.

      await repo.markAsRead(conversationId: conv.id, uid: patientUid);

      final stored = await fake.collection('conversations').doc(conv.id).get();
      expect(stored.data()!['patientUnreadCount'], 0);
      expect(stored.data()!['therapistUnreadCount'], 0);
    });

    test('is a no-op when the count is already 0', () async {
      final conv =
          await repo.getOrCreateConversation(therapistUid, patientUid);
      // Counts are both 0 from creation.
      await repo.markAsRead(conversationId: conv.id, uid: therapistUid);

      // Still 0 — no exception, no spurious writes.
      final stored = await fake.collection('conversations').doc(conv.id).get();
      expect(stored.data()!['therapistUnreadCount'], 0);
    });
  });

  group('watchMessages', () {
    test('emits messages in chronological order', () async {
      final conv =
          await repo.getOrCreateConversation(therapistUid, patientUid);

      await repo.sendMessage(
        conversationId: conv.id,
        senderId: therapistUid,
        text: 'one',
      );
      await repo.sendMessage(
        conversationId: conv.id,
        senderId: patientUid,
        text: 'two',
      );
      await repo.sendMessage(
        conversationId: conv.id,
        senderId: therapistUid,
        text: 'three',
      );

      final List<ChatMessage> latest =
          await repo.watchMessages(conv.id).first;
      expect(latest.map((m) => m.text), ['one', 'two', 'three']);
    });

    test('parses messages with missing read/type fields gracefully',
        () async {
      // Hand-write a message doc that lacks the read/type fields, as
      // older messages from the prior code path do.
      final convRef = fake.collection('conversations').doc('manual');
      await convRef.set({
        'therapistId': therapistUid,
        'patientId': patientUid,
        'lastMessage': '',
        'lastMessageAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'therapistUnreadCount': 0,
        'patientUnreadCount': 0,
      });
      await convRef.collection('messages').add({
        'senderId': therapistUid,
        'text': 'legacy',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });

      final List<ChatMessage> messages =
          await repo.watchMessages('manual').first;
      expect(messages, hasLength(1));
      expect(messages.first.text, 'legacy');
      expect(messages.first.read, isFalse);
      expect(messages.first.type, MessageType.text);
    });
  });

  group('watchConversations', () {
    test('therapist sees only conversations where they are the therapist',
        () async {
      // Therapist has two patients.
      await repo.getOrCreateConversation(therapistUid, patientUid);
      await repo.getOrCreateConversation(therapistUid, otherPatientUid);
      // A different therapist with the same patient (should not surface).
      await seedUser('t2', userType: 'therapist');
      await repo.getOrCreateConversation('t2', patientUid);

      final list = await repo.watchConversations(therapistUid).first;
      expect(list, hasLength(2));
      for (final c in list) {
        expect(c.therapistId, therapistUid);
      }
    });

    test('patient sees only their own conversation', () async {
      await repo.getOrCreateConversation(therapistUid, patientUid);
      await repo.getOrCreateConversation(therapistUid, otherPatientUid);

      final list = await repo.watchConversations(patientUid).first;
      expect(list, hasLength(1));
      expect(list.first.patientId, patientUid);
    });
  });
}
