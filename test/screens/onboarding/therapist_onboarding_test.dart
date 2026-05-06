// Widget tests for TherapistOnboardingScreen.
//
// We use FakeFirebaseFirestore so the "Continuar" / "Ir a mi panel" steps
// can write to the user doc without a network round-trip.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehabtech/screens/onboarding/therapist_onboarding_screen.dart';

const _uid = 'therapist-uid-1';

class _Stub extends StatelessWidget {
  const _Stub(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('stub:$label')));
}

GoRouter _router({
  required FakeFirebaseFirestore firestore,
  required MockFirebaseAuth auth,
}) {
  return GoRouter(
    initialLocation: '/therapist/onboarding',
    routes: [
      GoRoute(
        path: '/therapist/onboarding',
        builder: (_, _) => TherapistOnboardingScreen(
          firestore: firestore,
          auth: auth,
        ),
      ),
      GoRoute(
        path: '/therapist',
        builder: (_, _) => const _Stub('therapist-home'),
      ),
      GoRoute(
        path: '/license-verification',
        builder: (_, _) => const _Stub('license'),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeFirebaseFirestore firestore,
  required MockFirebaseAuth auth,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: _router(firestore: firestore, auth: auth),
  ));
  await tester.pump();
}

Future<void> _seedUserDoc(FakeFirebaseFirestore firestore) async {
  await firestore.collection('users').doc(_uid).set({
    'name': 'Marco',
    'lastName': 'Antonio',
    'email': 't@example.com',
    'userType': 'therapist',
    'licenseStatus': 'unverified',
    'createdAt': Timestamp.now(),
  });
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: _uid, email: 't@example.com'),
    );
    await _seedUserDoc(firestore);
  });

  group('TherapistOnboardingScreen — flow', () {
    testWidgets('starts at step 1 with welcome content', (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);
      expect(find.textContaining('Bienvenido'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
    });

    testWidgets('"Comenzar" advances to step 2 (profile)', (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(find.text('Completa tu perfil'), findsOneWidget);
      expect(find.text('Especialidad'), findsOneWidget);
    });

    testWidgets(
        'step 2 "Continuar" disabled until speciality + modality picked',
        (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      final continueBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuar'),
      );
      expect(continueBtn.onPressed, isNull,
          reason:
              'Continuar must be disabled until both dropdowns are picked');
    });

    testWidgets(
        'step 2 saves speciality and modality to Firestore on continue',
        (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      // Open speciality dropdown
      await tester
          .tap(find.byKey(const Key('therapist-onboarding-speciality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fisioterapia').last);
      await tester.pumpAndSettle();

      // Open modality dropdown
      await tester
          .tap(find.byKey(const Key('therapist-onboarding-modality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambas').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();

      final doc = await firestore.collection('users').doc(_uid).get();
      expect(doc.data()?['speciality'], 'Fisioterapia');
      expect(doc.data()?['modality'], 'Ambas');
    });

    testWidgets('"Verificar después" jumps from step 3 to step 4',
        (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);

      // step 1 → 2
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      // pick speciality + modality, advance to step 3
      await tester
          .tap(find.byKey(const Key('therapist-onboarding-speciality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fisioterapia').last);
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('therapist-onboarding-modality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Presencial').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();

      // step 3 — tap "Verificar después"
      expect(find.text('Verifica tu cédula'), findsOneWidget);
      await tester.tap(find.text('Verificar después'));
      await tester.pumpAndSettle();

      // step 4 — final
      expect(find.text('¡Todo listo!'), findsOneWidget);
    });

    testWidgets(
        'step 4 "Ir a mi panel" writes onboardingCompleted: true and navigates',
        (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);

      // step 1 → 2
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      // step 2 → 3
      await tester
          .tap(find.byKey(const Key('therapist-onboarding-speciality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otra').last);
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('therapist-onboarding-modality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Virtual').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();

      // step 3 → 4
      await tester.tap(find.text('Verificar después'));
      await tester.pumpAndSettle();

      // step 4
      await tester.tap(find.text('Ir a mi panel'));
      await tester.pumpAndSettle();

      final doc = await firestore.collection('users').doc(_uid).get();
      expect(doc.data()?['onboardingCompleted'], true);
      expect(find.text('stub:therapist-home'), findsOneWidget);
    });
  });
}
