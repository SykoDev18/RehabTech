// Widget tests for MyRoutinesScreen.
//
// Scope: the unauthenticated render path. The screen reads
// `FirebaseAuth.instance.currentUser` synchronously inside `build()`, and
// when no user is signed in it short-circuits to a "Inicia sesión" message
// without ever subscribing to Firestore. That path is what we cover here.
//
// The authenticated path (StreamBuilder over `routines` collection) needs
// either dependency injection or the Firebase Emulator. Documented in
// docs/integration_tests_spec.md and covered indirectly by the Firestore
// query-contract tests in test/data/firestore_query_contracts_test.dart.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehabtech/screens/main/my_appointments_screen.dart';
import 'package:rehabtech/screens/main/my_routines_screen.dart';

import '../_helpers/firebase_test_setup.dart';

void _drain(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

GoRouter _routerFor(Widget screen) {
  return GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1024, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp.router(routerConfig: _routerFor(screen)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  _drain(tester);
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('MyRoutinesScreen — unauthenticated state', () {
    testWidgets(
        'shows the "Inicia sesión" hint when FirebaseAuth has no current user',
        (tester) async {
      await _pump(tester, const MyRoutinesScreen());

      // The screen short-circuits to a Center(Text(...)) before ever touching
      // Firestore. We assert on that exact copy.
      expect(
        find.text('Inicia sesión para ver tus rutinas'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT render the routines list or empty-state',
        (tester) async {
      await _pump(tester, const MyRoutinesScreen());

      // The "Sin rutinas asignadas" empty-state is only reachable after a
      // successful auth + Firestore snapshot — it must not appear here.
      expect(find.text('Sin rutinas asignadas'), findsNothing);
      expect(find.text('Mis Rutinas'), findsNothing);
    });

    testWidgets('builds inside a Scaffold with no progress indicator',
        (tester) async {
      await _pump(tester, const MyRoutinesScreen());

      expect(find.byType(Scaffold), findsOneWidget);
      // No CircularProgressIndicator until the StreamBuilder actually starts.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('MyAppointmentsScreen — unauthenticated state', () {
    testWidgets(
        'shows the "Inicia sesión" hint when FirebaseAuth has no current user',
        (tester) async {
      await _pump(tester, const MyAppointmentsScreen());

      expect(
        find.text('Inicia sesión para ver tus citas'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT render the appointments header or sections',
        (tester) async {
      await _pump(tester, const MyAppointmentsScreen());

      expect(find.text('Próximas'), findsNothing);
      expect(find.text('Pasadas'), findsNothing);
    });
  });
}
