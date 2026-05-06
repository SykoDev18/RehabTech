// Pure-function redirect decision for the GoRouter `redirect` callback.
//
// Holding the rules in a function with no Firebase imports lets us unit-test
// every branch without mocking. The actual callback in [AppRouter.router]
// gathers state (auth + Firestore) and delegates here.

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

/// Returns the path to redirect to, or `null` to allow [RouterInputs.currentPath].
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
    final required = userType == 'therapist'
        ? '/therapist/onboarding'
        : '/patient/onboarding';
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
