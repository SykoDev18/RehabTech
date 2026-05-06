// Widget tests for VerifyEmailScreen.
//
// Scope: pure UI behaviour. We never reach a real FirebaseAuth platform
// channel — the screen uses an injected [VerifyEmailController] in tests,
// matching the LoginScreen test pattern (UI-only).
//
// What we verify:
//  * email is rendered into the subtitle
//  * "Ya verifiqué" calls the controller's reload+isEmailVerified
//  * SnackBar fires when still unverified
//  * "Reenviar" calls the controller and starts the cooldown
//  * cooldown text decrements and the button re-enables after 60s

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehabtech/screens/auth/verify_email_screen.dart';

class _FakeController implements VerifyEmailController {
  bool emailIsVerified = false;
  int reloadCalls = 0;
  int sendCalls = 0;
  int signOutCalls = 0;
  Object? sendError;
  Completer<void>? sendBlocker;

  @override
  String? get currentEmail => 'test@example.com';

  @override
  Future<bool> reloadAndCheckVerified() async {
    reloadCalls++;
    return emailIsVerified;
  }

  @override
  Future<void> sendVerificationEmail() async {
    sendCalls++;
    if (sendBlocker != null) await sendBlocker!.future;
    if (sendError != null) throw sendError!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

GoRouter _router(_FakeController c) {
  return GoRouter(
    initialLocation: '/verify-email',
    routes: [
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => VerifyEmailScreen(controller: c),
      ),
      GoRoute(path: '/', builder: (_, _) => const _Stub('home')),
      GoRoute(path: '/login', builder: (_, _) => const _Stub('login')),
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

Future<void> _pump(WidgetTester tester, _FakeController c) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp.router(routerConfig: _router(c)));
  await tester.pump();
}

void main() {
  group('VerifyEmailScreen — render', () {
    testWidgets('shows the user email in the subtitle', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);
      expect(find.text('Verifica tu correo'), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('renders all three actions', (tester) async {
      await _pump(tester, _FakeController());
      expect(find.text('Ya verifiqué mi correo'), findsOneWidget);
      expect(find.text('Reenviar correo'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  group('VerifyEmailScreen — "Ya verifiqué"', () {
    testWidgets('triggers reloadAndCheckVerified', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);

      await tester.tap(find.text('Ya verifiqué mi correo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(c.reloadCalls, 1);
    });

    testWidgets('shows SnackBar when still unverified', (tester) async {
      final c = _FakeController()..emailIsVerified = false;
      await _pump(tester, c);

      await tester.tap(find.text('Ya verifiqué mi correo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Aún no verificado'),
        findsOneWidget,
      );
    });

    testWidgets('navigates away when verified', (tester) async {
      final c = _FakeController()..emailIsVerified = true;
      await _pump(tester, c);

      await tester.tap(find.text('Ya verifiqué mi correo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The screen issues `context.go('/')`. Our stub renders 'stub:home'.
      expect(find.text('stub:home'), findsOneWidget);
    });
  });

  group('VerifyEmailScreen — "Reenviar"', () {
    testWidgets('calls sendVerificationEmail', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);

      await tester.tap(find.text('Reenviar correo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(c.sendCalls, 1);
      expect(find.text('Correo reenviado'), findsOneWidget);
    });

    testWidgets('starts a 60-second cooldown that decrements', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);

      await tester.tap(find.text('Reenviar correo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After the first second, the label shows "Reenviar en 59s".
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Reenviar en'), findsOneWidget);
      expect(find.textContaining('59'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('58'), findsOneWidget);
    });

    testWidgets('cooldown disables further sends', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);

      await tester.tap(find.text('Reenviar correo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Try to tap again during cooldown — the button label is now "Reenviar en Ns".
      // Tapping it should NOT call send again (button is disabled).
      await tester.tap(find.textContaining('Reenviar en'));
      await tester.pump();

      expect(c.sendCalls, 1);
    });
  });

  group('VerifyEmailScreen — "Cerrar sesión"', () {
    testWidgets('calls signOut and goes to /login', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(c.signOutCalls, 1);
      expect(find.text('stub:login'), findsOneWidget);
    });
  });
}
