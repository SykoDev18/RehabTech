# RehabTech — Architecture & Context Map

## Project Structure

The codebase is **mid-migration** from an older flat layout to Clean Architecture. Both layouts coexist, with screens mostly still on the old structure and a parallel `domain/data/presentation` skeleton that is partially wired:

```
lib/
├── main.dart                 entry point — runZonedGuarded → Firebase → dotenv → runApp
├── firebase_options.dart     auto-generated
│
├── core/                     cross-cutting
│   ├── constants/            api_constants.dart (collection names, Gemini model id, prefs keys), app_constants.dart
│   ├── extensions/           context, date, string extensions
│   ├── theme/                app_colors.dart, app_theme.dart
│   └── utils/                logger, error_handler, validators, formatters, app_check_service
│
├── domain/                   ⚠ Clean Architecture — entities + abstract repos exist…
│   ├── entities/             user, patient, routine, appointment, chat, exercise
│   └── repositories/         auth_repository.dart (abstract), chat, exercise, user
│
├── data/                     …and Firebase-backed implementations exist…
│   ├── datasources/          firebase_datasource.dart, local_datasource.dart
│   ├── models/               *_model.dart
│   └── repositories/         auth_repository_impl.dart, chat, exercise, user
│
├── presentation/             …but ONLY the theme provider lives here.
│   ├── providers/            theme_provider.dart  ← actually used
│   └── widgets/common/       glass_card, gradient_background, gradient_button, loading_indicator (unused by most screens)
│
├── providers/                ⚠ duplicate theme_provider.dart — dead copy (main.dart imports the presentation one)
│
├── router/app_router.dart    GoRouter + role-gating redirect
│
├── services/                 ⭐ where most app logic lives (singletons)
│   ├── analytics_service.dart       Firebase Analytics + GoRouter observer
│   ├── notification_service.dart    FCM + flutter_local_notifications + tz
│   ├── deep_link_service.dart       URI → GoRouter path
│   ├── pose_detection_service.dart  ML Kit pose detection state machine
│   ├── progress_service.dart        SharedPreferences-backed progress (NOT Firestore)
│   └── pdf_service.dart             session report export
│
├── screens/                  ⭐ UI lives here — bypasses domain/data layers
│   ├── login_screen.dart, register_screen.dart, forgot_password_screen.dart
│   ├── main/                 patient module (12 screens incl. ai_chat, therapy_session)
│   ├── therapist/            therapist module (8 screens)
│   └── profile/              shared profile/settings screens (8 screens)
│
├── widgets/                  ⚠ duplicate of presentation/widgets — common_widgets.dart, error_widget, empty_state_widget, loading_widget, exercise_card
└── models/exercise.dart      ⚠ legacy domain model with hardcoded `allExercises` list — used by the router and screens
```

**Layer boundaries — observed (not designed):** `domain/` and `data/repositories/` are written but  **not consumed by any screen** . UI talks to `FirebaseFirestore.instance` directly. Net effect: there is no enforced layering. The "Clean Architecture" scaffold is aspirational.

**Naming:** `snake_case` for files, `PascalCase` for classes; suffixes `_screen`, `_service`, `_repository_impl`, `_entity`. Consistent.

**Duplication smells:**

* `lib/providers/theme_provider.dart` vs `lib/presentation/providers/theme_provider.dart` (the second is the active one).
* `lib/widgets/common/*` vs `lib/presentation/widgets/common/*` (the first set has tests; the second is unused).
* `lib/models/exercise.dart` (UI model with `IconData`) vs `lib/domain/entities/exercise_entity.dart` + `lib/data/models/exercise_model.dart` (DTO/entity pair) — three exercise types coexist.
* Nora system prompt is defined  **three times** : in `ai_chat_screen.dart`, `chat_repository_impl.dart`, and a shorter inline copy in `therapy_session_screen.dart`.

---

## Dependencies

From [pubspec.yaml](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/pubspec.yaml). SDK constraint: `^3.9.0`. Most Firebase deps are pinned to `any` — fragile.

| Package                         | Version                   | Purpose                                                                             |
| ------------------------------- | ------------------------- | ----------------------------------------------------------------------------------- |
| `firebase_core`               | `any` ⚠                | Firebase init                                                                       |
| `firebase_auth`               | `any` ⚠                | Email/Google auth                                                                   |
| `firebase_app_check`          | `any` ⚠                | API protection (initialized in `core/utils/app_check_service.dart`)               |
| `cloud_firestore`             | `any` ⚠                | Primary DB                                                                          |
| `firebase_storage`            | `any` ⚠                | Imported but only `uploadUserPhoto()` is `UnimplementedError` — appears unused |
| `firebase_analytics`          | `any` ⚠                | Event tracking via `AnalyticsService`                                             |
| `firebase_messaging`          | `any` ⚠                | FCM push                                                                            |
| `flutter_local_notifications` | `^18.0.1`               | Local + scheduled notifications                                                     |
| `timezone`                    | `any` ⚠                | Required by `flutter_local_notifications`                                         |
| `google_sign_in`              | `6.2.1` (exact)         | Google OAuth — pinned because v7 has breaking API                                  |
| `google_generative_ai`        | `^0.4.0`                | Gemini SDK                                                                          |
| `google_mlkit_pose_detection` | `^0.14.0`               | On-device pose detection                                                            |
| `camera`                      | `^0.11.3`               | Camera frames for pose detection                                                    |
| `go_router`                   | `^17.0.1`               | Routing + redirect-based auth gate                                                  |
| `provider`                    | `^6.1.5+1`              | State management (only theme uses it)                                               |
| `flutter_dotenv`              | `^6.0.0`                | `.env` for `GEMINI_API_KEY`                                                     |
| `shared_preferences`          | `^2.5.4`                | Theme +`ProgressService` cache + notification prefs                               |
| `fl_chart`                    | `^1.1.1`                | Progress charts                                                                     |
| `pdf` / `printing`          | `^3.11.3` / `^5.14.2` | Session report PDF                                                                  |
| `share_plus`                  | `^12.0.1`               | Share PDF                                                                           |
| `path_provider`               | `^2.1.5`                | PDF file path                                                                       |
| `url_launcher`                | `^6.3.2`                | External links                                                                      |
| `intl`                        | `^0.20.2`               | Date locale (`es_ES` initialized in `main()`)                                   |
| `image_picker`                | `^1.1.2`                | Profile photo                                                                       |
| `lucide_icons_flutter`        | `^3.1.5`                | Icon set                                                                            |
| `flutter_svg`                 | `^2.2.1`                | SVG assets                                                                          |
| `google_fonts`                | `^6.3.2`                | Imported but I see no usage in screens read — likely unused                        |
| `cupertino_icons`             | `^1.0.8`                | Default Flutter icon font                                                           |

**dev_dependencies:** `flutter_test`, `flutter_lints: ^6.0.0`, `flutter_launcher_icons: ^0.14.4`. **No `mockito`/`mocktail`/`fake_cloud_firestore`** — tests in `test/services/*` are stubs that just `expect(true, isTrue)` because they have no mocking infrastructure.

**Risks flagged:**

1. Eight Firebase packages on `any` — every `flutter pub get` can pull breaking changes. Should be pinned to caret ranges.
2. `firebase_storage` and `google_fonts` look unused.
3. iOS platform support is missing per AGENTS.md, but the app uses several plugins requiring iOS-specific config (`camera`, `image_picker`, FCM, ML Kit, `pdf/printing`).

---

## Auth Flow

End-to-end trace, login screen → role-routed shell:

1. **App launch.** [main.dart:32-34](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/main.dart#L32-L34) calls `Firebase.initializeApp()`, then `AppCheckService().initialize()`, then `AnalyticsService` and `NotificationService`. `MaterialApp.router` mounts `AppRouter.router`.
2. **Initial redirect.** [app_router.dart:62-88](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/router/app_router.dart#L62-L88) — GoRouter's top-level `redirect`:
   * If `FirebaseAuth.instance.currentUser == null` and the path isn't an auth route → `/login`.
   * If logged in and on `/` or `/login` → call `getUserType()`, dispatch to `/therapist` (therapist) or `/main` (everything else, default `patient`).
3. **Role lookup.** [app_router.dart:34-55](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/router/app_router.dart#L34-L55) — `AppRouter.getUserType()`:
   * Reads `FirebaseFirestore.instance.collection('users').doc(uid).data()['userType']`.
   * **Caches in `_cachedUserType` static field** for the session.
   * Defaults to `'patient'` on read failure.
   * **Must be cleared on logout** via `AppRouter.clearUserTypeCache()` — otherwise re-login as a different role lands on the wrong shell. The `goToLogin()` extension does this; ad-hoc `signOut` calls in code may not.
4. **Login screen.** [login_screen.dart:39-80](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/login_screen.dart#L39-L80):
   * User toggles `_userType` (`patient`/`therapist`) — but this is a  **client-supplied claim** , not authoritative. For *email login* it's only used for analytics + topic subscription; the routing decision still reads `userType` back from Firestore. For *Google sign-in of a new user* ([login_screen.dart:115-126](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/login_screen.dart#L115-L126)), the toggle is what gets written to the new `users/{uid}` doc — meaning a user can self-elect therapist on first Google sign-in. **No server-side validation.**
   * Calls `_auth.signInWithEmailAndPassword()`, logs analytics, subscribes to FCM topic by role, clears the role cache, then `_navigateAfterLogin()` reads `userType` and `context.go('/therapist')` or `/main`.
5. **Auth repository.** [data/repositories/auth_repository_impl.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/data/repositories/auth_repository_impl.dart) wraps the same `FirebaseAuth` calls plus `GoogleSignIn`. It exists but **the login screen does not use it** — it instantiates `FirebaseAuth.instance` and `GoogleSignIn()` directly. The repo is dead code today.
6. **State propagation.** There is **no `authStateChanges` listener** wired into the app. Auth-driven re-routing happens only on initial load and on explicit redirects. A token expiry mid-session won't auto-route to `/login`.

**Service-of-record for auth state:** `FirebaseAuth.instance` directly (singleton). Role gate: `AppRouter.getUserType()` (cached). No reactive auth provider.

---

## Data Layer

Two parallel implementations exist for most collections — one in `lib/data/repositories/*_impl.dart` (unused), one inline in screens (used). Below is what the **runtime** actually does, with security notes from [firestore.rules](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/firestore.rules).

### `users/{uid}` — user profiles

* **Owners (writers):** `register_screen.dart` (create), `login_screen.dart` (create on first Google sign-in), `edit_profile_screen.dart` (update), `therapist_profile_screen.dart` (update), `notification_service.dart` (writes `fcmToken`/`fcmTokenUpdatedAt`), `patients_screen.dart:770` (therapist creates patient), `routines_screen.dart:842` (writes patient routine assignments).
* **Readers:** `app_router.dart` (role lookup), `ai_chat_screen.dart` (name/context), `profile_screen.dart`, all therapist screens to resolve patient names, `routines_screen.dart`.
* **Repo skeleton:** `UserRepositoryImpl` exposes `assignTherapist`, `getAllTherapists`, `watchUser`, `uploadUserPhoto` (TODO).
* **Security ([firestore.rules:44-100](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/firestore.rules#L44-L100)):** read by owner, assigned therapist, or therapist for any user where `therapistId == request.auth.uid`. Update gated to owner OR therapist updating only `therapistId`. **Gap:** the rule does not validate `request.resource.data.userType` on create — a self-elected therapist on Google first-login is accepted (matches the screen-side gap).

### `users/{uid}/nora_chats/{chatId}` + `.../messages/{msgId}` — Nora conversations

* Per-user, private. Created/written by `ai_chat_screen.dart` directly; `ChatRepositoryImpl` mirrors the same operations but is unused.
* Title is derived from the first message ([ai_chat_screen.dart:386-403](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart#L386-L403)).
* **Security:** owner-only read/write — solid.

### `users/{uid}/patient_context/summary` — Nora's long-term memory of the patient

* Single document holding a free-text summary that grows by appending. Updated by `_extractAndSavePatientInfo` ([ai_chat_screen.dart:418-434](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart#L418-L434)) — a hardcoded keyword list (`'lesión'`, `'dolor'`, `'cirugía'`, etc.) decides when a user message gets appended verbatim with a date stamp. **No size cap, no PII redaction, no summarization** — grows unbounded and is injected into every Gemini system prompt.
* **Security:** owner read/write + assigned therapist read.

### `users/{uid}/progress/{progressId}` — exercise history

* Written by `ExerciseRepositoryImpl.saveExerciseProgress` (unused) **and** by direct screen code, but in practice progress is currently going to **`SharedPreferences`** via `ProgressService.saveProgress()` ([therapy_session_screen.dart:579](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L579)) — *not* Firestore. The Firestore `progress/` subcollection writes appear in dead code paths.
* **Implication:** progress is  *device-local* . Reinstall = data loss. The therapist cannot see patient progress despite the security rule allowing it, because nothing writes to Firestore here at runtime.
* **Security:** owner + assigned therapist read; owner write.

### `routines/{routineId}` — therapist-authored routines

* Written/read by `lib/screens/therapist/routines_screen.dart` directly. `EXERCISES` subcollection nested under each routine.
* **Security ([firestore.rules:108-122](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/firestore.rules#L108-L122)):** therapist-creator read/write, assigned patient read. Has both top-level `routines/` and a parallel per-user `users/{uid}/routines/` subcollection ([firestore.rules:91-99](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/firestore.rules#L91-L99)) — unclear which is canonical; both are reachable.

### `appointments/{appointmentId}`

* Written by `lib/screens/therapist/calendar_screen.dart` (`add` at line 720, query at line 281). Patient-side view exists but I didn't trace a writer from the patient.
* **Security:** read by either party; create/update/delete therapist-only.

### `conversations/{conversationId}` + `.../messages/{msgId}` — patient↔therapist DM

* Written by `therapist_messages_screen.dart` and `therapist_chat_detail_screen.dart`; the patient-side `therapist_chat_screen.dart` reads.
* **Security:** read/update by either participant. Create allowed for any authenticated user — an attacker could create conversation docs with arbitrary `patientId/therapistId`. Mild integrity hole.

### `exercises/{exerciseId}` — global catalog

* `ExerciseRepositoryImpl` reads it; in practice screens use `lib/models/exercise.dart`'s **hardcoded `allExercises` list** instead. The Firestore catalog appears empty/unused at runtime.
* **Security:** auth read; therapist write.

### `fcm_tokens/{userId_hash}` + token mirror in `users/{uid}.fcmToken`

* Written by `NotificationService._saveTokenToFirestore` and removed by `removeToken`.
* **Security:** owner read/write/create. Solid.

### `notification_settings/{userId}`, `sent_notifications/{id}`, `feedback/{id}`, `user_streaks/{userId}`, `user_achievements/{id}`, `notifications/{id}`

* Defined in rules; I did not trace runtime writers for streaks/achievements — these may be aspirational (AGENTS.md lists "sistema de rachas / sistema de logros" as pending features).

### Missing security considerations

1. `userType` is not validated on create — client decides their role.
2. `conversations` create rule is `if isAuthenticated()` — anyone can spawn conversation docs targeting any pair of users.
3. `feedback/` create permits `isAuthenticated()` without binding `userId == auth.uid` on insert (only enforced on read).
4. The Nora `patient_context/summary` doc has no size limit — a malicious or buggy client can balloon it.
5. App Check is initialized but the rules don't reference `request.app` — protection is at the API edge only.

---

## State Management

 **Provider only** , and only one container is wired:

| Container         | Holds                                                                               | Where                                                                                                                                                           | Consumers                                                                                                  |
| ----------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `ThemeProvider` | `ThemeMode` (system/light/dark), persisted via `SharedPreferences['themeMode']` | [presentation/providers/theme_provider.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/presentation/providers/theme_provider.dart) | `main.dart` (root `ChangeNotifierProvider` + `Consumer<ThemeProvider>`), `profile_screen.dart:802` |

Everything else uses **local `setState`** in `StatefulWidget`s, with `StreamBuilder`/`FutureBuilder` reading directly from `FirebaseFirestore.instance`. There is no `MultiProvider`, no Riverpod, no Bloc, no GetX. `Provider.of<ThemeProvider>` only appears in [core/extensions/context_extensions.dart:31](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/core/extensions/context_extensions.dart#L31).

Singletons used as ambient state:

* `AnalyticsService()`, `NotificationService()`, `DeepLinkService()`, `ProgressService()`, `PoseDetectionService()` — `factory _instance` pattern. Mutable internal state. Treat as global.
* `AppRouter._cachedUserType` — static cache of role.

Implication for testing: nothing is injected, almost everything is a singleton or `Firebase.instance`. The `UserRepositoryImpl` etc. have constructor injection, but no screen uses them.

---

## ML Kit Camera Pipeline

Lives in [therapy_session_screen.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart) + [pose_detection_service.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/services/pose_detection_service.dart).

**End-to-end:**

1. **Init order** ([therapy_session_screen.dart:67-74](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L67-L74)) — `initState` fires four parallel inits: pose detection, camera, AI (Gemini), timer, AI tip scheduler.
2. **Pose detector setup** ([pose_detection_service.dart:69-75](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/services/pose_detection_service.dart#L69-L75)) — `PoseDetector(PoseDetectorOptions(mode: stream, model: base))`. Mapped from exercise title via `PoseDetectionService.getExerciseType(title)` keyword matcher (`'sentadilla' → squat`, `'curl' → bicepCurl`, etc.). 9 supported `ExerciseType`s with per-exercise start/end angle thresholds.
3. **Camera setup** ([therapy_session_screen.dart:122-155](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L122-L155)) — picks **front** camera if available (`firstWhere(front)`), `ResolutionPreset.medium`, `enableAudio: false`, `imageFormatGroup: ImageFormatGroup.nv21` (ML Kit-compatible on Android). Calls `startImageStream(_processFrame)`.
4. **Per-frame loop** ([therapy_session_screen.dart:157-195](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L157-L195)):
   * Drop guard: `if (_isProcessingFrame || _isPaused || !_isPoseDetectionEnabled)` returns. **Single-flight** — no parallel ML inference.
   * `_poseService.processFrame(image, _currentCamera)` → `InputImage.fromBytes(plane.bytes, ...)` → `_poseDetector.processImage()` → `_analyzeExercise(pose)`.
   * Per exercise, computes a key joint angle (`atan2`-based 3-point angle) and runs a `_updateRepCounter` **state machine** (`wasInStartPosition` ↔ `wasInEndPosition`) — increments `_repCount` on the start→end→start cycle.
   * Returns `PoseAnalysisResult { isCorrectForm, primaryAngle, repState, feedback, corrections, confidence }`.
5. **Service → screen callbacks** — `onRepCompleted(int)` updates `_currentRep`, fires "halfway" / "complete" Nora-style hints; `onFeedback(String)` pushes a bubble. UI shows live confidence bar, angle, and form-correction warnings.
6. **AI tips loop** ([therapy_session_screen.dart:227-239](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L227-L239)) — `Timer.periodic(20s)` cycles a hardcoded `_tips` list. Independent of pose detection. **Bug:** this `Timer.periodic` is created in `_scheduleAiTips` but never cancelled in `dispose()` — leaks across sessions.
7. **Manual fallback** — if pose detection toggles off, a `GestureDetector` "Toca para contar rep" lets the user count manually.
8. **Session end** ([therapy_session_screen.dart:343-606](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L343-L606)) — pain-level slider dialog → `ProgressService().saveProgress(...)` (SharedPreferences) → `AnalyticsService().logExerciseCompleted(...)` → `Navigator.pushReplacement` to `SessionReportScreen`.

**dispose() coverage** ([therapy_session_screen.dart:643-653](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L643-L653)):

* ✅ `_timer?.cancel()` (the elapsed-seconds timer)
* ✅ `_cameraController!.stopImageStream()` (guarded by `isStreamingImages`)
* ✅ `_cameraController?.dispose()`
* ✅ `_poseService.dispose()` (closes `PoseDetector`)
* ❌ **The `_scheduleAiTips` `Timer.periodic` is never cancelled** — keeps a closure on `setState` after the screen leaves. Mitigated by `if (!mounted)` early-returns inside, but still a leak.
* ❌ No backgrounding handling — when the app loses focus during a session, the camera stream keeps running. Should hook `WidgetsBindingObserver.didChangeAppLifecycleState` to pause/resume camera + detector.
* ❌ No camera permission denial path — `availableCameras()` failure logs and the screen stays on a spinner.

**Error states:** frame-level errors are swallowed (`} catch (e) { // ignore }`). Pose-detector init failure flips `_isPoseDetectionEnabled = false` and shows "Detección no disponible" — handled.

---

## Nora / Gemini Integration

Two **separate** Gemini integrations, one per screen, plus a third in the unused `ChatRepositoryImpl`. They have  **divergent system prompts and even different model IDs** .

### A. Conversational chat (`AiChatScreen`)

[ai_chat_screen.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart):

* **Model:** `'gemini-3-flash-preview'` ([line 184](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart#L184)) — note: this is a *preview* model; production should be `gemini-1.5-flash` or `gemini-2.0-flash` (the latter is what `api_constants.dart:14` declares). Mismatched constants.
* **API key:** `dotenv.env['GEMINI_API_KEY']` with sentinel fallback `'NO_SE_ENCONTRO_LA_KEY'` — error logged but the screen still constructs the model with the bogus key, deferring failure to first request.
* **System prompt assembly** ([line 318-371](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart#L318-L371)) — interpolates `_userName` (from `users/{uid}.name`) and `_patientContext` (from `users/{uid}/patient_context/summary`). Prompt is the strictest of the three, with explicit safety boundaries (no diagnosis, no prescriptions, recommend pro on red-flag symptoms).
* **History management** ([line 298-316](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart#L298-L316)) — on chat init, builds `List<Content>` = system prompt + initial Nora greeting + every prior message from Firestore translated to alternating `Content.text` / `Content.model([TextPart])`. Calls `_model.startChat(history: history)`.
* **Per-turn flow** ([line 436-493](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/ai_chat_screen.dart#L436-L493)):
  1. Save user message to `users/{uid}/nora_chats/{cid}/messages` + update conversation `lastMessage`/`lastMessageAt`.
  2. Run `_extractAndSavePatientInfo(text)` — keyword scan, append to `patient_context/summary` if any keyword matches.
  3. `_chat.sendMessage(Content.text(text))` → save Nora reply.
* **Error fallback:** custom messages for "API key" and "quota/limit" substrings; otherwise generic "algo salió mal".
* **Conversation ID:** taken from a `?conversationId=` query param on the route, or a new `nora_chats` doc is created on entry.

### B. In-session voice assistant (`TherapySessionScreen`)

[therapy_session_screen.dart:197-225](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/screens/main/therapy_session_screen.dart#L197-L225):

* **Model:** also `'gemini-3-flash-preview'`.
* **System prompt:** much shorter, exercise-specific (`exercise.title`, `targetMuscles`, `description`). No safety preamble beyond "if pain → stop". **No `patient_context` injection** — this Gemini session knows nothing about prior conversations.
* **History:** just the system prompt; not persisted to Firestore.
* **Trigger:** user taps the "Asistente de Voz" sparkle button → `_askAiForHelp()` sends a fixed prompt. There is no STT/TTS — the "voice" label is aspirational.

### C. `ChatRepositoryImpl.sendToNora` (dead code)

* Uses `ApiConstants.geminiModel` = `'gemini-2.0-flash'` (yet another model id).
* Different, shorter system prompt. Not invoked at runtime.

**Findings:**

1. **Three competing Gemini configurations.** The "right" model id depends on which file you read.
2. **`patient_context` is one-way.** Keywords are heuristic (Spanish-only, no negation handling — "no tengo dolor" appends just like "tengo dolor"). Document grows unboundedly and is injected verbatim every turn.
3. **API key is logged at startup if missing** but the model is constructed regardless — the failure surfaces only on first send.
4. **No streaming** — `sendMessage` blocks until the full response, then renders. Long answers feel laggy.
5. **No retries / no rate-limit handling** beyond a generic error string.

---

## Navigation & Routing

All routes from [lib/router/app_router.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/router/app_router.dart):

| Path                       | Name               | Builder                                                                                                                                        | Auth requirement                         |
| -------------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `/`                      | —                 | redirect: logged-out →`/login`, logged-in → `/main` or `/therapist` by role                                                            | —                                       |
| `/login`                 | `login`          | `LoginScreen`                                                                                                                                | unauth (top-level redirect lets it pass) |
| `/register`              | `register`       | `RegisterScreen`                                                                                                                             | unauth                                   |
| `/forgot-password`       | `forgotPassword` | `ForgotPasswordScreen`                                                                                                                       | unauth                                   |
| `/main`                  | `main`           | `MainNavScreen` (BottomNav: home/exercises/messages/progress/profile)                                                                        | logged-in                                |
| `/main/chat/nora`        | `noraChat`       | `AiChatScreen(conversationId: query.conversationId)`                                                                                         | logged-in                                |
| `/main/chat/therapist`   | `therapistChat`  | `TherapistChatScreen`                                                                                                                        | logged-in                                |
| `/main/exercise/:id`     | `exerciseDetail` | `ExerciseDetailScreen` — first checks `state.extra as Exercise?`, then falls back to `allExercises.firstWhere(id)`, then error scaffold | logged-in                                |
| `/main/countdown`        | `countdown`      | `CountdownScreen` (requires `state.extra as Exercise`)                                                                                     | logged-in                                |
| `/main/therapy-session`  | `therapySession` | `TherapySessionScreen` (requires `state.extra as Exercise`)                                                                                | logged-in                                |
| `/main/session-report`   | `sessionReport`  | `SessionReportScreen` (requires extra map)                                                                                                   | logged-in                                |
| `/profile/edit`          | `editProfile`    | `EditProfileScreen`                                                                                                                          | logged-in                                |
| `/profile/security`      | `security`       | `SecurityScreen`                                                                                                                             | logged-in                                |
| `/profile/therapist`     | `myTherapist`    | `MyTherapistScreen`                                                                                                                          | logged-in                                |
| `/profile/text-size`     | `textSize`       | `TextSizeScreen`                                                                                                                             | logged-in                                |
| `/profile/high-contrast` | `highContrast`   | `HighContrastScreen`                                                                                                                         | logged-in                                |
| `/profile/notifications` | `notifications`  | `NotificationsScreen`                                                                                                                        | logged-in                                |
| `/profile/help`          | `helpCenter`     | `HelpCenterScreen`                                                                                                                           | logged-in                                |
| `/profile/privacy`       | `privacyPolicy`  | `PrivacyPolicyScreen`                                                                                                                        | logged-in                                |
| `/therapist`             | `therapistMain`  | `TherapistMainNavScreen` (5 tabs: patients/routines/calendar/messages/profile)                                                               | logged-in                                |

**Auth guard:** single top-level `redirect`. There is **no role-based guard** — a patient who navigates to `/therapist` would land on the therapist shell (the redirect only prevents logged-out access; it routes by role  *only on entry to `/` or `/login`* ). This is a real bug: `context.go('/therapist')` from a patient session would render therapist UI. The therapist screens then enforce by querying Firestore and hitting permission denials, so it's defense-in-depth rather than catastrophic — but the UX is undefined.

**Profile routes are flat (`/profile/*`) instead of nested under `/main` or `/therapist`** — both roles share them, but back-navigation via `Navigator.pop` from these returns to whichever route pushed them, which is fragile across deep-link entry.

**Deep links:** [deep_link_service.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/lib/services/deep_link_service.dart) parses `rehabtech://...` and `https://rehabtech.app/...` into GoRouter paths. Schemes supported: `exercise/:id`, `chat/nora|therapist`, `profile/*`, `progress`, `routine/:id` (target route doesn't exist), `notification?type=...`. **Issue:** deep links always route to `/main/...` — a logged-in therapist who taps a deep link lands on the patient shell.

**Back-navigation correctness:**

* The patient `/main` shell uses `IndexedStack`-style local nav, so back from a sub-route returns to `/main` correctly.
* `TherapySessionScreen → SessionReportScreen` uses `Navigator.pushReplacement` (not GoRouter), bypassing the route stack — pressing back from the report goes wherever GoRouter thinks the previous route was, which may be the `/main/therapy-session` ghost.
* `goToLogin()` extension clears the role cache; bare `_auth.signOut()` calls (e.g. in profile screens) might not.

**Error route:** GoRouter `errorBuilder` shows a generic 404 with "Ir al inicio" → `/main` — which itself errors for logged-out users (would re-redirect to `/login`).

---

## Test Coverage

`flutter test --coverage` ran 62 tests:  **54 passed, 8 failed** , in ~7s.

The 8 failures are all in [test/widget_test.dart](vscode-webview://0mspf2l0lq3ts2377s95vd4cf9rk7hm7atdhuqn59htt1t34mgs9/test/widget_test.dart) — the **stale Flutter starter "counter increments smoke test"** that `pumpWidget(MyApp())` and looks for a `Text('0')`. `MyApp` is the real RehabTech root, so it tries to init Firebase in the test harness and dies. This test has nothing to do with the app — should be deleted.

**Overall line coverage: 4.4%** (351 / 7,966 lines).

By layer:

| Layer                                          | Coverage                              | Notes                                                      |
| ---------------------------------------------- | ------------------------------------- | ---------------------------------------------------------- |
| `widgets/common/error_widget.dart`           | **100%** (50/50)                | Tested in `common_widgets_test.dart`                     |
| `core/theme/app_theme.dart`                  | **98.3%** (59/60)               | Constructed by `ThemeProvider` during widget tests       |
| `models/exercise.dart`                       | **97.0%** (32/33)               | Touched by router tests indirectly                         |
| `widgets/common/empty_state_widget.dart`     | 85.1%                                 | Tested                                                     |
| `widgets/common/loading_widget.dart`         | 77.3%                                 | Tested                                                     |
| `services/deep_link_service.dart`            | 67.9%                                 | Has dedicated test                                         |
| `core/utils/logger.dart`                     | 57.4%                                 | Used by tested widgets                                     |
| `presentation/providers/theme_provider.dart` | 30.4%                                 | Constructed in widget tests                                |
| `main.dart`                                  | 28.6%                                 | The broken `widget_test.dart` exercises `MyApp.build`  |
| `services/analytics_service.dart`            | 4.2%                                  | Stub tests                                                 |
| `router/app_router.dart`                     | 3.1%                                  | Stub tests                                                 |
| `screens/**`                                 | **~0%**                         | None of the 28 screens have tests                          |
| `services/pose_detection_service.dart`       | **0%**                          | 281 lines of math/state-machine, untested                  |
| `services/notification_service.dart`         | **0%**                          | 115 lines, untested                                        |
| `services/progress_service.dart`             | **0%**                          | The component that*actually* persists progress, untested |
| `services/pdf_service.dart`                  | **0%**                          | Untested                                                   |
| `core/utils/error_handler.dart`              | **0%**                          | Untested despite being installed in `main()`             |
| `data/repositories/*_impl.dart`              | **0%**                          | Repos exist; no tests                                      |
| `domain/entities/*`                          | **0%** (those with line counts) |                                                            |
| `firebase_options.dart`                      | 0%                                    | OK — auto-generated                                       |

**Test quality:** the `analytics_service_test.dart` and `notification_service_test.dart` files contain stub tests that just `expect(true, isTrue)` because mocking infra isn't set up. They inflate the test count without testing anything. `deep_link_service_test.dart` and `common_widgets_test.dart` are real.

**Practical state:** the only meaningfully-tested code is `widgets/common/*` and `deep_link_service.dart`. All Firebase-touching logic, all screens, the entire pose detection pipeline, both Gemini integrations, and progress persistence are uncovered.

---

## Knowledge Gaps

1. **Patient↔therapist linking flow.** `users/{uid}.therapistId` is the join column, but I only saw therapist-side writers. How does a patient initially get linked — is it the therapist who creates the patient user (write to `users/`) and the patient claims it via the 6-digit `patientId` mentioned in AGENTS.md, or is it the patient who picks a therapist? **Question:** what's the canonical onboarding sequence that establishes the `therapistId` field?
2. **Routines — top-level vs nested.** Both `routines/{id}` (top-level) and `users/{uid}/routines/{id}` (per-user subcollection) have security rules. I only saw `routines_screen.dart` writing to the top-level. **Question:** is the per-user subcollection live, or dead from an earlier schema?
3. **Progress sync intent.** `ProgressService` writes to SharedPreferences only, but `ExerciseRepositoryImpl.saveExerciseProgress` writes to Firestore (and is unused). **Question:** is the SharedPreferences-only persistence intentional (offline-first plan, sync later) or a regression that needs fixing? It currently breaks the therapist's ability to see progress.
4. **Self-elected `userType`.** First Google sign-in writes whatever role toggle the user picked on the login screen. **Question:** is this acceptable in your threat model, or should role assignment require therapist verification / a magic-link?
5. **Gemini model id.** Three different ids (`gemini-3-flash-preview`, `gemini-2.0-flash`, the AGENTS.md mention of `gemini-1.5-flash`). **Question:** which one is the production target — `gemini-3-flash-preview` is unsuitable for prod.
6. **Streaks/achievements/notifications collections.** Rules exist for `user_streaks`, `user_achievements`, `notifications`, `sent_notifications`, `feedback`. I didn't find runtime writers for streaks/achievements. **Question:** are these implemented elsewhere (Cloud Functions backend), or pending features?
7. **iOS readiness.** AGENTS.md says "iOS pendiente". **Question:** is the iOS Xcode project intentionally absent, or scaffolded but uncommitted? `flutter_launcher_icons.ios: true` is set but I haven't checked the `ios/` directory.
8. **Cloud Functions / backend.** FCM push *send* and `sent_notifications.create` look like they need a server. **Question:** is there a Cloud Functions repo I'm not seeing, or is FCM send currently driven from device-side only?
9. **Tests intent.** The stub tests in `test/services/*` look like placeholders someone meant to fill in with mockito. **Question:** is there an active plan to wire mocking infra (`mockito` / `fake_cloud_firestore`), or should these stubs be deleted?
10. **`presentation/widgets/common/*` vs `widgets/common/*`.** Two parallel widget directories. Tests cover the older `widgets/common/*`. **Question:** which is canonical — should I migrate consumers and delete the other?
