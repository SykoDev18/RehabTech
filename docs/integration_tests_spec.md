# RehabTech — Integration Test Spec

This document is the **implementation spec** for end-to-end integration tests.
It exists because the test plan that produced [the unit + widget suite](../test/) deferred
Phase 3 — those tests need infrastructure that isn't yet wired into the
project (the `integration_test` package and the Firebase Emulator Suite).

When the next session sets that up, this document is the contract. The
flows below are written as Given / When / Then so they can be implemented
verbatim.

---

## 1. Required packages

Add these to `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  patrol: ^3.0.0          # optional; only if multi-app gestures are needed
```

> **Why `integration_test` and not just `flutter_test`?** `flutter_test`
> renders into a headless TestWidgetsFlutterBinding — it can't reach
> platform channels or external services. `integration_test` boots a real
> Flutter engine on a device or emulator, which means `FirebaseAuth.instance`
> talks to a real (or emulated) Firebase backend instead of throwing.

Run after adding:

```bash
flutter pub get
```

---

## 2. Firebase Emulator setup (Windows)

### 2.1 One-time install

```powershell
# Java JDK 17+ (emulators require a JVM)
winget install --id EclipseAdoptium.Temurin.17.JDK

# Firebase CLI
npm install -g firebase-tools

# Verify
firebase --version
java -version
```

### 2.2 Emulator config in this repo

Create `firebase.json` (extend the existing one if present) with:

```json
{
  "emulators": {
    "auth":      { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "storage":   { "port": 9199 },
    "ui":        { "enabled": true, "port": 4000 }
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

### 2.3 Wire the app to talk to the emulator in test mode

Add a guarded block in `lib/main.dart` (or a dedicated `lib/firebase_init.dart`):

```dart
const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

await Firebase.initializeApp(...);

if (useEmulator) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

Run integration tests with the flag:

```powershell
flutter test integration_test --dart-define=USE_EMULATOR=true
```

### 2.4 Daily workflow

```powershell
# Terminal A — emulators (keep running)
firebase emulators:start --only auth,firestore,functions,storage

# Terminal B — run the test suite
flutter test integration_test --dart-define=USE_EMULATOR=true
```

> **Tip:** the emulator UI at `http://localhost:4000` shows live Firestore
> contents and auth users — invaluable for diagnosing seed-data drift.

---

## 3. Seed data scripts

Each integration test must start from a **deterministic** state. Two seed
scripts are needed:

### 3.1 `test/integration/_seed/users_seed.dart`

```dart
// Loaded by setUp(). Creates a known patient + therapist pair and links
// them via `users/{patient}.therapistId = <therapistUid>`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeededUsers {
  const SeededUsers({
    required this.patientUid,
    required this.therapistUid,
    required this.patientEmail,
    required this.therapistEmail,
    this.password = 'test1234',
  });
  final String patientUid;
  final String therapistUid;
  final String patientEmail;
  final String therapistEmail;
  final String password;
}

Future<SeededUsers> seedDefaultUsers() async {
  final auth = FirebaseAuth.instance;
  final fs = FirebaseFirestore.instance;

  // Therapist
  final t = await auth.createUserWithEmailAndPassword(
    email: 'therapist@test.local',
    password: 'test1234',
  );
  await fs.collection('users').doc(t.user!.uid).set({
    'name': 'Dra. Test',
    'email': 'therapist@test.local',
    'userType': 'therapist',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Patient (linked to that therapist)
  final p = await auth.createUserWithEmailAndPassword(
    email: 'patient@test.local',
    password: 'test1234',
  );
  await fs.collection('users').doc(p.user!.uid).set({
    'name': 'Marco',
    'lastName': 'Test',
    'email': 'patient@test.local',
    'userType': 'patient',
    'therapistId': t.user!.uid,
    'patientId': 'TEST0001',
    'createdAt': FieldValue.serverTimestamp(),
  });

  await auth.signOut();

  return SeededUsers(
    patientUid: p.user!.uid,
    therapistUid: t.user!.uid,
    patientEmail: 'patient@test.local',
    therapistEmail: 'therapist@test.local',
  );
}

/// Wipes everything between tests. Reset the emulator HTTP endpoint instead
/// of trying to delete docs one-by-one.
Future<void> resetEmulator() async {
  final projectId = 'rehabtech-test';
  for (final path in const [
    'http://localhost:9099/emulator/v1/projects/$projectId/accounts',
    'http://localhost:8080/emulator/v1/projects/$projectId/databases/(default)/documents',
  ]) {
    // ignore: avoid_dynamic_calls
    await HttpClient().deleteUrl(Uri.parse(path)).then((r) => r.close());
  }
}
```

### 3.2 `test/integration/_seed/routines_seed.dart`

```dart
Future<String> seedRoutineForPatient({
  required String patientId,
  required String therapistId,
}) async {
  final fs = FirebaseFirestore.instance;
  final ref = await fs.collection('routines').add({
    'name': 'Rutina de prueba',
    'patientId': patientId,
    'therapistId': therapistId,
    'createdAt': FieldValue.serverTimestamp(),
    'exercises': [
      {'name': 'Sentadilla', 'series': 3, 'reps': 10, 'order': 0},
      {'name': 'Plancha',    'series': 1, 'reps': 1,  'order': 1, 'durationSeconds': 30},
    ],
  });
  return ref.id;
}
```

---

## 4. Integration flows (Given / When / Then)

Every flow runs against a freshly reset emulator (call `resetEmulator()`
in `setUp`).

### Flow 1 — Patient full journey

> **Why this flow?** It's the daily-use happy path: a patient logs in,
> sees their assigned routines, opens one, runs through a session, logs
> their pain at the end, and leaves. If this breaks, the app is unusable
> for the patient role.

**Given**
- The emulator is running and reset.
- `seedDefaultUsers()` was called → patient + therapist exist and are linked.
- `seedRoutineForPatient(patient, therapist)` created one routine with two
  exercises.

**When**
1. The app boots at `/login`.
2. The user types `patient@test.local` / `test1234` and taps **Iniciar Sesión**.
3. Router redirects to `/main` (patient shell, BottomNav).
4. The user taps the "Mis Rutinas" shortcut on Home.
5. The user taps the only routine card.
6. The user taps **Iniciar sesión** on the exercise detail.
7. The countdown finishes, the therapy session screen runs, and the user
   taps **Finalizar**.
8. A pain-rating dialog appears; the user picks 4 and taps **Guardar**.
9. The session report appears.
10. The user taps **Cerrar** and returns to the routines list.

**Then**
- The router never navigates to `/therapist`.
- After the session, `users/{patientUid}/progress/<auto>` exists and has
  `painLevel == 4`, `routineId == <seeded id>`, and `durationSeconds > 0`.
- `progressService.progressList` includes the new entry.
- The "Mis Rutinas" screen still lists the same routine.

### Flow 2 — Therapist full journey

> **Why this flow?** The therapist is the supply side — they create the
> work that patients consume. Verifies the patient list filter, routine
> creation, and assignment write-through.

**Given**
- The emulator is running and reset.
- `seedDefaultUsers()` was called.

**When**
1. The app boots at `/login` and the user toggles **Soy Terapeuta**.
2. Logs in as `therapist@test.local`.
3. Router redirects to `/therapist`.
4. The patient list shows exactly one patient (`Marco Test`).
5. The user taps that patient → `PatientDetailScreen`.
6. Taps **Crear rutina** → routine builder.
7. Adds an exercise (name, 3 series × 10 reps) and saves.
8. Returns to the patient detail; the new routine is listed.

**Then**
- A new doc exists in `routines/` with `therapistId == therapistUid`,
  `patientId == patientUid`, and the saved exercises array.
- The patient KPI card on the dashboard shows count 1 for Pacientes,
  Rutinas activas ≥ 1.
- Logging in as the patient (after sign-out) immediately shows the new
  routine on `MyRoutinesScreen`.

### Flow 3 — Patient ↔ Therapist chat

> **Why this flow?** Top-level `conversations/{id}/messages/{id}` carries
> the human-to-human channel and is governed by separate rules. Verifies
> a message round-trips both directions and that rules permit it for the
> linked pair.

**Given**
- The emulator is running and reset.
- `seedDefaultUsers()` was called.
- A `conversations/{convId}` doc exists with members
  `[patientUid, therapistUid]`.

**When**
1. Patient logs in and opens **Mensajes** → the seeded conversation.
2. Patient sends `"Hola, me duele el hombro derecho desde ayer"`.
3. Patient signs out; therapist signs in; opens the conversation.
4. Therapist replies `"Vamos a revisarlo en la próxima sesión"`.

**Then**
- `conversations/{convId}/messages` has 2 docs in chronological order.
- Each doc has `senderId` matching the actor and `createdAt` server
  timestamps in increasing order.
- Both clients render the new message inside 5s of the write
  (verified via `pumpAndSettle` looped with a 10s timeout).
- The conversation's `lastMessage` and `lastMessageAt` reflect the most
  recent reply.

---

## 5. Test file scaffolding

```
test/integration/
├── _seed/
│   ├── users_seed.dart
│   └── routines_seed.dart
├── patient_full_flow_test.dart
├── therapist_full_flow_test.dart
└── chat_flow_test.dart
```

Each `*_test.dart` follows this template:

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/main.dart' as app;
import '_seed/users_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetEmulator();
  });

  testWidgets('patient runs a routine end-to-end', (tester) async {
    final seeded = await seedDefaultUsers();
    final routineId = await seedRoutineForPatient(
      patientId: seeded.patientUid,
      therapistId: seeded.therapistUid,
    );

    app.main();
    await tester.pumpAndSettle();

    // ... drive the flow with tester.tap / tester.enterText ...
  });
}
```

---

## 6. CI considerations (deferred)

When wiring this into CI:

- Use the official `firebase-tools-instrumentation` Docker image OR install
  `firebase-tools` in a setup step.
- Cache `~/.cache/firebase/emulators` between runs — the Java emulator
  binaries are >100 MB.
- Run integration tests on a single Android emulator instance via
  `flutter test integration_test --device-id <emulator>`.
- Tag flaky-looking tests with `@Tags(['integration'])` so the unit suite
  stays green and fast.

---

## 7. Things explicitly NOT in scope here

- **ML Kit pose detection.** Real pose detection requires a camera. Out of
  emulator reach. Cover those screens with widget tests + a fake
  `PoseDetectionService`.
- **Gemini / Nora live calls.** Already covered by mocks
  (`NoraModelClient` is injectable). Don't burn quota in CI.
- **Apple sign-in.** Not implemented in the production code yet.
- **FCM push delivery.** Emulator has no FCM equivalent; rely on
  `NotificationService` unit tests with a fake messaging instance.
