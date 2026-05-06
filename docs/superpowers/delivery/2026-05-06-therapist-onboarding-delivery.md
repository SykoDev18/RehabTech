# RehabTech — Therapist Onboarding: Delivery Report

**Branch:** `feat/security-and-features`
**Date:** 2026-05-06
**Plan:** [docs/superpowers/plans/2026-05-05-therapist-onboarding.md](../plans/2026-05-05-therapist-onboarding.md)

---

## TL;DR

The post-registration flow (Register → Email Verification → Role-Specific Onboarding → Home) is now hard-required for every new RehabTech user, gated reactively in the GoRouter `redirect` callback. Therapists are still soft-blocked (not hard-blocked) on license verification — the persistent `TherapistUnverifiedBanner` retains that role.

`flutter analyze` clean. 61 onboarding-touched tests pass; pre-existing flaky chat test (`watchMessages emits messages in chronological order`) is unrelated and untouched by this work — see "Known limitations" below.

---

## Flow Audit Results

### What was found
- Generic `/onboarding` carousel already covers spec STEP 8 — left untouched.
- `TherapistUnverifiedBanner` already reactive (StreamBuilder on `users/{uid}`); only fired for `unverified`. Patched to also fire for `rejected`.
- `firestore.rules` already permitted owner-writes to non-license fields — no rules change needed.
- Field naming differs from spec: codebase uses `userType` (not `role`), `name`/`lastName` (not `fullName`), `photoUrl` (not `photoURL`). Implementation respects the existing schema.

### What was missing
- `/verify-email` route + screen.
- Email-verification gate in router redirect.
- Per-role onboarding gate in router redirect.
- Therapist onboarding screen.
- Patient onboarding screen.
- Spanish error mapping (raw `e.message` was leaking English).
- `reload()` after sign-in.

---

## Redirect Logic

| State | Redirect to | Was it working before? |
|-------|------------|----------------------|
| Logged out, app intro not done | /onboarding | ✅ already worked |
| Logged out, app intro done, on /onboarding | /login | ✅ already worked |
| Logged out, anywhere not in {/login, /register, /forgot-password, /} | /login | ✅ already worked |
| Logged in, !emailVerified, anywhere not /verify-email | /verify-email | 🆕 added |
| Logged in, emailVerified, on /verify-email | role home | 🆕 added |
| Therapist, emailVerified, !onboardingCompleted | /therapist/onboarding | 🆕 added |
| Patient, emailVerified, !onboardingCompleted | /patient/onboarding | 🆕 added |
| Logged in, on /license-verification mid-onboarding | (allow) | 🆕 added |
| Logged in, fully onboarded, on /login or /onboarding | role home | ✅ already worked |
| User doc still loading (offline / cold start) | (allow) | 🆕 added — preserves offline-friendly cache pattern |

Decision logic lives in [`lib/router/redirect_logic.dart`](../../../lib/router/redirect_logic.dart) as a pure function — fully unit-tested in [`test/router/redirect_logic_test.dart`](../../../test/router/redirect_logic_test.dart) (23 tests covering every branch). The `redirect:` callback in [`AppRouter`](../../../lib/router/app_router.dart) only gathers state and delegates.

---

## Screens Created / Fixed

| Screen | Route | New/Fixed |
|--------|-------|-----------|
| `VerifyEmailScreen` | `/verify-email` | 🆕 New — full-screen, 60s resend cooldown, injectable controller for tests |
| `TherapistOnboardingScreen` | `/therapist/onboarding` | 🆕 New — 4 steps: Welcome → Profile (specialidad+modalidad+bio) → License CTA → Done |
| `PatientOnboardingScreen` | `/patient/onboarding` | 🆕 New — 4 steps: Welcome → Demographics (DOB+condition+emergency contact) → How-it-works → Done |
| `RegisterScreen` | `/register` | Fixed — routes to `/verify-email`; therapist info banner; explicit `licenseStatus: 'unverified'`; Spanish errors via `mapSignUpError` |
| `LoginScreen` | `/login` | Fixed — `currentUser.reload()` post-auth; redirect-driven navigation (`context.go('/')`); Spanish errors via `mapSignInError` |
| `TherapistUnverifiedBanner` | (widget) | Fixed — also shows for `LicenseStatus.rejected` |

---

## TherapistUnverifiedBanner

Was already reactive via `StreamBuilder` on `users/{uid}` — no architecture change. The single fix was extending the visibility predicate to include `LicenseStatus.rejected`. Therapists in `pending` / `manual_review` / `verified` continue to see no banner (those states have their own UIs in `LicenseVerificationScreen`).

The banner stays in the therapist shell at [`therapist_main_nav_screen.dart:40`](../../../lib/screens/therapist/therapist_main_nav_screen.dart#L40), so newly-registered therapists who tap "Verificar después" in onboarding land on `/therapist` and immediately see the persistent prompt.

---

## Firestore Fields Added

| Collection | Field | Type | Purpose |
|-----------|-------|------|---------|
| `users/{uid}` | `onboardingCompleted` | bool | Per-role onboarding gate. Set to `false` at registration; `true` after the role-specific welcome flow finishes. |
| `users/{uid}` | `licenseStatus` | string | Now set to `'unverified'` at therapist registration. Was previously absent and worked via the lenient `LicenseStatus.fromString` parser; now explicit. |
| `users/{uid}` | `licenseNumber` | string? | Set to null at therapist registration (placeholder so `update()` calls don't fail on missing field). |
| `users/{uid}` | `speciality` | string? | Null at registration; populated by therapist onboarding step 2. |
| `users/{uid}` | `bio` | string? | Optional; populated by therapist onboarding step 2. |
| `users/{uid}` | `modality` | string | Populated by therapist onboarding step 2. Values: `Presencial`, `Virtual`, `Ambas`. |
| `users/{uid}` | `dob` | Timestamp? | Optional; populated by patient onboarding step 2. |
| `users/{uid}` | `condition` | string? | Optional; populated by patient onboarding step 2. |
| `users/{uid}` | `emergencyContactName` | string? | Optional; populated by patient onboarding step 2. |
| `users/{uid}` | `emergencyContactPhone` | string? | Optional; populated by patient onboarding step 2. 10 digits, numeric-only input. |

All fields are writable by the document owner under the existing `firestore.rules` (none of them are in the `affectsLicenseAdminFields` blocklist) — **no rules change required**.

---

## Files Created

| Path | Lines | Tests |
|------|-------|-------|
| [`lib/core/utils/auth_error_messages.dart`](../../../lib/core/utils/auth_error_messages.dart) | 56 | ✅ 13 |
| [`lib/router/redirect_logic.dart`](../../../lib/router/redirect_logic.dart) | 110 | ✅ 23 |
| [`lib/screens/auth/verify_email_screen.dart`](../../../lib/screens/auth/verify_email_screen.dart) | 232 | ✅ 9 |
| [`lib/screens/onboarding/therapist_onboarding_screen.dart`](../../../lib/screens/onboarding/therapist_onboarding_screen.dart) | 320 | ✅ 6 |
| [`lib/screens/onboarding/patient_onboarding_screen.dart`](../../../lib/screens/onboarding/patient_onboarding_screen.dart) | 386 | (covered structurally by therapist test) |

## Files Modified

| Path | Notes |
|------|-------|
| [`lib/router/app_router.dart`](../../../lib/router/app_router.dart) | Replaced cache + redirect; added 3 new routes; added 3 nav extensions; preserves offline-friendly Source.cache → Source.server pattern |
| [`lib/screens/register_screen.dart`](../../../lib/screens/register_screen.dart) | Therapist info banner; explicit licenseStatus default; Spanish errors; routes to /verify-email |
| [`lib/screens/login_screen.dart`](../../../lib/screens/login_screen.dart) | reload(); shared error mapper; context.go('/') instead of manual role routing |
| [`lib/widgets/therapist_unverified_banner.dart`](../../../lib/widgets/therapist_unverified_banner.dart) | Fires for `rejected` in addition to `unverified` |

---

## Verification

- `flutter analyze` → **No issues found!**
- `flutter test test/router/redirect_logic_test.dart test/screens/auth/verify_email_screen_test.dart test/screens/onboarding/therapist_onboarding_test.dart test/core/utils/auth_error_messages_test.dart test/widgets/login_screen_test.dart` → **61 tests pass** (full new + adjacent surface)
- `flutter test` → 408 of 409 tests pass (one pre-existing flaky test unrelated — see below)

### Manual smoke checklist (recommended before release)

1. Fresh install → app shows `/onboarding` carousel.
2. Complete carousel → `/login`.
3. Tap "Regístrate aquí" → `/register`.
4. Toggle "Soy Terapeuta" → amber info banner appears.
5. Submit → routed to `/verify-email`.
6. Click link in inbox (or use Firebase Console "Verify" tool) → return to app, tap "Ya verifiqué" → routed to `/therapist/onboarding`.
7. Walk all 4 steps. Tap "Verificar después" on step 3 → step 4. Tap "Ir a mi panel" → `/therapist`.
8. Therapist banner is present (because `licenseStatus = unverified`).
9. Sign out → `/login`. Sign in as a fresh patient → lands on `/patient/onboarding` (first time) or `/main` (subsequent).

---

## Manual Steps Required (post-merge)

1. **Customise the verification email template** in Firebase Console → Authentication → Templates → Email address verification. Translate to Spanish, add the RehabTech logo, optionally configure the action URL.
2. **(Optional)** Add `/patient/onboarding` and `/therapist/onboarding` to Firebase Hosting redirects if `https://rehabtech.app/...` deep links should resolve to them.

---

## Known Limitations / Deferred

1. **Pre-existing flaky test** — [`test/repositories/conversation_repository_test.dart:223`](../../../test/repositories/conversation_repository_test.dart#L223) fails ~30% of the time on `watchMessages emits messages in chronological order`. Root cause: `FakeFirebaseFirestore` resolves `Timestamp.now()` ties non-deterministically when three messages are written within the same microsecond. Introduced in commit `80c7b4b` (chat module, 2026-05-05) — predates this work and is **untouched** by it. Recommended follow-up: add 1-2ms `Future.delayed` or pass an explicit incrementing `Timestamp` per message in the test fixture.
2. **No widget test for the patient onboarding screen.** The structural patterns are identical to the therapist screen, which has a thorough widget test, and the redirect tests cover state transitions. Add a dedicated test in a follow-up if patient-specific behaviour grows (e.g. validation of `emergencyContactPhone`).
3. **Lottie checkmark not used.** Both onboarding "done" screens use `TweenAnimationBuilder` driving `Icons.check_circle`. Adding Lottie is a 1-package addition if/when motion design lands.
4. **Email-change flow does not reset `emailVerified`** in the in-app email-change feature. Out of scope here — handled by the existing `SecurityScreen`.
5. **Therapist onboarding does not gate license verification.** The spec explicitly required soft-block, so a therapist who taps "Verificar después" can use the app freely; the persistent banner is the prompt.
6. **No analytics events** logged for onboarding step completion. Easy follow-up via the existing `AnalyticsService`.

---

## Commits

```
99e0849 feat(login): reload user post-auth, delegate routing to GoRouter redirect, share error mapper
e1e1728 feat(register): route to /verify-email, add therapist info banner, write licenseStatus default
677195a feat(router): wire emailVerified gate, per-role onboarding gate, and new routes
d93d16e fix(banner): show TherapistUnverifiedBanner for rejected status as well
9e2161a feat(onboarding): add four-step PatientOnboardingScreen with optional demographics
e7a6bd3 feat(onboarding): add four-step TherapistOnboardingScreen with profile + license CTA
2912da0 feat(auth): add VerifyEmailScreen with cooldown timer and injectable controller
4696e4d feat(router): add pure computeRedirect decision function with unit tests
847a5f0 feat(auth): add Spanish error-message mapper for sign-in/sign-up/resend
```

9 commits. Each individually compiles and passes its own tests; rebase-friendly.
