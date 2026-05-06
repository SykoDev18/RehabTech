# Therapist & Patient Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the post-registration flow (register → email-verify → role-specific onboarding → home) hard-required for every new RehabTech user, without breaking offline behaviour or hard-blocking therapists when the SEP RNP is down.

**Architecture:** Reactive GoRouter `redirect` driven by a pure decision function (`computeRedirect`) that takes the current path + auth/Firestore state and returns the next route. The redirect callback gathers state (auth via `FirebaseAuth.instance`, Firestore via a cached lookup) and delegates the decision to that pure function — so router behaviour is unit-testable in isolation, and the existing offline-friendly cache pattern (`Source.cache → Source.server with timeout → fallback`) is preserved. Two new full-screen flows (`VerifyEmailScreen`, role-specific onboarding screens) plus minor edits to register/login/banner. A single new Firestore field on `users/{uid}` — `onboardingCompleted: bool` — gates the per-role onboarding once. The existing `TherapistUnverifiedBanner` keeps soft-blocking therapists with unverified/rejected licenses without ever blocking app access.

**Tech Stack:** Flutter 3.9+, GoRouter 17, Firebase Auth, Cloud Firestore, `provider 6.x` (existing pattern — no new state management), `firebase_auth_mocks` + `fake_cloud_firestore` + `fake_async` for tests (already in dev_dependencies).

---

## ⚠️ Schema reality

The spec uses field names that do **not** match the existing codebase. The audit established this. The plan uses the **actual** field names everywhere:

| Spec name | Real name in this repo |
|---|---|
| `role` | **`userType`** (`'patient' \| 'therapist'`) |
| `fullName` | **`name` + `lastName`** (split) |
| `photoURL` | **`photoUrl`** |
| `/intro` | **`/onboarding`** — already exists, leave alone |
| `intro_shown` SharedPreferences key | **`onboarding_completed`** — already exists, leave alone |
| `onboardingCompleted` (Firestore) | **new field** to be added on `users/{uid}` |

`firestore.rules` already permits owner writes to non-license fields, so no rule change is required for `onboardingCompleted`, `bio`, or `modality`.

## File structure

**New files:**
- `lib/core/utils/auth_error_messages.dart` — pure mapper from `FirebaseAuthException.code` → Spanish text. DRY across login + register + verify.
- `lib/router/redirect_logic.dart` — pure `computeRedirect(...)` function + `RouterInputs` struct. No Firebase imports.
- `lib/screens/auth/verify_email_screen.dart` — full-screen post-registration verification gate.
- `lib/screens/onboarding/therapist_onboarding_screen.dart` — 4-step PageView (welcome → profile → license CTA → done).
- `lib/screens/onboarding/patient_onboarding_screen.dart` — 4-step PageView (welcome → demographics → how-it-works → done).
- `test/core/utils/auth_error_messages_test.dart`
- `test/router/redirect_logic_test.dart`
- `test/screens/auth/verify_email_screen_test.dart`
- `test/screens/onboarding/therapist_onboarding_test.dart`

**Modified files:**
- `lib/router/app_router.dart` — add the three new routes, replace `redirect` body with a thin gatherer that calls `computeRedirect`, extend the cache to also cache `onboardingCompleted`, expose new helpers.
- `lib/screens/register_screen.dart` — write `licenseStatus: 'unverified'` for therapists, swap raw `e.message` for the auth-error mapper, surface a therapist-info banner under the user-type toggle, route to `/verify-email` on success.
- `lib/screens/login_screen.dart` — call `currentUser.reload()` after sign-in, swap `_getErrorMessage` body for the shared mapper, replace manual role-routing with a single `context.go('/')` (lets the redirect resolve).
- `lib/widgets/therapist_unverified_banner.dart` — also fire for `LicenseStatus.rejected` (1-line change + test note).

**Untouched (already correct):**
- `lib/screens/onboarding/onboarding_screen.dart` — handles the spec's STEP 8 (app intro) already.
- `lib/screens/profile/therapist/license_verification_screen.dart` — works as designed.
- `firestore.rules` — current rules already allow owner writes to non-license user fields.

## Design decisions worth knowing

1. **Single Firestore boolean for both roles' onboarding.** A new field `onboardingCompleted: bool` on `users/{uid}` works for therapist and patient because the redirect picks which onboarding screen to send the user to based on `userType`. Two booleans would be redundant — `userType` is fixed at registration.
2. **`emailVerified` is never cached.** It's already in memory on `FirebaseAuth.instance.currentUser`. We only need to call `reload()` at strategic points (on sign-in, when the verify-email screen polls).
3. **Pure-function redirect logic.** Test surface is a function with `({String currentPath, bool isLoggedIn, bool emailVerified, String? userType, bool? onboardingCompleted, bool appIntroDone})` → `String?`. The `redirect` callback gathers, the function decides. No GoRouter mocking, no FirebaseAuth mocking in the redirect tests.
4. **Cache invalidation.** `AppRouter.clearUserTypeCache()` is already called from `goToLogin()`. We extend it to `clearAuthCache()` — clears userType + onboardingCompleted together — and update all call sites. This avoids the cache going stale on logout.
5. **The therapist info banner under the user-type toggle is part of register, not a new screen.** Spec lists it under STEP 1.3 — implementing it inline keeps the registration single-screen. No separate "are you sure you're a therapist" gate.
6. **`context.go('/')` after login**, not manual role-routing. The redirect knows where to send each user; duplicating that knowledge in `_navigateAfterLogin` is what created the gap in the first place.
7. **Lottie not added.** The spec says "checkmark animation" — we use `TweenAnimationBuilder<double>` driving an `Icons.check_circle` scale-in. No new dependency.

---

## Pre-flight

- [ ] **Step 0.1: Confirm baseline analyze is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 0.2: Confirm baseline tests pass**

Run: `flutter test`
Expected: All existing tests pass (this is a green-baseline checkpoint — if anything is already red, capture it before adding new code).

---

## Task 1: Auth error message mapper

**Why first:** Pure utility used by 3 screens. TDD-friendly. Zero deps. Establishes the Spanish message catalog before screens consume it.

**Files:**
- Create: `lib/core/utils/auth_error_messages.dart`
- Test: `test/core/utils/auth_error_messages_test.dart`

- [ ] **Step 1.1: Write the failing test**

Create `test/core/utils/auth_error_messages_test.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/core/utils/auth_error_messages.dart';

FirebaseAuthException _exc(String code, [String? message]) =>
    FirebaseAuthException(code: code, message: message);

void main() {
  group('mapSignInError', () {
    test('user-not-found returns Spanish "no existe" message', () {
      expect(
        mapSignInError(_exc('user-not-found')),
        'No existe una cuenta con este correo.',
      );
    });

    test('wrong-password and invalid-credential map to the same message', () {
      expect(
        mapSignInError(_exc('wrong-password')),
        'Contraseña incorrecta.',
      );
      expect(
        mapSignInError(_exc('invalid-credential')),
        'Contraseña incorrecta.',
      );
    });

    test('user-disabled mentions support contact', () {
      final m = mapSignInError(_exc('user-disabled'));
      expect(m, contains('desactivada'));
      expect(m, contains('soporte'));
    });

    test('too-many-requests asks user to wait', () {
      expect(
        mapSignInError(_exc('too-many-requests')),
        'Demasiados intentos. Espera unos minutos.',
      );
    });

    test('network-request-failed mentions internet', () {
      expect(
        mapSignInError(_exc('network-request-failed')),
        'Sin conexión. Verifica tu internet.',
      );
    });

    test('unknown code returns generic Spanish fallback', () {
      expect(
        mapSignInError(_exc('something-weird')),
        'Error al iniciar sesión. Intenta de nuevo.',
      );
    });
  });

  group('mapSignUpError', () {
    test('email-already-in-use suggests signing in', () {
      final m = mapSignUpError(_exc('email-already-in-use'));
      expect(m, contains('ya tiene una cuenta'));
    });

    test('weak-password mentions length', () {
      expect(
        mapSignUpError(_exc('weak-password')),
        'La contraseña es muy débil. Usa al menos 8 caracteres.',
      );
    });

    test('invalid-email is mapped', () {
      expect(
        mapSignUpError(_exc('invalid-email')),
        'El formato del correo no es válido.',
      );
    });

    test('network-request-failed mentions internet', () {
      expect(
        mapSignUpError(_exc('network-request-failed')),
        'Sin conexión. Verifica tu internet e intenta de nuevo.',
      );
    });

    test('unknown code returns generic Spanish fallback', () {
      expect(
        mapSignUpError(_exc('weirdness')),
        'Error al crear la cuenta. Intenta de nuevo.',
      );
    });
  });

  group('mapResendVerificationError', () {
    test('too-many-requests is mapped to wait message', () {
      expect(
        mapResendVerificationError(_exc('too-many-requests')),
        'Has solicitado demasiados correos. Espera unos minutos.',
      );
    });

    test('unknown code returns generic resend-failed Spanish', () {
      expect(
        mapResendVerificationError(_exc('whatever')),
        'No se pudo reenviar el correo. Intenta de nuevo.',
      );
    });
  });
}
```

- [ ] **Step 1.2: Run the test — confirm it fails**

Run: `flutter test test/core/utils/auth_error_messages_test.dart`
Expected: All tests fail with compilation errors (target file does not exist yet).

- [ ] **Step 1.3: Implement the mapper**

Create `lib/core/utils/auth_error_messages.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';

/// Spanish-language mappers for Firebase Auth error codes.
///
/// Three call sites use these:
///  * Login → [mapSignInError]
///  * Register → [mapSignUpError]
///  * Verify-email "Reenviar" → [mapResendVerificationError]
///
/// Anything not in the switch returns a friendly generic message — never
/// the raw Firebase string, which leaks English UX into the Spanish app.

String mapSignInError(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No existe una cuenta con este correo.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Contraseña incorrecta.';
    case 'invalid-email':
      return 'El formato del correo no es válido.';
    case 'user-disabled':
      return 'Esta cuenta ha sido desactivada. Contacta a soporte.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera unos minutos.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet.';
    default:
      return 'Error al iniciar sesión. Intenta de nuevo.';
  }
}

String mapSignUpError(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'Este correo ya tiene una cuenta. ¿Quieres iniciar sesión?';
    case 'weak-password':
      return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
    case 'invalid-email':
      return 'El formato del correo no es válido.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    default:
      return 'Error al crear la cuenta. Intenta de nuevo.';
  }
}

String mapResendVerificationError(FirebaseAuthException e) {
  switch (e.code) {
    case 'too-many-requests':
      return 'Has solicitado demasiados correos. Espera unos minutos.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet.';
    default:
      return 'No se pudo reenviar el correo. Intenta de nuevo.';
  }
}
```

- [ ] **Step 1.4: Run the test — confirm it passes**

Run: `flutter test test/core/utils/auth_error_messages_test.dart`
Expected: All 13 tests pass.

- [ ] **Step 1.5: Run analyze**

Run: `flutter analyze lib/core/utils/auth_error_messages.dart test/core/utils/auth_error_messages_test.dart`
Expected: No issues found.

- [ ] **Step 1.6: Commit**

```bash
git add lib/core/utils/auth_error_messages.dart test/core/utils/auth_error_messages_test.dart
git commit -m "feat(auth): add Spanish error-message mapper for sign-in/sign-up/resend"
```

---

## Task 2: Pure redirect-decision function

**Why second:** Lets us test every routing rule (Step 3 in the spec) without GoRouter, FirebaseAuth, or Firestore mocks. Once green, the actual `redirect` callback in Task 7 just gathers inputs and delegates here.

**Files:**
- Create: `lib/router/redirect_logic.dart`
- Test: `test/router/redirect_logic_test.dart`

- [ ] **Step 2.1: Write the failing tests**

Create `test/router/redirect_logic_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/router/redirect_logic.dart';

RouterInputs _i({
  String currentPath = '/',
  bool isLoggedIn = false,
  bool emailVerified = false,
  String? userType,
  bool? onboardingCompleted,
  bool appIntroDone = true,
}) {
  return RouterInputs(
    currentPath: currentPath,
    isLoggedIn: isLoggedIn,
    emailVerified: emailVerified,
    userType: userType,
    onboardingCompleted: onboardingCompleted,
    appIntroDone: appIntroDone,
  );
}

void main() {
  group('app intro gate (logged out)', () {
    test('intro not done & not on /onboarding → /onboarding', () {
      expect(
        computeRedirect(_i(appIntroDone: false, currentPath: '/login')),
        '/onboarding',
      );
    });

    test('intro done & on /onboarding → /login', () {
      expect(
        computeRedirect(_i(appIntroDone: true, currentPath: '/onboarding')),
        '/login',
      );
    });

    test('intro not done & already on /onboarding → null', () {
      expect(
        computeRedirect(_i(appIntroDone: false, currentPath: '/onboarding')),
        isNull,
      );
    });

    test('logged-in users skip the intro gate', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: true,
          appIntroDone: false,
          currentPath: '/therapist',
        )),
        isNull,
      );
    });
  });

  group('unauthenticated', () {
    test('not logged in & not on auth route → /login', () {
      expect(
        computeRedirect(_i(currentPath: '/main')),
        '/login',
      );
    });

    test('not logged in & on /login → null', () {
      expect(computeRedirect(_i(currentPath: '/login')), isNull);
    });

    test('not logged in & on /register → null', () {
      expect(computeRedirect(_i(currentPath: '/register')), isNull);
    });

    test('not logged in & on /forgot-password → null', () {
      expect(computeRedirect(_i(currentPath: '/forgot-password')), isNull);
    });
  });

  group('email verification gate', () {
    test('logged in & email NOT verified & not on /verify-email → /verify-email',
        () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: false,
          currentPath: '/main',
        )),
        '/verify-email',
      );
    });

    test('logged in & email NOT verified & already on /verify-email → null',
        () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: false,
          currentPath: '/verify-email',
        )),
        isNull,
      );
    });

    test('logged in & email verified & on /verify-email → role home (therapist)',
        () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: true,
          currentPath: '/verify-email',
        )),
        '/therapist',
      );
    });

    test('logged in & email verified & on /verify-email → role home (patient)',
        () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'patient',
          onboardingCompleted: true,
          currentPath: '/verify-email',
        )),
        '/main',
      );
    });
  });

  group('per-role onboarding gate', () {
    test('therapist with onboarding NOT done & not on therapist onboarding → /therapist/onboarding',
        () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: false,
          currentPath: '/therapist',
        )),
        '/therapist/onboarding',
      );
    });

    test('patient with onboarding NOT done & not on patient onboarding → /patient/onboarding',
        () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'patient',
          onboardingCompleted: false,
          currentPath: '/main',
        )),
        '/patient/onboarding',
      );
    });

    test('therapist already on /therapist/onboarding → null', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: false,
          currentPath: '/therapist/onboarding',
        )),
        isNull,
      );
    });

    test('therapist allowed to reach /license-verification mid-onboarding', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: false,
          currentPath: '/license-verification',
        )),
        isNull,
      );
    });

    test('therapist with onboarding done & on /therapist → null', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: true,
          currentPath: '/therapist',
        )),
        isNull,
      );
    });

    test('userType still resolving (null) does NOT trigger onboarding gate', () {
      // Cache miss/Firestore offline — don't bounce the user; let next nav resolve.
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: null,
          onboardingCompleted: null,
          currentPath: '/main',
        )),
        isNull,
      );
    });
  });

  group('post-login bounce', () {
    test('logged in & verified & at /login → role home', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: true,
          currentPath: '/login',
        )),
        '/therapist',
      );
    });

    test('logged in & verified & at /register → role home', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'patient',
          onboardingCompleted: true,
          currentPath: '/register',
        )),
        '/main',
      );
    });

    test('logged in & verified & at / → role home', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'patient',
          onboardingCompleted: true,
          currentPath: '/',
        )),
        '/main',
      );
    });
  });

  group('happy paths', () {
    test('therapist verified, onboarded, on /therapist → null', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'therapist',
          onboardingCompleted: true,
          currentPath: '/therapist',
        )),
        isNull,
      );
    });

    test('patient verified, onboarded, on /main/exercise/foo → null', () {
      expect(
        computeRedirect(_i(
          isLoggedIn: true,
          emailVerified: true,
          userType: 'patient',
          onboardingCompleted: true,
          currentPath: '/main/exercise/foo',
        )),
        isNull,
      );
    });
  });
}
```

- [ ] **Step 2.2: Run the test — confirm it fails**

Run: `flutter test test/router/redirect_logic_test.dart`
Expected: Compilation errors (target file does not exist).

- [ ] **Step 2.3: Implement the pure function**

Create `lib/router/redirect_logic.dart`:

```dart
/// Pure-function redirect decision for the GoRouter `redirect` callback.
///
/// Holding the rules in a function with no Firebase imports lets us unit-test
/// every branch without mocking. The actual callback in [AppRouter.router]
/// gathers state (auth + Firestore) and delegates here.

class RouterInputs {
  final String currentPath;
  final bool isLoggedIn;
  final bool emailVerified;

  /// `'patient' | 'therapist' | null`. `null` means the lookup is still in
  /// flight or Firestore was unreachable — we treat it as "do not gate" so
  /// users on cold starts never see a redirect loop while the doc loads.
  final String? userType;

  /// `null` when the user doc hasn't loaded yet (same offline-friendly story
  /// as [userType]). `false` means the user is registered but has not
  /// finished the role-specific onboarding screen.
  final bool? onboardingCompleted;

  /// Whether the one-time app-intro carousel has been completed (stored in
  /// SharedPreferences, not Firestore).
  final bool appIntroDone;

  const RouterInputs({
    required this.currentPath,
    required this.isLoggedIn,
    required this.emailVerified,
    required this.userType,
    required this.onboardingCompleted,
    required this.appIntroDone,
  });
}

const _authRoutes = <String>{
  '/login',
  '/register',
  '/forgot-password',
  '/',
};

const _onboardingPaths = <String>{
  '/onboarding',
  '/verify-email',
  '/therapist/onboarding',
  '/patient/onboarding',
};

/// Returns the path to redirect to, or `null` to allow [currentPath].
String? computeRedirect(RouterInputs i) {
  // 1. App-intro gate — only applies to logged-out users.
  if (!i.isLoggedIn) {
    if (!i.appIntroDone) {
      return i.currentPath == '/onboarding' ? null : '/onboarding';
    }
    if (i.currentPath == '/onboarding') return '/login';
    if (!_authRoutes.contains(i.currentPath)) return '/login';
    return null;
  }

  // 2. Email-verification gate — health-app safety: ALL therapists must
  //    verify their email; we apply the same gate to patients for parity.
  if (!i.emailVerified) {
    if (i.currentPath == '/verify-email') return null;
    return '/verify-email';
  }

  // 3. User doc is still loading — never redirect; let the next navigation
  //    re-evaluate once the cache has populated. This avoids spinning the
  //    user on cold starts with spotty connectivity.
  final userType = i.userType;
  final onboardingDone = i.onboardingCompleted;
  if (userType == null || onboardingDone == null) {
    // Still bounce post-auth pages to a home-ish placeholder so users don't
    // get stuck on /login while we wait for the doc.
    if (_authRoutes.contains(i.currentPath) ||
        i.currentPath == '/verify-email') {
      // Default to patient home — getUserType() falls back to 'patient'
      // anyway, so this is consistent.
      return '/main';
    }
    return null;
  }

  final roleHome = userType == 'therapist' ? '/therapist' : '/main';

  // 4. Per-role onboarding gate — once per user, gated by Firestore field.
  if (!onboardingDone) {
    final required =
        userType == 'therapist' ? '/therapist/onboarding' : '/patient/onboarding';
    if (i.currentPath == required) return null;
    // Allow the license-verification screen mid-onboarding (the therapist
    // onboarding's "Verificar ahora" button navigates there and back).
    if (i.currentPath == '/license-verification') return null;
    return required;
  }

  // 5. Logged in & fully set up — bounce away from auth/onboarding routes.
  if (_authRoutes.contains(i.currentPath) ||
      _onboardingPaths.contains(i.currentPath)) {
    return roleHome;
  }

  return null;
}
```

- [ ] **Step 2.4: Run the test — confirm it passes**

Run: `flutter test test/router/redirect_logic_test.dart`
Expected: All ~22 tests pass.

- [ ] **Step 2.5: Run analyze**

Run: `flutter analyze lib/router/redirect_logic.dart test/router/redirect_logic_test.dart`
Expected: No issues found.

- [ ] **Step 2.6: Commit**

```bash
git add lib/router/redirect_logic.dart test/router/redirect_logic_test.dart
git commit -m "feat(router): add pure computeRedirect decision function with unit tests"
```

---

## Task 3: Verify-email screen

**Why before touching the router:** building the screen first means the router task has a real target to wire to.

**Files:**
- Create: `lib/screens/auth/verify_email_screen.dart`
- Test: `test/screens/auth/verify_email_screen_test.dart`

- [ ] **Step 3.1: Write the failing test**

Create `test/screens/auth/verify_email_screen_test.dart`:

```dart
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

      // We don't pump 60 seconds — that's the next test.
    });

    testWidgets('cooldown disables further sends', (tester) async {
      final c = _FakeController();
      await _pump(tester, c);

      await tester.tap(find.text('Reenviar correo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Try to tap again during cooldown — the button label is now "Reenviar en Ns".
      // tapping it should NOT call send again.
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
```

- [ ] **Step 3.2: Run the test — confirm it fails**

Run: `flutter test test/screens/auth/verify_email_screen_test.dart`
Expected: Compilation errors (target file not yet created).

- [ ] **Step 3.3: Implement the screen**

Create `lib/screens/auth/verify_email_screen.dart`:

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rehabtech/core/utils/auth_error_messages.dart';
import 'package:rehabtech/router/app_router.dart';

/// Indirection layer over FirebaseAuth so widget tests can drive the screen
/// without touching the platform channel. Production wiring uses
/// [_FirebaseVerifyEmailController]; tests inject a fake.
abstract class VerifyEmailController {
  String? get currentEmail;
  Future<bool> reloadAndCheckVerified();
  Future<void> sendVerificationEmail();
  Future<void> signOut();
}

class _FirebaseVerifyEmailController implements VerifyEmailController {
  @override
  String? get currentEmail => FirebaseAuth.instance.currentUser?.email;

  @override
  Future<bool> reloadAndCheckVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendVerificationEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> signOut() async {
    AppRouter.clearAuthCache();
    await FirebaseAuth.instance.signOut();
  }
}

class VerifyEmailScreen extends StatefulWidget {
  /// Optional in production — defaults to a controller that talks to
  /// FirebaseAuth. Tests pass a fake.
  final VerifyEmailController? controller;

  const VerifyEmailScreen({super.key, this.controller});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final VerifyEmailController _controller;
  bool _isChecking = false;
  bool _isResending = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _FirebaseVerifyEmailController();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final verified = await _controller.reloadAndCheckVerified();
      if (!mounted) return;
      if (verified) {
        // Router redirect will route to the right home (or onboarding) based
        // on userType + onboardingCompleted.
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aún no verificado. Revisa tu correo y toca el enlace primero.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _controller.sendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo reenviado')),
      );
      _startCooldown(60);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapResendVerificationError(e))),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _logout() async {
    await _controller.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = _controller.currentEmail ?? 'tu correo';
    final cooldownActive = _cooldownSeconds > 0;
    final resendLabel =
        cooldownActive ? 'Reenviar en ${_cooldownSeconds}s' : 'Reenviar correo';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: scheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Verifica tu correo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Enviamos un enlace a\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          '\nRevisa tu bandeja de entrada (y la carpeta de spam).',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isChecking ? null : _checkVerification,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Ya verifiqué mi correo'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: cooldownActive || _isResending ? null : _resendEmail,
                child: Text(resendLabel),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _logout,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                child: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Problemas? Contáctanos en soporte@rehabtech.mx',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

> **Note:** This file references `AppRouter.clearAuthCache()`, which doesn't exist yet — Task 7 introduces it. Until then, `flutter analyze` on this file alone will warn. We accept the warning here and clear it in Task 7.

- [ ] **Step 3.4: Run the test — expect partial failure**

Run: `flutter test test/screens/auth/verify_email_screen_test.dart`
Expected: All tests pass *except* possibly the "Cerrar sesión" test if `clearAuthCache` blows up at construction. If they all pass: skip ahead. If they fail because of `clearAuthCache`: temporarily comment that one line in the controller, re-run, confirm green, then UNCOMMENT the line — Task 7 brings the symbol into existence and we'll re-run.

If the analyzer flags `clearAuthCache` as undefined now, leave it — Task 7 will close the loop.

- [ ] **Step 3.5: Commit**

```bash
git add lib/screens/auth/verify_email_screen.dart test/screens/auth/verify_email_screen_test.dart
git commit -m "feat(auth): add VerifyEmailScreen with cooldown timer and injectable controller"
```

---

## Task 4: Therapist onboarding screen

**Why now:** independent file, doesn't touch the router. Once landed, Task 7 wires its route.

**Files:**
- Create: `lib/screens/onboarding/therapist_onboarding_screen.dart`
- Test: `test/screens/onboarding/therapist_onboarding_test.dart`

- [ ] **Step 4.1: Write the failing test**

Create `test/screens/onboarding/therapist_onboarding_test.dart`:

```dart
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

    testWidgets('step 2 "Continuar" disabled until speciality + modality picked',
        (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      final continueBtn =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'));
      expect(continueBtn.onPressed, isNull,
          reason: 'Continuar must be disabled until both dropdowns are picked');
    });

    testWidgets('step 2 saves speciality and modality to Firestore on continue',
        (tester) async {
      await _pump(tester, firestore: firestore, auth: auth);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      // Open speciality dropdown
      await tester.tap(find.byKey(const Key('therapist-onboarding-speciality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fisioterapia').last);
      await tester.pumpAndSettle();

      // Open modality dropdown
      await tester.tap(find.byKey(const Key('therapist-onboarding-modality')));
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
      await tester.tap(find.byKey(const Key('therapist-onboarding-speciality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fisioterapia').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('therapist-onboarding-modality')));
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
      await tester.tap(find.byKey(const Key('therapist-onboarding-speciality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otra').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('therapist-onboarding-modality')));
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
```

- [ ] **Step 4.2: Run the test — confirm it fails**

Run: `flutter test test/screens/onboarding/therapist_onboarding_test.dart`
Expected: Compilation errors (target file doesn't exist).

- [ ] **Step 4.3: Implement the screen**

Create `lib/screens/onboarding/therapist_onboarding_screen.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rehabtech/router/app_router.dart';

const _kSpecialities = <String>[
  'Fisioterapia',
  'Rehabilitación Física',
  'Kinesiología',
  'Terapia Física',
  'Terapia Ocupacional',
  'Otra',
];

const _kModalities = <String>['Presencial', 'Virtual', 'Ambas'];

/// Four-step welcome flow shown once for newly registered therapists.
/// Gated by `users/{uid}.onboardingCompleted` — the GoRouter redirect
/// pushes therapists here until that flag is `true`.
class TherapistOnboardingScreen extends StatefulWidget {
  /// Optional injection seams for tests; production wiring uses the global
  /// singletons.
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const TherapistOnboardingScreen({super.key, this.firestore, this.auth});

  @override
  State<TherapistOnboardingScreen> createState() =>
      _TherapistOnboardingScreenState();
}

class _TherapistOnboardingScreenState extends State<TherapistOnboardingScreen> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final PageController _pageController = PageController();
  int _step = 0;

  String? _speciality;
  String? _modality;
  final TextEditingController _bioController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _saveProfileAndAdvance() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_speciality == null || _modality == null) return;

    setState(() => _saving = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'speciality': _speciality,
        'modality': _modality,
        if (_bioController.text.trim().isNotEmpty)
          'bio': _bioController.text.trim(),
      });
      if (!mounted) return;
      await _goTo(2);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'onboardingCompleted': true,
      });
      AppRouter.markUserOnboardingCompleted();
      if (!mounted) return;
      context.go('/therapist');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomeStep(),
            _buildProfileStep(),
            _buildLicenseStep(),
            _buildDoneStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(LucideIcons.heartPulse, size: 96, color: Color(0xFF2563EB)),
          const SizedBox(height: 32),
          Text(
            '¡Bienvenido a RehabTech!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'La plataforma que conecta fisioterapeutas con sus pacientes.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => _goTo(1),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    final canContinue =
        !_saving && _speciality != null && _modality != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Completa tu perfil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Tus pacientes verán esta información'),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              key: const Key('therapist-onboarding-speciality'),
              initialValue: _speciality,
              decoration: const InputDecoration(
                labelText: 'Especialidad',
                border: OutlineInputBorder(),
              ),
              items: _kSpecialities
                  .map((s) =>
                      DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _speciality = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio profesional (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Hasta 300 caracteres',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('therapist-onboarding-modality'),
              initialValue: _modality,
              decoration: const InputDecoration(
                labelText: 'Modalidad',
                border: OutlineInputBorder(),
              ),
              items: _kModalities
                  .map((s) =>
                      DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _modality = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: canContinue ? _saveProfileAndAdvance : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(LucideIcons.shieldCheck,
              size: 80, color: Color(0xFF2563EB)),
          const SizedBox(height: 24),
          Text(
            'Verifica tu cédula',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tus pacientes podrán ver que eres un profesional certificado '
            'por la SEP. El proceso toma menos de 1 minuto.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => context.go('/license-verification'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Verificar ahora'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _goTo(3),
            child: const Text('Verificar después'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, scale, _) => Transform.scale(
              scale: scale,
              child: const Icon(
                Icons.check_circle,
                size: 120,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Todo listo!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Puedes verificar tu cédula en cualquier momento desde tu perfil. '
            'Los pacientes verán un aviso hasta que la verifiques.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: _saving ? null : _finish,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Ir a mi panel'),
          ),
        ],
      ),
    );
  }
}
```

> **Same caveat as Task 3:** this references `AppRouter.markUserOnboardingCompleted()`, introduced in Task 7. The widget tests don't navigate after `_finish()` until that exists, but the test asserts the Firestore write only — so it should already pass. The analyzer will flag the symbol — that's fine; Task 7 closes the loop.

- [ ] **Step 4.4: Run the test — confirm it passes**

Run: `flutter test test/screens/onboarding/therapist_onboarding_test.dart`
Expected: All ~6 tests pass. If `markUserOnboardingCompleted` is undefined, the screen file may not compile — in that case temporarily comment that single line, re-run tests, confirm green, and uncomment. Task 7 brings the symbol into existence.

- [ ] **Step 4.5: Commit**

```bash
git add lib/screens/onboarding/therapist_onboarding_screen.dart test/screens/onboarding/therapist_onboarding_test.dart
git commit -m "feat(onboarding): add four-step TherapistOnboardingScreen with profile + license CTA"
```

---

## Task 5: Patient onboarding screen

**Files:**
- Create: `lib/screens/onboarding/patient_onboarding_screen.dart`

> **No dedicated test file** — the spec didn't mandate one and the structural patterns are identical to the therapist screen, which has a thorough widget test. We get coverage on the shared shape from there.

- [ ] **Step 5.1: Implement the screen**

Create `lib/screens/onboarding/patient_onboarding_screen.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rehabtech/router/app_router.dart';

/// Four-step welcome flow for newly registered patients.
class PatientOnboardingScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const PatientOnboardingScreen({super.key, this.firestore, this.auth});

  @override
  State<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final PageController _pageController = PageController();
  int _step = 0;

  DateTime? _dob;
  final TextEditingController _condition = TextEditingController();
  final TextEditingController _emergencyName = TextEditingController();
  final TextEditingController _emergencyPhone = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _condition.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _saveProfileAndAdvance({required bool skip}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{};
      if (!skip) {
        if (_dob != null) updates['dob'] = Timestamp.fromDate(_dob!);
        if (_condition.text.trim().isNotEmpty) {
          updates['condition'] = _condition.text.trim();
        }
        if (_emergencyName.text.trim().isNotEmpty) {
          updates['emergencyContactName'] = _emergencyName.text.trim();
        }
        if (_emergencyPhone.text.trim().isNotEmpty) {
          updates['emergencyContactPhone'] = _emergencyPhone.text.trim();
        }
      }
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
      if (!mounted) return;
      await _goTo(2);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'onboardingCompleted': true,
      });
      AppRouter.markUserOnboardingCompleted();
      if (!mounted) return;
      context.go('/main');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcome(),
            _buildProfile(),
            _buildHowItWorks(),
            _buildDone(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(LucideIcons.heartPulse, size: 96, color: Color(0xFF2563EB)),
          const SizedBox(height: 32),
          Text(
            '¡Bienvenido a RehabTech!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu compañero en la rehabilitación física.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => _goTo(1),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final dobLabel = _dob == null
        ? 'Selecciona tu fecha de nacimiento'
        : DateFormat('dd/MM/yyyy').format(_dob!);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Cuéntanos un poco',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Tu terapeuta verá esta información (todo es opcional)'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDob,
              icon: const Icon(LucideIcons.calendar),
              label: Text(dobLabel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _condition,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Condición o motivo de rehabilitación',
                hintText: 'Ej. Lesión de rodilla, dolor lumbar...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyName,
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia — nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyPhone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia — teléfono',
                helperText: '10 dígitos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _saveProfileAndAdvance(skip: false),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continuar'),
            ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => _saveProfileAndAdvance(skip: true),
              child: const Text('Omitir por ahora'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            '¿Cómo funciona RehabTech?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          _featureCard(
            icon: LucideIcons.dumbbell,
            title: 'Tus rutinas',
            body: 'Tu terapeuta te asignará ejercicios personalizados.',
          ),
          const SizedBox(height: 12),
          _featureCard(
            icon: LucideIcons.sparkles,
            title: 'Nora, tu asistente',
            body: 'Pregúntale a Nora sobre tus ejercicios y dolor.',
          ),
          const SizedBox(height: 12),
          _featureCard(
            icon: LucideIcons.calendar,
            title: 'Tus citas',
            body: 'Agenda y gestiona tus citas directamente en la app.',
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => _goTo(3),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF2563EB)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, scale, _) => Transform.scale(
              scale: scale,
              child: const Icon(
                Icons.check_circle,
                size: 120,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Listo para comenzar!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _saving ? null : _finish,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Ir a mi panel'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5.2: Run analyze (file may flag `markUserOnboardingCompleted` until Task 7)**

Run: `flutter analyze lib/screens/onboarding/patient_onboarding_screen.dart`
Expected: At worst, an `undefined_method` for `markUserOnboardingCompleted` — that resolves in Task 7.

- [ ] **Step 5.3: Commit**

```bash
git add lib/screens/onboarding/patient_onboarding_screen.dart
git commit -m "feat(onboarding): add four-step PatientOnboardingScreen with optional demographics"
```

---

## Task 6: Make TherapistUnverifiedBanner also fire for `rejected`

**Files:**
- Modify: `lib/widgets/therapist_unverified_banner.dart`

- [ ] **Step 6.1: Edit the visibility check**

In `lib/widgets/therapist_unverified_banner.dart`, find the line:

```dart
        if (license.status != LicenseStatus.unverified) {
          return const SizedBox.shrink();
        }
```

Replace it with:

```dart
        // Also surface the prompt for `rejected` therapists — the spec keeps
        // them out of `pending`/`manual_review`/`verified` (those have their
        // own UI) but stranded `rejected` therapists otherwise see no banner.
        final status = license.status;
        if (status != LicenseStatus.unverified &&
            status != LicenseStatus.rejected) {
          return const SizedBox.shrink();
        }
```

- [ ] **Step 6.2: Run analyze**

Run: `flutter analyze lib/widgets/therapist_unverified_banner.dart`
Expected: No issues found.

- [ ] **Step 6.3: Run the existing banner test (if any)**

The repo has no dedicated banner test. Smoke through the existing therapist screens by running their tests:

Run: `flutter test test/widgets/patients_screen_test.dart`
Expected: All pass — the banner is just a child of the shell and shouldn't break the patient list.

- [ ] **Step 6.4: Commit**

```bash
git add lib/widgets/therapist_unverified_banner.dart
git commit -m "fix(banner): show TherapistUnverifiedBanner for rejected status as well"
```

---

## Task 7: Wire the new redirect, routes, and cache into AppRouter

**This is the linchpin task.** It introduces the symbols Tasks 3-5 reference (`clearAuthCache`, `markUserOnboardingCompleted`), so once it lands the analyzer goes back to clean.

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 7.1: Add new imports at the top of the file**

In `lib/router/app_router.dart`, locate the existing import block (lines 1-33). Add two new imports:

```dart
import 'package:rehabtech/router/redirect_logic.dart';
import 'package:rehabtech/screens/auth/verify_email_screen.dart';
import 'package:rehabtech/screens/onboarding/therapist_onboarding_screen.dart';
import 'package:rehabtech/screens/onboarding/patient_onboarding_screen.dart';
```

- [ ] **Step 7.2: Replace the cache + lookup helpers**

Find this block in `AppRouter` (lines ~38-107):

```dart
  // Variable para cachear el tipo de usuario
  static String? _cachedUserType;

  // Cache del flag de onboarding para evitar leer SharedPreferences en
  // cada redirect. Se invalida via [markOnboardingCompleted].
  static bool? _cachedOnboardingDone;

  // Función para obtener el tipo de usuario.
  ...
  static Future<String?> getUserType() async { ... }

  // Limpiar cache al cerrar sesión
  static void clearUserTypeCache() {
    _cachedUserType = null;
  }

  /// Lee (y cachea) el flag de onboarding desde SharedPreferences.
  static Future<bool> isOnboardingCompleted() async { ... }

  /// Llamar tras finalizar el onboarding ...
  static void markOnboardingCompleted() {
    _cachedOnboardingDone = true;
  }
```

Replace it with this expanded version (preserves the offline-friendly behaviour but also caches the per-user `onboardingCompleted` flag from Firestore):

```dart
  // ─────────────────── User-doc cache ───────────────────
  //
  // The redirect callback runs on every navigation, including push() within
  // a screen. We cache `userType` and `onboardingCompleted` together since
  // they come from the same Firestore document — one lookup, two values.
  //
  // Offline behaviour:
  //   1. Try Source.cache (returns instantly if the doc was ever loaded).
  //   2. Otherwise hit Source.server with a 6s timeout.
  //   3. If both fail, fall back to {userType: 'patient', onboardingCompleted: null}
  //      so signed-in users on cold-starts see *something* instead of getting
  //      bounced through the redirect logic indefinitely. `null` for the
  //      onboarding flag lets [computeRedirect] decline to gate.

  static String? _cachedUserType;
  static bool? _cachedUserOnboardingCompleted;

  // App-intro carousel flag (SharedPreferences). Independent of the
  // per-user onboarding flag.
  static bool? _cachedAppIntroDone;

  /// Returns `'patient' | 'therapist' | null`. `null` only when the user is
  /// unauthenticated.
  static Future<String?> getUserType() async {
    final state = await _loadUserState();
    return state?.userType;
  }

  /// Returns whether the per-role onboarding has been completed for the
  /// current user, or `null` if the user doc hasn't been loaded yet
  /// (offline cold-start). Callers must treat `null` as "do not gate".
  static Future<bool?> getUserOnboardingCompleted() async {
    final state = await _loadUserState();
    return state?.onboardingCompleted;
  }

  static Future<_UserState?> _loadUserState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (_cachedUserType != null) {
      return _UserState(_cachedUserType!, _cachedUserOnboardingCompleted);
    }

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // 1) Cache first — offline-friendly.
    try {
      final cached =
          await docRef.get(const GetOptions(source: Source.cache));
      if (cached.exists) {
        final data = cached.data() ?? const {};
        _cachedUserType = (data['userType'] as String?) ?? 'patient';
        _cachedUserOnboardingCompleted =
            data['onboardingCompleted'] as bool? ?? false;
        return _UserState(_cachedUserType!, _cachedUserOnboardingCompleted);
      }
    } catch (_) {
      // Cache miss on first launch — fall through.
    }

    // 2) Server, with timeout to avoid wedging the redirect.
    try {
      final doc = await docRef
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 6));
      if (doc.exists) {
        final data = doc.data() ?? const {};
        _cachedUserType = (data['userType'] as String?) ?? 'patient';
        _cachedUserOnboardingCompleted =
            data['onboardingCompleted'] as bool? ?? false;
        return _UserState(_cachedUserType!, _cachedUserOnboardingCompleted);
      }
    } catch (_) {
      // Offline / timeout — return a permissive default so the user isn't
      // bounced. The next navigation will retry.
    }
    return _UserState('patient', null);
  }

  /// Clears all caches that depend on the signed-in user. Call from every
  /// logout path. The `goToLogin()` extension already invokes this.
  static void clearAuthCache() {
    _cachedUserType = null;
    _cachedUserOnboardingCompleted = null;
  }

  /// Backwards-compatible alias — old call sites still call this. Both
  /// names clear the same fields.
  static void clearUserTypeCache() => clearAuthCache();

  /// Reads (and caches) whether the app-intro carousel has been completed.
  static Future<bool> isOnboardingCompleted() async {
    if (_cachedAppIntroDone != null) return _cachedAppIntroDone!;
    final prefs = await SharedPreferences.getInstance();
    _cachedAppIntroDone = prefs.getBool(onboardingCompletedKey) ?? false;
    return _cachedAppIntroDone!;
  }

  /// Call after finishing the app-intro carousel.
  static void markOnboardingCompleted() {
    _cachedAppIntroDone = true;
  }

  /// Call after finishing the per-role onboarding screen (therapist or
  /// patient). Keeps the cache in sync with the Firestore write so the
  /// next redirect doesn't bounce the user back.
  static void markUserOnboardingCompleted() {
    _cachedUserOnboardingCompleted = true;
  }
```

Then add this private helper class above the `AppRouter` class (or at the bottom of the file, scoped to the library):

```dart
class _UserState {
  final String userType;
  final bool? onboardingCompleted;
  const _UserState(this.userType, this.onboardingCompleted);
}
```

- [ ] **Step 7.3: Replace the redirect callback**

Find the existing `redirect:` block in `GoRouter(...)` (lines ~115-149). Replace it with:

```dart
    redirect: (context, state) async {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      final isLoggedIn = user != null;
      final emailVerified = user?.emailVerified ?? false;

      String? userType;
      bool? onboardingCompleted;
      if (isLoggedIn) {
        final userState = await _loadUserState();
        userType = userState?.userType;
        onboardingCompleted = userState?.onboardingCompleted;
      }

      final appIntroDone = await isOnboardingCompleted();

      return computeRedirect(RouterInputs(
        currentPath: state.matchedLocation,
        isLoggedIn: isLoggedIn,
        emailVerified: emailVerified,
        userType: userType,
        onboardingCompleted: onboardingCompleted,
        appIntroDone: appIntroDone,
      ));
    },
```

- [ ] **Step 7.4: Replace the top-level `/` redirect**

Find the existing `GoRoute(path: '/', redirect: (...) async { ... })` block (lines ~153-161). Replace it with a simpler version that lets the global redirect handle everything:

```dart
      GoRoute(
        path: '/',
        // Global redirect handles all auth/onboarding routing — this exists
        // only so '/' is a valid initial location.
        redirect: (_, _) => null,
      ),
```

- [ ] **Step 7.5: Add the three new routes**

Inside the `routes:` array, add these three routes near the existing auth routes (after the `/onboarding` route definition, before `// ============ MAIN APP ROUTES`):

```dart
      GoRoute(
        path: '/verify-email',
        name: 'verifyEmail',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const VerifyEmailScreen()),
      ),

      GoRoute(
        path: '/therapist/onboarding',
        name: 'therapistOnboarding',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const TherapistOnboardingScreen()),
      ),

      GoRoute(
        path: '/patient/onboarding',
        name: 'patientOnboarding',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const PatientOnboardingScreen()),
      ),
```

- [ ] **Step 7.6: Add a navigation extension**

At the bottom of the file inside `extension GoRouterExtension on BuildContext`, add:

```dart
  void goToVerifyEmail() => go('/verify-email');
  void goToTherapistOnboarding() => go('/therapist/onboarding');
  void goToPatientOnboarding() => go('/patient/onboarding');
```

- [ ] **Step 7.7: Run analyze on the whole project**

Run: `flutter analyze`
Expected: No issues found. (All previously-undefined symbols now resolve.)

- [ ] **Step 7.8: Run all the tests written so far**

Run: `flutter test test/router/redirect_logic_test.dart test/screens/auth/verify_email_screen_test.dart test/screens/onboarding/therapist_onboarding_test.dart test/core/utils/auth_error_messages_test.dart`
Expected: All pass.

- [ ] **Step 7.9: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat(router): wire emailVerified gate, per-role onboarding gate, and verify-email/onboarding routes"
```

---

## Task 8: Update register screen

**Files:**
- Modify: `lib/screens/register_screen.dart`

- [ ] **Step 8.1: Add the auth-error-messages import**

At the top of `lib/screens/register_screen.dart`, after the existing rehabtech imports, add:

```dart
import 'package:rehabtech/core/utils/auth_error_messages.dart';
```

- [ ] **Step 8.2: Replace the Firestore write block to include therapist defaults**

Find this block (lines ~88-97):

```dart
      // Generar ID único de paciente si es paciente
      final patientId = _userType == 'patient' ? _generatePatientId() : null;

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': firstName,
        'lastName': lastName,
        'email': _emailController.text.trim(),
        'userType': _userType,
        'patientId': patientId,
        'createdAt': FieldValue.serverTimestamp(),
      });
```

Replace with:

```dart
      // Generar ID único de paciente si es paciente
      final patientId = _userType == 'patient' ? _generatePatientId() : null;

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': firstName,
        'lastName': lastName,
        'email': _emailController.text.trim(),
        'userType': _userType,
        'patientId': patientId,
        'createdAt': FieldValue.serverTimestamp(),
        // Per-role defaults — explicit so the user-doc shape is
        // self-describing rather than relying on lenient parsers.
        'onboardingCompleted': false,
        if (_userType == 'therapist') ...{
          'licenseStatus': 'unverified',
          'licenseNumber': null,
          'speciality': null,
        },
      });
```

- [ ] **Step 8.3: Replace `_navigateAfterRegister` to route to /verify-email**

Find:

```dart
  Future<void> _navigateAfterRegister() async {
    AppRouter.clearUserTypeCache();
    if (mounted) {
      if (_userType == 'therapist') {
        context.go('/therapist');
      } else {
        context.go('/main');
      }
    }
  }
```

Replace with:

```dart
  Future<void> _navigateAfterRegister() async {
    AppRouter.clearAuthCache();
    if (!mounted) return;
    // The router's emailVerified gate sends every newly registered user to
    // /verify-email until they click the link in their inbox. We send them
    // there explicitly so they don't briefly see /main or /therapist before
    // the redirect kicks in.
    context.go('/verify-email');
  }
```

- [ ] **Step 8.4: Replace the `FirebaseAuthException` catch with the mapper**

Find the catch block in `_createAccount` (lines ~123-128):

```dart
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error al crear cuenta')),
        );
      }
    } finally {
```

Replace with:

```dart
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapSignUpError(e))),
        );
      }
    } finally {
```

- [ ] **Step 8.5: Add the therapist info banner under the user-type toggle**

Find the existing `_buildUserTypeSelector()` widget call in the body's `Column` (around line 224):

```dart
            _buildUserTypeSelector(),
            const SizedBox(height: 24),
```

Replace with:

```dart
            _buildUserTypeSelector(),
            const SizedBox(height: 12),
            _buildTherapistInfoBanner(),
            const SizedBox(height: 12),
```

Then add the helper method anywhere inside `_RegisterScreenState` (suggested spot: just below `_buildUserTypeButton`):

```dart
  Widget _buildTherapistInfoBanner() {
    if (_userType != 'therapist') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Como terapeuta, necesitarás verificar tu cédula profesional '
              'en el Registro Nacional de Profesionistas de la SEP. '
              'Este proceso toma menos de 1 minuto.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 8.6: Update the Google sign-in path to route to /verify-email too**

Find the end of `_signInWithGoogle` — the line `await _navigateAfterRegister();` already exists. No change needed: that method now points to `/verify-email`. ✅

But also: Google-authenticated accounts are already `emailVerified: true`. The router's redirect will instantly bounce them off `/verify-email` to home, so the user experience is unchanged. ✅

- [ ] **Step 8.7: Run analyze**

Run: `flutter analyze lib/screens/register_screen.dart`
Expected: No issues found.

- [ ] **Step 8.8: Run any existing register-related tests**

Run: `flutter test`
Expected: Existing tests still pass.

- [ ] **Step 8.9: Commit**

```bash
git add lib/screens/register_screen.dart
git commit -m "feat(register): route to /verify-email, add therapist info banner, write licenseStatus default"
```

---

## Task 9: Update login screen

**Files:**
- Modify: `lib/screens/login_screen.dart`

- [ ] **Step 9.1: Add the auth-error-messages import**

At the top of `lib/screens/login_screen.dart`, add:

```dart
import 'package:rehabtech/core/utils/auth_error_messages.dart';
```

- [ ] **Step 9.2: Replace `_signIn` body so it reloads + delegates to redirect**

Find:

```dart
  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Track login event
      await AnalyticsService().logLogin(method: 'email');
      await AnalyticsService().setUserId(_auth.currentUser?.uid);
      await AnalyticsService().setUserType(_userType);
      
      // Subscribe to notifications topic
      await NotificationService().subscribeToTopic(_userType);
      
      AppRouter.clearUserTypeCache(); // Limpiar cache para obtener tipo actualizado
      await _navigateAfterLogin();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = _getErrorMessage(e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

Replace with:

```dart
  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Refresh emailVerified — without this the local user is stale on the
      // first session after a verification click happens in another app.
      await _auth.currentUser?.reload();

      // Track login event
      await AnalyticsService().logLogin(method: 'email');
      await AnalyticsService().setUserId(_auth.currentUser?.uid);
      await AnalyticsService().setUserType(_userType);

      // Subscribe to notifications topic
      await NotificationService().subscribeToTopic(_userType);

      // Clear the cache so the redirect re-reads the user doc.
      AppRouter.clearAuthCache();

      // Let the global redirect resolve where the user goes — it knows about
      // emailVerified, role, and onboarding state. Manual routing here is
      // what created the original gap.
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapSignInError(e))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

- [ ] **Step 9.3: Replace `_signInWithGoogle` post-auth navigation**

Find the end of `_signInWithGoogle` (around line 138):

```dart
      AppRouter.clearUserTypeCache();
      
      // Track login event
      ...
      await _navigateAfterLogin();
```

Replace `await _navigateAfterLogin();` with:

```dart
      AppRouter.clearAuthCache();

      // Track login event
      await AnalyticsService().logLogin(method: 'google');
      await AnalyticsService().setUserId(_auth.currentUser?.uid);
      await AnalyticsService().setUserType(_userType);

      // Subscribe to notifications topic
      await NotificationService().subscribeToTopic(_userType);

      if (mounted) context.go('/');
```

(Replace the entire region between `AppRouter.clearUserTypeCache();` and `await _navigateAfterLogin();` so we don't end up with duplicated tracking calls.)

- [ ] **Step 9.4: Delete the now-unused `_navigateAfterLogin` and `_getErrorMessage`**

Find and delete the entire `_navigateAfterLogin` method (lines ~27-37) and the `_getErrorMessage` method (lines ~156-171). Both are dead code after the previous steps.

- [ ] **Step 9.5: Run analyze**

Run: `flutter analyze lib/screens/login_screen.dart`
Expected: No issues found. If there's an unused-import warning for `AppRouter`, that's expected — it's still used (`AppRouter.clearAuthCache()`). If the analyzer flags `AnalyticsService` or any other import, double-check Step 9.3 didn't accidentally remove a needed call.

- [ ] **Step 9.6: Run the existing login widget test**

Run: `flutter test test/widgets/login_screen_test.dart`
Expected: All pass. The test checks UI state and the empty-form snackbar; no Firebase paths are exercised.

- [ ] **Step 9.7: Commit**

```bash
git add lib/screens/login_screen.dart
git commit -m "feat(login): reload user post-auth, delegate routing to GoRouter redirect, share error mapper"
```

---

## Task 10: Final verification

- [ ] **Step 10.1: Full project analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10.2: Full test suite**

Run: `flutter test`
Expected: All tests pass. The new tests added across Tasks 1-4 should be present and green; existing tests should be unaffected.

- [ ] **Step 10.3: Manual smoke checklist (write up in delivery report)**

Document the manual smoke flow steps in the delivery report (do not actually run the app):

1. Fresh install → app shows `/onboarding` carousel.
2. Complete carousel → `/login`.
3. Tap "Regístrate aquí" → `/register`.
4. Toggle "Soy Terapeuta" → amber info banner appears.
5. Submit → routed to `/verify-email`.
6. Tap link in inbox (or use Firebase Console "Verify" tool) → return to app, tap "Ya verifiqué" → routed to `/therapist/onboarding`.
7. Walk all 4 steps. Tap "Verificar después" on step 3 → step 4. Tap "Ir a mi panel" → `/therapist`.
8. Therapist banner is present (because `licenseStatus = unverified`).
9. Sign out → `/login`. Cache cleared (verify by signing in as a patient: lands on `/patient/onboarding` if first time, otherwise `/main`).

- [ ] **Step 10.4: Compile the delivery report**

Create the delivery report inline in this PR (or a separate document if your workflow prefers). Use this template:

```markdown
# RehabTech — Therapist Onboarding: Delivery Report

## Flow Audit Results

### What was found
- Generic `/onboarding` carousel already covers the spec's STEP 8 — left untouched.
- TherapistUnverifiedBanner already reactive (StreamBuilder on users/{uid}); only fired for `unverified`. Patched to also fire for `rejected`.
- `firestore.rules` already permitted owner-writes to non-license fields — no rules change needed.
- Field naming differs from spec: `userType` (not `role`), `name`/`lastName` (not `fullName`), `photoUrl` (not `photoURL`). Plan respects existing schema.

### What was missing
- `/verify-email` route + screen.
- Email-verification gate in router redirect.
- Per-role onboarding gate in router redirect.
- Therapist onboarding screen.
- Patient onboarding screen.
- Spanish error mapping (raw `e.message` was leaking).
- `reload()` after sign-in.

## Redirect Logic

| State | Redirect to | Was it working before? |
|-------|------------|----------------------|
| Logged out, app intro not done, anywhere | /onboarding | ✅ already worked |
| Logged out, app intro done, on /onboarding | /login | ✅ already worked |
| Logged out, anywhere not in {/login, /register, /forgot-password, /} | /login | ✅ already worked |
| Logged in, !emailVerified, anywhere not /verify-email | /verify-email | ❌ now added |
| Logged in, emailVerified, on /verify-email | role home | ❌ now added |
| Therapist, emailVerified, !onboardingCompleted | /therapist/onboarding | ❌ now added |
| Patient, emailVerified, !onboardingCompleted | /patient/onboarding | ❌ now added |
| Logged in, on /license-verification mid-onboarding | (allow) | ❌ now added |
| Logged in, fully onboarded, on /login or /onboarding | role home | ✅ already worked |

## Screens Created / Fixed

| Screen | Route | New/Fixed |
|--------|-------|-----------|
| VerifyEmailScreen | /verify-email | New |
| TherapistOnboardingScreen | /therapist/onboarding | New |
| PatientOnboardingScreen | /patient/onboarding | New |
| RegisterScreen | /register | Fixed: routes to /verify-email; therapist info banner; explicit therapist defaults; Spanish errors |
| LoginScreen | /login | Fixed: reload() post-auth; redirect-driven navigation; Spanish errors |
| TherapistUnverifiedBanner | (widget) | Fixed: also shows for `rejected` |

## TherapistUnverifiedBanner

Was already reactive via StreamBuilder on `users/{uid}` — no architecture change. The single fix was extending the visibility predicate to include `LicenseStatus.rejected`. Therapists in `pending`/`manual_review`/`verified` continue to see no banner (those have their own UIs).

## Firestore Fields Added

| Collection | Field | Type | Purpose |
|-----------|-------|------|---------|
| users/{uid} | onboardingCompleted | bool | Per-role onboarding gate (true after the role-specific welcome flow finishes) |
| users/{uid} | licenseStatus | string | Set to `'unverified'` at therapist registration. Was previously absent and worked via the lenient parser; now explicit. |
| users/{uid} | licenseNumber | string? | Set to null at therapist registration. |
| users/{uid} | speciality | string? | Set to null at therapist registration; populated by therapist onboarding. |
| users/{uid} | bio | string? | Optional, populated by therapist onboarding. |
| users/{uid} | modality | string | Populated by therapist onboarding. |
| users/{uid} | dob | Timestamp? | Optional, populated by patient onboarding. |
| users/{uid} | condition | string? | Optional, populated by patient onboarding. |
| users/{uid} | emergencyContactName | string? | Optional, populated by patient onboarding. |
| users/{uid} | emergencyContactPhone | string? | Optional, populated by patient onboarding. |

All fields are writable by the document owner under the existing Firestore rules — no rule change required.

## Manual Steps Required

1. **Customize the verification email template** in Firebase Console → Authentication → Templates → Email address verification. Translate to Spanish, add the RehabTech logo, and customise the action URL if you have a deeper link strategy.
2. **(Optional)** Add `'patient/onboarding'` and `'therapist/onboarding'` to Firebase Hosting redirects if you support `https://rehabtech.app/...` deep links.

## Known Limitations / Deferred

1. **No widget test for the patient onboarding screen** — covered structurally by the therapist screen test (same shape) and by the redirect tests (state transitions). Add one in a follow-up if patient-specific behaviour grows.
2. **Lottie checkmark not used** — both onboarding "done" screens use `TweenAnimationBuilder` driving `Icons.check_circle`. Adding Lottie is a 1-package addition if/when motion design lands.
3. **Email change flow does not reset `emailVerified`** for the in-app email-change feature. Out of scope here — handled by the existing SecurityScreen.
4. **Therapist onboarding does not gate license verification** — the spec explicitly required soft-block, so a therapist who taps "Verificar después" can use the app freely; the persistent banner is the prompt.
5. **No analytics events** logged for onboarding step completion. Easy follow-up via `AnalyticsService` once we settle on event names.
```

- [ ] **Step 10.5: Final commit & push**

```bash
git add docs/superpowers/plans/2026-05-05-therapist-onboarding.md
git commit -m "docs: add therapist onboarding implementation plan"
```

---

## Self-review checklist (run after writing the plan)

**1. Spec coverage** — every spec section has a task:

- [x] STEP 0 (audit) — covered in the audit reply that precedes this plan.
- [x] STEP 1.1 (Firestore doc on register) — Task 8 step 8.2.
- [x] STEP 1.2 (sendEmailVerification) — already in code; Task 8 preserves call order.
- [x] STEP 1.3 (role selector + therapist info banner) — Task 8 step 8.5.
- [x] STEP 1.4 (Spanish error map) — Task 1 + Task 8 step 8.4.
- [x] STEP 2 (verify-email screen) — Task 3.
- [x] STEP 3 (router redirect) — Tasks 2, 7. Pure-function approach replaces the spec's naive cache class with the existing offline-friendly cache pattern.
- [x] STEP 4 (therapist onboarding) — Task 4.
- [x] STEP 5 (patient onboarding) — Task 5.
- [x] STEP 6 (banner audit) — Task 6.
- [x] STEP 7 (login fix) — Task 9.
- [x] STEP 8 (app intro) — **already done** in the codebase; no task needed (audit explicitly notes this).
- [x] STEP 9 (tests) — Tasks 1, 2, 3, 4 each carry their tests TDD-first.
- [x] DELIVERY (analyze + test + report) — Task 10.

**2. Placeholder scan** — none found. Every code block is complete; every command has expected output.

**3. Type / symbol consistency:**
- `clearAuthCache()` — defined in Task 7, used in Tasks 3, 8, 9.
- `markUserOnboardingCompleted()` — defined in Task 7, used in Tasks 4, 5.
- `mapSignInError`, `mapSignUpError`, `mapResendVerificationError` — defined in Task 1, used in Tasks 3, 8, 9.
- `RouterInputs`, `computeRedirect` — defined in Task 2, used in Task 7.
- `VerifyEmailController` — defined in Task 3, used by its own tests; production wiring via private `_FirebaseVerifyEmailController` (no leak).
- All field names use `userType`, `name`/`lastName`, `photoUrl`, `licenseStatus` — match Firestore + existing rules.

Plan is internally consistent. Ready for execution.
