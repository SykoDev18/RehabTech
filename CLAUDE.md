# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RehabTech is a Flutter mobile app for physical rehabilitation. It has two role-based modules — patient and therapist — backed by Firebase, with a Gemini-powered chat assistant called **Nora** and ML Kit pose detection during therapy sessions. UI strings are Spanish (MX/LATAM); code/logs are English.

For deeper context (Firestore schema, design tokens, troubleshooting, conventions) see [AGENTS.md](AGENTS.md). It is the canonical reference — prefer reading it over re-deriving from the codebase. [README.md](README.md) covers the same ground at a lighter level.

## Common commands

```bash
flutter pub get                       # install dependencies
flutter run                           # debug run (uses .env at project root)
flutter analyze                       # MUST run after edits — gates considered "done"
flutter test                          # all tests
flutter test test/services/analytics_service_test.dart   # single file
flutter test --coverage
flutter build apk --release           # Android release

# Firebase (requires firebase-tools)
firebase deploy --only firestore:rules,storage:rules
firebase deploy --only firestore:indexes
```

The app **requires** `.env` at the project root with `GEMINI_API_KEY=...`. It is declared as an asset in [pubspec.yaml](pubspec.yaml) and loaded by `dotenv.load()` in [main.dart](lib/main.dart). Missing it crashes startup.

## Architecture

The codebase is mid-migration from a flat `screens/` + `services/` layout toward Clean Architecture (`domain/`, `data/`, `presentation/`). Both layouts coexist — when editing, follow the pattern of the surrounding code rather than forcing a particular structure.

### Entry point flow ([lib/main.dart](lib/main.dart))

`main()` runs inside `runZonedGuarded` so all uncaught errors funnel through `ErrorHandler`. Init order matters and is roughly:

1. `WidgetsFlutterBinding.ensureInitialized()` → `ErrorHandler().initialize()`
2. `Firebase.initializeApp()` → `AppCheckService` → `AnalyticsService` → `NotificationService`
3. `dotenv.load(".env")` (after Firebase, so secrets aren't needed for Firebase init)
4. `initializeDateFormatting('es_ES', null)` and `ProgressService().init()`
5. `runApp(MyApp)` — wraps `MaterialApp.router` with `ThemeProvider` (Provider) and an `ErrorListener` builder so SnackBars from errors have a `ScaffoldMessenger`.

If you add a new global service, slot it into this sequence — don't lazy-init from a screen.

### Routing & role gating ([lib/router/app_router.dart](lib/router/app_router.dart))

GoRouter with a top-level `redirect` that checks `FirebaseAuth.currentUser` and dispatches by `userType` field on `users/{uid}`:

- `patient` → `/main` (BottomNav shell)
- `therapist` → `/therapist`

`AppRouter._cachedUserType` caches the Firestore lookup for the session. **Always call `AppRouter.clearUserTypeCache()` on logout** (the `goToLogin()` extension does this) — otherwise a re-login as a different role lands on the wrong shell. The `GoRouterExtension` on `BuildContext` (e.g. `context.goToNoraChat()`) is the preferred navigation API; prefer it over raw `context.go(...)` strings.

Deep links use scheme `rehabtech://...` and HTTPS app links `https://rehabtech.app/...` — see [lib/services/deep_link_service.dart](lib/services/deep_link_service.dart).

### Services (singletons)

All services in `lib/services/` are singletons via the `factory _instance` pattern. Treat them as global — instantiating a second one breaks state (e.g. FCM token registration). Key ones:

- **AnalyticsService** — exposes `.observer` consumed by GoRouter; methods log domain events. Firebase Analytics rejects `bool` params — convert to `int` (`isActive ? 1 : 0`).
- **NotificationService** — FCM + flutter_local_notifications + timezone. Has a top-level `@pragma('vm:entry-point')` background handler.
- **ProgressService**, **PdfService**, **PoseDetectionService** (ML Kit), **DeepLinkService**.

### Firestore data model

Documented in detail in [AGENTS.md](AGENTS.md#-base-de-datos-firestore). Key relationships:

- `users/{uid}` carries `userType` (`patient`|`therapist`) and, for patients, `therapistId` linking to the assigned therapist.
- Nora chats are nested under the user: `users/{uid}/nora_chats/{chatId}/messages/{msgId}` (per-user, private).
- Patient↔therapist messaging lives in top-level `conversations/{id}/messages/{id}`.

[firestore.rules](firestore.rules) enforce the `request.auth.uid == userId` pattern plus therapist-of-patient reads via `get(...users/$(userId)).data.therapistId`. Required composite indexes are in [firestore.indexes.json](firestore.indexes.json) — adding a new query that filters+orders on different fields will require an index addition there.

### State

Provider-only (`provider: ^6.x`). The single global `ChangeNotifierProvider` is `ThemeProvider` in [lib/presentation/providers/theme_provider.dart](lib/presentation/providers/theme_provider.dart). Most screens use `StatefulWidget` + `StreamBuilder` against Firestore directly. Don't introduce a second state-management library.

## Project-specific gotchas

- **Lucide icon renames:** use `LucideIcons.circleAlert`, not the deprecated `alertCircle`. Other Lucide icons have similarly renamed; check before assuming.
- **Firebase Analytics params:** only `String`/`num`. Cast booleans to `int`.
- **`.env` is in assets:** changes to `.env` require a hot restart (not hot reload) to take effect.
- **Firebase API keys in `firebase_options.dart` are public by design** — they're protected by App Check, not by secrecy. Don't try to move them to `.env`.
- **Android core-library desugaring** is already configured in `android/app/build.gradle.kts` for `flutter_local_notifications`. Don't remove it.
- **Google Sign-In on Android** needs the debug keystore SHA-1 registered in Firebase Console; `DEVELOPER_ERROR` at sign-in time means the SHA-1 is missing for the current build variant.

## Conventions

- Files: `snake_case`, with suffixes `_screen.dart`, `_service.dart`, `_widget.dart`.
- After any code change, run `flutter analyze` before reporting done.
- UI strings in Spanish; code, comments, and logs in English.
- Always check `mounted` after `await` before using `BuildContext` (lints will flag it, but it's worth being deliberate about).
