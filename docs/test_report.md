# RehabTech — Test Report

**Run:** 2026-05-02 · branch `feat/security-and-features` · `flutter analyze` clean (`No issues found!`).

## Summary

| Layer | Tests Written (this session) | Pre-existing | Pass | Fail | Coverage of touched files |
|-------|-----------------------------:|-------------:|-----:|-----:|---------------------------|
| Unit (entities + repos + Firestore contracts) | **62** | 121 | **183** | **0** | see § Coverage |
| Widget | **33** | 76 | **109** | **0** | see § Coverage |
| Integration | **0** *(spec authored, infra deferred)* | 0 | — | — | see [docs/integration_tests_spec.md](integration_tests_spec.md) |
| Cloud Functions (separate Jest suite) | 0 *(unchanged)* | 31 | **31** | **0** | n/a |
| **Total Flutter** | **95 new** | 197 | **292** | **0** | 12.42 % overall |

### Per-file breakdown of new tests

| File | New tests | Status |
|---|--:|---|
| `test/data/repositories/auth_repository_impl_test.dart` | 13 | all green |
| `test/domain/entities/appointment_entity_test.dart` | 17 | all green |
| `test/domain/entities/routine_entity_test.dart` | 16 | all green |
| `test/data/firestore_query_contracts_test.dart` | 16 | all green |
| `test/widgets/login_screen_test.dart` | 10 | all green |
| `test/widgets/my_routines_screen_test.dart` *(also covers MyAppointmentsScreen)* | 5 | all green |
| `test/widgets/patients_screen_test.dart` | 3 | all green |
| `test/widgets/ai_chat_screen_test.dart` *(ChatMessage, TypingIndicator)* | 9 | all green |
| `test/widgets/home_screen_test.dart` *(catalogue contract)* | 6 | all green |

Plus one infrastructure file: `test/_helpers/firebase_test_setup.dart` (Firebase platform-channel mock used by widget tests).

---

## Failing Tests

**None.** 292 / 292 Flutter tests pass; 31 / 31 Cloud Functions tests pass.

---

## Coverage

`flutter test --coverage` produced `coverage/lcov.info` (10 768 instrumented lines, 1 337 covered → **12.42 %** project-wide).

> **Why "only" 12 %?** The codebase has ~80 large screen widgets that haven't yet been refactored to allow dependency injection of `FirebaseAuth.instance` / `FirebaseFirestore.instance`. Until they are, those screens contribute hundreds of uncovered lines each — see § Coverage Gaps. The high-value targets we did test are at 50 – 100 %.

### Coverage of files this session targeted

| File | Coverage | Notes |
|---|--:|---|
| `lib/domain/entities/appointment_entity.dart` | **100.00 %** | every getter, every formatted-string branch, copyWith, equality |
| `lib/domain/entities/routine_entity.dart` | **97.56 %** | only `RoutineExerciseEntity.copyWith` field-by-field combinatorial gap |
| `lib/models/exercise.dart` | **96.97 %** | the 1 missing line is unreachable defensive code |
| `lib/screens/login_screen.dart` | **63.78 %** | render + form-validation paths covered; Firebase-auth branches untested by design |
| `lib/data/repositories/auth_repository_impl.dart` | **50.00 %** | email/password + reset + sign-out covered; Google sign-in branch needs platform mock |
| `lib/screens/therapist/patients_screen.dart` | **12.69 %** | unauthenticated render path covered; Firestore-stream branches deferred to Phase 3 |
| `lib/screens/main/ai_chat_screen.dart` | **10.58 %** | `ChatMessage` + `TypingIndicator` covered; full chat flow deferred to Phase 3 |
| `lib/screens/main/my_routines_screen.dart` | **5.88 %** | unauth path only |
| `lib/screens/main/my_appointments_screen.dart` | **4.76 %** | unauth path only |
| `lib/screens/main/home_screen.dart` | **0.00 %** | input-catalogue contract tested via `allExercises`; widget pump deferred |

### Highest-coverage files in the suite (after this session)

| File | Coverage |
|---|--:|
| `lib/widgets/common/error_widget.dart` | 100.00 % |
| `lib/screens/achievements/widgets/achievement_card.dart` | 100.00 % |
| `lib/domain/entities/appointment_entity.dart` | 100.00 % |
| `lib/widgets/license_status_badge.dart` | 100.00 % |
| `lib/domain/therapy/session_state.dart` | 100.00 % |
| `lib/presentation/widgets/auth/password_strength_indicator.dart` | 98.18 % |
| `lib/domain/entities/routine_entity.dart` | 97.56 % |
| `lib/domain/pose_analysis/rep_phase_machine.dart` | 96.97 % |
| `lib/domain/validators/password_validator.dart` | 96.88 % |
| `lib/domain/therapy/session_controller.dart` | 91.43 % |
| `lib/services/streak_service.dart` | 91.43 % |
| `lib/services/nora_input_sanitizer.dart` | 89.55 % |
| `lib/services/achievement_service.dart` | 89.19 % |

---

## Coverage Gaps (< 70 %)

71 files fall below 70 % line coverage. They sort into three buckets:

### Bucket A — Untestable as-written (architectural blockers, not test gaps)

These screens and services use `FirebaseAuth.instance` / `FirebaseFirestore.instance` / `Firebase…Service()` singletons inline inside `build()` or `initState()`. There is no constructor seam to inject a fake. Until they accept an injected client (or the Firebase Emulator runs in CI), they cannot be widget-tested for branches beyond the unauthenticated fallback.

| File | Coverage | Untested branches |
|---|--:|---|
| `lib/screens/main/home_screen.dart` | 0.00 % | full screen — needs `ProgressService` injection + `intl es_ES` setup |
| `lib/screens/main/therapy_session_screen.dart` | 0.00 % | the 614-line ML-Kit pose loop — needs `PoseDetectionService` fake |
| `lib/screens/main/session_report_screen.dart` | 0.00 % | post-session pain/notes UI |
| `lib/screens/main/exercise_detail_screen.dart` | 0.00 % | every branch |
| `lib/screens/main/countdown_screen.dart` | 0.00 % | every branch |
| `lib/screens/therapist/patient_detail_screen.dart` | 0.00 % | every branch |
| `lib/screens/therapist/routines_screen.dart` | 0.23 % | full routine builder |
| `lib/screens/main/progress_screen.dart` | 0.24 % | fl_chart progress charts |
| `lib/router/app_router.dart` | 0.00 % | role-based redirect — gated on Firestore `users/{uid}` lookup |
| `lib/services/pdf_service.dart` | 0.00 % | PDF generation paths (non-trivial; needs golden file infra) |
| `lib/services/pose_detection_service.dart` | 0.00 % | ML Kit shim — needs an injectable analyzer |
| `lib/services/progress_service.dart` | 0.00 % | singleton with `init()` side effects |
| `lib/services/notification_service.dart` | 0.00 % | tests are stubbed in [test/services/notification_service_test.dart](../test/services/notification_service_test.dart) but never executed because mocks were never wired |

### Bucket B — Touched this session, but only the unauthenticated branch ran

These screens are now partially covered. The remaining branches are either authenticated UI flows (covered by the deferred Phase 3 spec) or settings / forms not in scope of the original plan.

| File | Coverage | Untested branches |
|---|--:|---|
| `lib/data/repositories/auth_repository_impl.dart` | 50.00 % | `signInWithGoogle()` (needs GoogleSignIn fake), `updateProfile`, `updatePassword`, `deleteAccount` |
| `lib/screens/login_screen.dart` | 63.78 % | success path of `_signIn()` (needs an injected FirebaseAuth on the screen), `_signInWithGoogle()` flow, `_getErrorMessage()` table for non-tested codes |
| `lib/screens/main/my_appointments_screen.dart` | 4.76 % | StreamBuilder branches: loading spinner, error UI, upcoming/past sectioning |
| `lib/screens/main/my_routines_screen.dart` | 5.88 % | StreamBuilder branches: loading, error, populated routine cards |
| `lib/screens/therapist/patients_screen.dart` | 12.69 % | search filter, KPI dashboard, add-patient modal, manual-add modal |
| `lib/screens/main/ai_chat_screen.dart` | 10.58 % | full conversation init, send/receive, error retry, save-to-Firestore branches |

### Bucket C — Out of scope for this session (settings, profile screens, onboarding)

Settings, profile, and onboarding screens were never targeted by the test plan and remain at < 5 % coverage. Examples: `security_screen.dart`, `edit_profile_screen.dart`, `notifications_screen.dart`, `help_center_screen.dart`, `high_contrast_screen.dart`, `text_size_screen.dart`, `onboarding_screen.dart`, `forgot_password_screen.dart`, `register_screen.dart`. These are the natural follow-up batch.

---

## Notable findings during testing

1. **Defensive fix applied to [lib/data/repositories/auth_repository_impl.dart](../lib/data/repositories/auth_repository_impl.dart):** `_attachUserToCrashlytics` already attached `.catchError((_) {})` for async errors but the synchronous `FirebaseCrashlytics.instance` getter could still throw and abort `signInWithEmail` in environments where Crashlytics isn't fully initialised (i.e., tests). Wrapped the call in `try { ... } catch (_) {}` to complete the existing best-effort intent. No change to production behaviour when Crashlytics is healthy. This is the only production-code change in this session.

2. **`firebase_auth_mocks` quirk:** `MockFirebaseAuth.createUserWithEmailAndPassword` ignores the configured `mockUser` and returns a fresh anonymous user. Tests assert on shape, not on a specific uid.

3. **Render overflow in `LoginScreen`:** at narrow widths the Apple/Google social-button rows overflow because `Image.asset` falls back to a default-sized broken-image widget when assets aren't bundled into tests. This is a genuine layout fragility on small phones. Not fixed in this session (out of scope), but flagged.

4. **No `AppointmentRepository` exists.** The plan's Phase 1 target #4 doesn't have a corresponding class — appointments are queried inline from screens. Replaced with **Firestore query-contract tests** (`test/data/firestore_query_contracts_test.dart`, 16 tests) that pin down the exact filter / sort / state-machine pattern those inline queries depend on. These tests survive a future repository refactor by swapping the helper class for the new repo and keeping the assertions.

5. **HomeScreen widget pump deliberately deferred.** `HomeScreen` synchronously requires `ProgressService.init()` (a stateful singleton initialised in `main.dart`), the `intl 'es_ES'` locale, and a `StreakWidget` that streams from FirebaseAuth + Firestore. Pumping it inside `flutter_test` blows up before any assertion can run. Replaced with an `allExercises` catalogue contract test that pins the input HomeScreen indexes by day-of-week.

---

## What ships in this PR

```
lib/data/repositories/auth_repository_impl.dart          (defensive try/catch around Crashlytics)
test/_helpers/firebase_test_setup.dart                   (Firebase platform-channel mock)
test/data/repositories/auth_repository_impl_test.dart    (13 tests)
test/data/firestore_query_contracts_test.dart            (16 tests)
test/domain/entities/appointment_entity_test.dart        (17 tests)
test/domain/entities/routine_entity_test.dart            (16 tests)
test/widgets/login_screen_test.dart                      (10 tests)
test/widgets/my_routines_screen_test.dart                (5 tests)
test/widgets/patients_screen_test.dart                   (3 tests)
test/widgets/ai_chat_screen_test.dart                    (9 tests)
test/widgets/home_screen_test.dart                       (6 tests)
docs/integration_tests_spec.md                           (Phase 3 implementation spec)
docs/test_report.md                                      (this file)
```

---

## Next-session checklist (Phase 3 + bucket B closeout)

1. Wire integration tests per [docs/integration_tests_spec.md](integration_tests_spec.md):
   - Add `integration_test` + `firebase_storage_mocks` (or the emulator) to dev_dependencies.
   - Add the seed scripts under `test/integration/_seed/`.
   - Implement the three flows (patient journey, therapist journey, chat).
2. Refactor screens in bucket B to accept injected `FirebaseAuth` / `FirebaseFirestore` (constructor parameter with `instance` default). Then their authenticated-state branches become widget-testable without an emulator.
3. Add a `GoogleSignIn` fake to lift `auth_repository_impl.dart` from 50 % → ~80 %.
4. Sweep settings / profile / onboarding screens (bucket C).
