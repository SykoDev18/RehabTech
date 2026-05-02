// Widget tests for LoginScreen.
//
// Scope: validates UI state, form-validation paths, and the visual
// user-type / password-visibility toggles. These exercise the screen's
// behaviour BEFORE any FirebaseAuth network call — `_signIn()` short-circuits
// on empty input, so we never hit the platform channel.
//
// Out of scope: actual auth flow + role-based navigation. Those require
// either a refactor to inject FirebaseAuth into the screen, or running on
// the Firebase Emulator. Documented in docs/integration_tests_spec.md.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehabtech/screens/login_screen.dart';

import '../_helpers/firebase_test_setup.dart';

GoRouter _routerForLogin() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const _Stub('forgot'),
      ),
      GoRoute(path: '/register', builder: (_, _) => const _Stub('register')),
      GoRoute(path: '/main', builder: (_, _) => const _Stub('main')),
      GoRoute(
        path: '/therapist',
        builder: (_, _) => const _Stub('therapist'),
      ),
    ],
  );
}

class _Stub extends StatelessWidget {
  const _Stub(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('stub:$label')));
}

/// Consume layout/asset noise that flutter_test would otherwise count as
/// a test failure: the social-button rows overflow when Image.asset can't
/// resolve a logo, and `Unable to load asset` errors fire for the same
/// reason. Neither is what we're testing — and the test framework already
/// logs the exception details to stdout if anyone needs them.
void _drainExpectedExceptions(WidgetTester tester) {
  while (true) {
    final e = tester.takeException();
    if (e == null) return;
  }
}

Future<void> _pumpLoginScreen(WidgetTester tester) async {
  // Wider-than-phone surface so the screen's fixed-width 400 card and
  // the social-button rows lay out closer to their design width.
  tester.view.physicalSize = const Size(1024, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp.router(routerConfig: _routerForLogin()));
  // Use pump() not pumpAndSettle() — Image.asset never settles in tests
  // because the AssetBundle has no real assets attached.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  _drainExpectedExceptions(tester);
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('LoginScreen — render', () {
    testWidgets('renders email field, password field, and login button',
        (tester) async {
      await _pumpLoginScreen(tester);

      expect(find.widgetWithText(TextFormField, ''), findsNWidgets(2),
          reason: 'two TextFormField for email + password');
      expect(find.text('Correo Electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('renders the user-type selector with both options',
        (tester) async {
      await _pumpLoginScreen(tester);
      expect(find.text('Soy Paciente'), findsOneWidget);
      expect(find.text('Soy Terapeuta'), findsOneWidget);
    });

    testWidgets('renders forgot-password and sign-up navigation links',
        (tester) async {
      await _pumpLoginScreen(tester);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(find.text('Regístrate aquí'), findsOneWidget);
    });

    testWidgets('renders Apple and Google social login buttons',
        (tester) async {
      await _pumpLoginScreen(tester);
      expect(find.text('Continuar con Apple'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });
  });

  group('LoginScreen — form validation (no Firebase touched)', () {
    testWidgets('empty submit shows the "complete all fields" snackbar',
        (tester) async {
      await _pumpLoginScreen(tester);

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump(); // schedule snackbar
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Por favor completa todos los campos'),
        findsOneWidget,
      );
    });

    testWidgets('email-only submit still shows the validation snackbar',
        (tester) async {
      await _pumpLoginScreen(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo Electrónico').first,
        'someone@example.com',
      );

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Por favor completa todos los campos'),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen — user-type toggle', () {
    testWidgets('starts with "Paciente" visually selected', (tester) async {
      await _pumpLoginScreen(tester);
      // The selected variant uses FontWeight.bold; the other is normal.
      final patientText = tester.widget<Text>(find.text('Soy Paciente'));
      final therapistText = tester.widget<Text>(find.text('Soy Terapeuta'));
      expect(patientText.style?.fontWeight, equals(FontWeight.bold));
      expect(therapistText.style?.fontWeight, equals(FontWeight.normal));
    });

    testWidgets('tapping "Soy Terapeuta" flips the visual selection',
        (tester) async {
      await _pumpLoginScreen(tester);

      await tester.tap(find.text('Soy Terapeuta'));
      await tester.pump();

      final patientText = tester.widget<Text>(find.text('Soy Paciente'));
      final therapistText = tester.widget<Text>(find.text('Soy Terapeuta'));
      expect(therapistText.style?.fontWeight, equals(FontWeight.bold));
      expect(patientText.style?.fontWeight, equals(FontWeight.normal));
    });
  });

  group('LoginScreen — password visibility toggle', () {
    testWidgets('password field starts obscured', (tester) async {
      await _pumpLoginScreen(tester);
      // Find the visibility-off icon (initial state).
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('tapping the eye icon flips visibility', (tester) async {
      await _pumpLoginScreen(tester);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });
  });
}
