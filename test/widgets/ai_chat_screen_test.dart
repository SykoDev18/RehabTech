// Widget + model tests for AiChatScreen and the public types it exports.
//
// AiChatScreen itself is heavily Firebase-coupled (FirebaseAuth.instance +
// FirebaseFirestore.instance reads in initState, plus a Gemini API call) so
// we test only the parts that can be exercised without a real backend:
//   - ChatMessage roundtrip (toMap / fromMap) — the persistence contract
//   - TypingIndicator widget — the "Nora is thinking" visual
// The full chat send/receive flow is a Phase-3 integration target.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/screens/main/ai_chat_screen.dart';

void main() {
  group('ChatMessage — toMap / fromMap roundtrip', () {
    test('user message roundtrips through Firestore-shaped Map', () {
      final ts = DateTime(2026, 5, 1, 12, 30);
      final original = ChatMessage(
        'Hola Nora, me duele el hombro',
        MessageAuthor.user,
        timestamp: ts,
      );

      final map = original.toMap();
      expect(map['text'], equals('Hola Nora, me duele el hombro'));
      expect(map['author'], equals('user'));
      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate(), equals(ts));

      final recovered = ChatMessage.fromMap(map);
      expect(recovered.text, equals(original.text));
      expect(recovered.author, equals(MessageAuthor.user));
      expect(recovered.timestamp, equals(ts));
    });

    test('nora message uses the "nora" author tag', () {
      final ts = DateTime(2026, 5, 1, 12, 31);
      final original = ChatMessage(
        'Cuéntame cómo se siente.',
        MessageAuthor.nora,
        timestamp: ts,
      );

      final map = original.toMap();
      expect(map['author'], equals('nora'));

      final recovered = ChatMessage.fromMap(map);
      expect(recovered.author, equals(MessageAuthor.nora));
    });

    test('fromMap defaults missing text to empty string', () {
      final m = ChatMessage.fromMap({
        'author': 'user',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });
      expect(m.text, equals(''));
    });

    test('fromMap defaults unknown/missing author to nora', () {
      // Not-"user" → nora (mirrors the screen logic).
      final m1 = ChatMessage.fromMap({
        'text': 'hi',
        'author': 'system',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });
      expect(m1.author, equals(MessageAuthor.nora));

      // Missing author also falls back to nora.
      final m2 = ChatMessage.fromMap({
        'text': 'hi',
        'timestamp': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });
      expect(m2.author, equals(MessageAuthor.nora));
    });

    test('fromMap defaults missing timestamp to a non-null DateTime', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final m = ChatMessage.fromMap({'text': 'hi', 'author': 'user'});
      final after = DateTime.now().add(const Duration(seconds: 2));

      expect(m.timestamp.isAfter(before), isTrue);
      expect(m.timestamp.isBefore(after), isTrue);
    });

    test('ChatMessage default timestamp is set to roughly "now"', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final m = ChatMessage('x', MessageAuthor.user);
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(m.timestamp.isAfter(before), isTrue);
      expect(m.timestamp.isBefore(after), isTrue);
    });
  });

  group('TypingIndicator — visual', () {
    testWidgets('renders a dot pattern that animates between 1–3 dots',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: TypingIndicator()),
          ),
        ),
      );

      // Initial frame: the controller forwards from 0; on first build the
      // animation hasn't fired yet so the rendered dots are 1.
      await tester.pump();
      var dots = tester.widget<Text>(find.byType(Text)).data!;
      expect(dots, equals('•'));

      // After the controller completes once, the count cycles.
      // Pump beyond the 500ms duration to let the listener fire.
      await tester.pump(const Duration(milliseconds: 600));
      dots = tester.widget<Text>(find.byType(Text)).data!;
      expect(dots, anyOf(equals('•'), equals('••'), equals('•••')));

      await tester.pump(const Duration(milliseconds: 600));
      dots = tester.widget<Text>(find.byType(Text)).data!;
      expect(dots, anyOf(equals('•'), equals('••'), equals('•••')));
    });

    testWidgets('renders inside a left-aligned bubble container',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: TypingIndicator()),
          ),
        ),
      );

      // The bubble wraps the dots; sanity check it lays out non-zero size.
      final containerSize = tester.getSize(find.byType(TypingIndicator));
      expect(containerSize.width, greaterThan(0));
      expect(containerSize.height, greaterThan(0));
    });
  });

  group('ChatConversation — fromFirestore (model integrity check)', () {
    // ChatConversation reads via DocumentSnapshot which we can't construct
    // directly without `fake_cloud_firestore`. Defer that to the Firestore
    // contract tests which exercise the same Timestamp-decoding pattern.
    test('ChatConversation type is publicly exported', () {
      // Guard test: if someone privatises the class, this stops compiling.
      // Cheap insurance because the screen relies on the public name.
      // ignore: unnecessary_type_check
      expect(ChatConversation, isA<Type>());
    });
  });
}
