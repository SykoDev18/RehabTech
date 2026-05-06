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
    test(
        'therapist with onboarding NOT done & not on therapist onboarding → /therapist/onboarding',
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

    test(
        'patient with onboarding NOT done & not on patient onboarding → /patient/onboarding',
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

    test('userType still resolving (null) does NOT trigger onboarding gate',
        () {
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
