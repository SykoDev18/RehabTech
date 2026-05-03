import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/data/repositories/firestore_appointment_repository.dart';
import 'package:rehabtech/domain/models/appointment.dart';
import 'package:rehabtech/screens/appointments/book_appointment_sheet.dart';

/// The sheet's "taken slot" StreamBuilder hits `FirebaseFirestore.instance`
/// directly (not the injected repository) which is hard to fake without a
/// full Firebase platform stub. The widget tests below exercise step 1 and
/// the confirm path through the repository directly — the visual flow is
/// covered by manual QA.
void main() {
  late FakeFirebaseFirestore fake;
  late FirestoreAppointmentRepository repo;

  setUp(() {
    fake = FakeFirebaseFirestore();
    repo = FirestoreAppointmentRepository(firestore: fake);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) => BookAppointmentSheet(
                    patientId: 'p1',
                    therapistId: 't1',
                    repository: repo,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('step 1 renders calendar picker', (tester) async {
    await pumpSheet(tester);
    expect(find.text('¿Qué día prefieres?'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });

  testWidgets('next button is disabled until a date is selected',
      (tester) async {
    await pumpSheet(tester);
    final nextButton = find.widgetWithText(ElevatedButton, 'Siguiente');
    expect(nextButton, findsOneWidget);
    final ElevatedButton btn = tester.widget(nextButton);
    expect(btn.onPressed, isNull);
  });

  testWidgets('confirm path writes a pending appointment', (tester) async {
    final id = await repo.createAppointment(
      Appointment(
        id: '',
        therapistId: 't1',
        patientId: 'p1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 60,
        status: AppointmentStatus.pending,
        type: AppointmentType.presencial,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final doc = await fake.collection('appointments').doc(id).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['status'], 'pending');
    expect(doc.data()!['type'], 'presencial');
  });
}
