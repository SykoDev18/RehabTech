// Widget tests for therapist PatientsScreen.
//
// Scope: header + dashboard skeleton render, and the unauthenticated
// fallback branch ("No autenticado") inside `_buildPatientsList()`.
//
// Authenticated streams (patients-by-therapist filter, KPI counters) are
// covered as Firestore query contracts in
// test/data/firestore_query_contracts_test.dart.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehabtech/screens/therapist/patients_screen.dart';

import '../_helpers/firebase_test_setup.dart';

void _drain(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(
        path: '/screen',
        builder: (_, _) => const Scaffold(body: PatientsScreen()),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  _drain(tester);
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('PatientsScreen — header + skeleton', () {
    testWidgets('renders the "Pacientes" title and the search field',
        (tester) async {
      await _pump(tester);

      expect(find.text('Pacientes'), findsOneWidget);
      expect(find.text('Buscar paciente...'), findsOneWidget);
    });
  });

  group('PatientsScreen — unauthenticated state', () {
    testWidgets(
        'shows "No autenticado" when FirebaseAuth has no current user',
        (tester) async {
      await _pump(tester);

      // Inside `_buildPatientsList()` the screen falls back to a Center(Text)
      // when uid is null. We must not see the empty-list state here, since
      // that is reached after a successful Firestore query.
      expect(find.text('No autenticado'), findsOneWidget);
      expect(find.text('Sin pacientes aún'), findsNothing);
    });

    testWidgets('does NOT render any patient cards', (tester) async {
      await _pump(tester);

      // The card uses status badges with copy "Activo" / "Atención". Neither
      // should appear without a real authenticated stream.
      expect(find.text('Activo'), findsNothing);
      expect(find.text('Atención'), findsNothing);
    });
  });
}
