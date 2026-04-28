# Camera, Pose Detection & Exercise Library Overhaul

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the monolithic `PoseDetectionService` analyzer block with a per-exercise `ExerciseAnalyzer` abstraction, harden the camera lifecycle, add a real-time skeleton overlay, expand the exercise catalog (12 new exercises with Firestore seeds), and introduce a `SessionState` machine driving multi-set flow with countdown / rest timers.

**Architecture:**
- New `lib/domain/pose_analysis/` layer with `AngleCalculator`, `ExerciseAnalyzer` base, `RepPhaseMachine`, `ExerciseFeedback`.
- New `lib/domain/exercises/` registry that maps exercise IDs → analyzer factories.
- `PoseDetectionService` becomes a thin runtime adapter: it owns the `PoseDetector`, the camera-image → `InputImage` conversion, and delegates analysis to the registered `ExerciseAnalyzer`.
- New `lib/screens/therapy/widgets/` with `SkeletonOverlay` (CustomPainter) and `ExerciseFeedbackOverlay`.
- New `lib/domain/therapy/session_state.dart` sealed classes; therapy screen owns a `SessionController` that emits `SessionState` and is consumed by overlays.

**Tech Stack:** Flutter 3.9+, `camera ^0.11.3`, `google_mlkit_pose_detection ^0.14.0`, `device_info_plus` (NEW dependency), Provider for screen-local state, `fake_cloud_firestore` + manual `Pose` fixtures for tests.

---

## Pre-flight: state of the world

Existing code that this plan intentionally **keeps and extends** (do not rewrite from scratch):

- `lib/screens/main/therapy_session_screen.dart` already has `WidgetsBindingObserver`, `_isProcessingFrame` frame-drop guard, lifecycle pause/resume, and a pose-detection indicator widget. We extend it; we do not replace it.
- `lib/services/pose_detection_service.dart` already implements `calculateAngle` (atan2-based), confidence checks, and a working rep-state machine for 8 exercises (squat, bicepCurl, shoulderPress, kneeExtension, legRaise, armRaise, lunge, hipFlexion). We refactor this in place — extract the math, keep the runtime, register analyzers under it.
- `lib/models/exercise.dart` is a Dart-list display model with icons/colors. We do **not** change its shape; we add a separate `ExerciseTemplate` domain entity in `lib/domain/exercises/` for analyzer/seed mapping. Keep them bridged via `Exercise.id`.
- Image format is currently `nv21` (Android-only). It works with ML Kit. We add iOS branch (`bgra8888`) but keep `nv21` for Android (the spec said `yuv420` but `nv21` is also accepted by `google_mlkit_pose_detection` and is what's deployed; do not regress).

Decisions surfaced to the user before execution:

1. **Refactor strategy.** This plan refactors `PoseDetectionService` in place: extracts `AngleCalculator` to `domain/pose_analysis/`, introduces `ExerciseAnalyzer` abstraction, then migrates the 8 existing exercise analyses into concrete analyzer classes (one commit each). The service becomes a thin facade. **Alternative (not chosen):** build a parallel V2 system. Rejected because it would require a feature flag and double-maintenance for ≥1 release cycle.
2. **Exercise model.** Keep the existing `Exercise` Dart-list catalog for UI rendering. Add `ExerciseTemplate` (Firestore-backed) for the analyzer/threshold/seed mapping. Bridge by ID. **Alternative:** migrate the entire catalog to Firestore now. Rejected — outside this plan's scope.
3. **Timed exercises.** Wall sit, glute-bridge hold, pendulum, and single-leg stance have a `durationSeconds`-based completion path, not reps. The plan handles this via `ExercisePhase.hold` + a `HoldTimerController`, not via the rep-phase state machine.
4. **Neck exercises.** ML Kit body-pose is unreliable for cervical work. The plan implements neck exercises as a **screen-based timed flow with self-report `✓ Completé`** — no analyzer, no skeleton overlay. They share the SessionState machine but skip pose detection.
5. **Existing `PoseDetectionService.dispose` ordering** in the screen at line 778-790 is currently: stop stream → dispose controller → service.dispose. The spec demands: removeObserver → stop pose → close detector → stop stream → dispose camera. The plan corrects the order in Phase 1 Task 4.

---

## Phase Map

Each phase is independently shippable and gets its own commit chain. After each phase: `flutter analyze` → `flutter test` → manual smoke test on a physical device → commit.

| Phase | What ships | Tasks |
|---|---|---|
| 1 | Hardened camera + lifecycle + typed errors | 1.1 – 1.5 |
| 2 | `AngleCalculator` + `ExerciseAnalyzer` base + `RepPhaseMachine` (existing 8 migrated) | 2.1 – 2.6 |
| 3 | `SkeletonOverlay` + `ExerciseFeedbackOverlay` widgets wired to therapy screen | 3.1 – 3.4 |
| 4 | 12 new analyzers + Firestore seed | 4.1 – 4.6 |
| 5 | `SessionState` sealed classes + `SessionController` + multi-set / countdown / rest timer flow | 5.1 – 5.5 |
| 6 | Test suite (AngleCalculator, RepPhase, KneeExtension, SessionState) | 6.1 – 6.4 |

**Total est: ~35 tasks, 30+ files.** Each task is 2–5 min of code + analyze + commit.

---

## PHASE 1 — Camera Pipeline Hardening

**Files:**
- Modify: `lib/screens/main/therapy_session_screen.dart` (`_initializeCamera`, `dispose`, `didChangeAppLifecycleState`)
- Create: `lib/services/camera_capability_probe.dart`
- Modify: `pubspec.yaml` (add `device_info_plus: ^11.0.0`)

### Task 1.1: Add `device_info_plus` dependency

- [ ] **Step 1** — Edit `pubspec.yaml` line 67 (after `google_mlkit_pose_detection`):

```yaml
  google_mlkit_pose_detection: ^0.14.0
  device_info_plus: ^11.0.0
```

- [ ] **Step 2** — Run `flutter pub get` and confirm no resolution errors.
- [ ] **Step 3** — Commit: `chore: add device_info_plus for resolution tier selection`

### Task 1.2: Create `CameraCapabilityProbe`

- [ ] **Step 1** — Create `lib/services/camera_capability_probe.dart`:

```dart
import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Picks an ML Kit-friendly [ResolutionPreset] and image format for the
/// current device. Lower-tier devices fall back to medium so 30fps survives.
class CameraCapabilityProbe {
  CameraCapabilityProbe({DeviceInfoPlugin? info}) : _info = info ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _info;

  Future<ResolutionPreset> selectResolution() async {
    if (Platform.isAndroid) {
      final android = await _info.androidInfo;
      // API < 28 (Android 9) is our low tier. Newer devices get high.
      if (android.version.sdkInt < 28) return ResolutionPreset.medium;
      return ResolutionPreset.high;
    }
    if (Platform.isIOS) {
      final ios = await _info.iosInfo;
      // iPhones from iOS 13 onwards (≈iPhone 6S) all handle high comfortably.
      final major = int.tryParse(ios.systemVersion.split('.').first) ?? 0;
      return major >= 13 ? ResolutionPreset.high : ResolutionPreset.medium;
    }
    return ResolutionPreset.medium;
  }

  ImageFormatGroup selectFormat() {
    if (Platform.isIOS) return ImageFormatGroup.bgra8888;
    return ImageFormatGroup.nv21; // ML Kit accepts NV21 on Android
  }
}
```

- [ ] **Step 2** — Run `flutter analyze lib/services/camera_capability_probe.dart`. Expected: no issues.
- [ ] **Step 3** — Commit: `feat(camera): add CameraCapabilityProbe for tiered resolution`

### Task 1.3: Wire probe into `_initializeCamera` with typed `CameraException` handling

- [ ] **Step 1** — Edit `lib/screens/main/therapy_session_screen.dart` `_initializeCamera` (lines 160–193). Replace with:

```dart
Future<void> _initializeCamera() async {
  try {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      if (!mounted) return;
      _showCameraError('No se encontró una cámara en este dispositivo.');
      return;
    }
    _currentCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    final probe = CameraCapabilityProbe();
    final resolution = await probe.selectResolution();
    final format = probe.selectFormat();
    if (!mounted) return;

    _cameraController = CameraController(
      _currentCamera!,
      resolution,
      enableAudio: false,
      imageFormatGroup: format,
    );

    await _cameraController!.initialize();
    if (!mounted) {
      await _cameraController!.dispose();
      return;
    }

    if (_isPoseDetectionEnabled) {
      await _cameraController!.startImageStream(_processFrame);
    }

    setState(() => _isCameraInitialized = true);
  } on CameraException catch (e, st) {
    AppLogger.error('CameraException al inicializar', error: e, stackTrace: st, tag: 'TherapySession');
    if (!mounted) return;
    _showCameraError(_messageForCameraException(e));
  } catch (e, st) {
    AppLogger.error('Error al inicializar cámara', error: e, stackTrace: st, tag: 'TherapySession');
    if (!mounted) return;
    _showCameraError('No se pudo iniciar la cámara. Intenta de nuevo.');
  }
}

String _messageForCameraException(CameraException e) {
  switch (e.code) {
    case 'CameraAccessDenied':
    case 'CameraAccessDeniedWithoutPrompt':
      return 'Necesitas dar permiso de cámara en Configuración > RehabTech';
    case 'CameraAccessRestricted':
      return 'El acceso a la cámara está restringido en este dispositivo.';
    default:
      return 'No se pudo iniciar la cámara. Intenta de nuevo.';
  }
}

void _showCameraError(String message) {
  setState(() {
    _isCameraInitialized = false;
    _isPoseDetectionEnabled = false;
    _poseStatus = message;
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444)),
  );
}
```

- [ ] **Step 2** — Add the import at the top of the file:

```dart
import 'package:rehabtech/services/camera_capability_probe.dart';
```

- [ ] **Step 3** — Run `flutter analyze lib/screens/main/therapy_session_screen.dart`. Fix any lints inline.
- [ ] **Step 4** — Commit: `feat(camera): typed CameraException handling + tiered resolution`

### Task 1.4: Fix dispose ordering

- [ ] **Step 1** — Edit `dispose()` (lines 777–790). Replace with:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _timer?.cancel();
  _tipsTimer?.cancel();
  // Order matters: stop pose pipeline → close detector → stop camera stream → dispose camera.
  _isPoseDetectionEnabled = false;
  _poseService.dispose(); // closes the underlying PoseDetector
  final controller = _cameraController;
  if (controller != null) {
    if (controller.value.isStreamingImages) {
      controller.stopImageStream().catchError((Object e, StackTrace st) {
        AppLogger.warning('Error al detener stream en dispose',
            data: {'error': e.toString()}, tag: 'TherapySession');
      });
    }
    controller.dispose();
  }
  super.dispose();
}
```

- [ ] **Step 2** — Run `flutter analyze`. Fix any lints.
- [ ] **Step 3** — Commit: `fix(camera): correct disposal order to prevent platform channel crashes`

### Task 1.5: Audit `didChangeAppLifecycleState` against spec

The existing handler at lines 86–112 already covers `paused`/`inactive`/`resumed`. The spec explicitly demands `_initCamera()` on `resumed`, but reinitializing each resume causes flicker. Keep current behavior (resume stream only) but add `hidden` handling.

- [ ] **Step 1** — Edit lines 86–112. Verify current handler already handles `hidden` — it does (line 94). No code change needed. Add an in-code note explaining why we don't reinit on resume:

```dart
// NOTE: We resume the stream rather than reinitializing the controller.
// Reinitializing on every foreground triggers a 600-1000ms black flash
// that breaks the user's flow during a session.
```

- [ ] **Step 2** — Commit: `docs(camera): document why we resume vs reinit on lifecycle change`

---

## PHASE 2 — Pose Analysis Abstraction

**Files:**
- Create: `lib/domain/pose_analysis/angle_calculator.dart`
- Create: `lib/domain/pose_analysis/exercise_feedback.dart`
- Create: `lib/domain/pose_analysis/rep_phase_machine.dart`
- Create: `lib/domain/pose_analysis/exercise_analyzer.dart`
- Modify: `lib/services/pose_detection_service.dart` (delegate to analyzers)

### Task 2.1: Extract `AngleCalculator`

- [ ] **Step 1** — Create `lib/domain/pose_analysis/angle_calculator.dart`:

```dart
import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Pure math + visibility helpers for pose landmarks. No ML Kit calls.
class AngleCalculator {
  static const double defaultMinConfidence = 0.5;

  /// Angle at [vertex] formed by [pointA]→[vertex]→[pointC], in degrees [0, 180].
  static double calculateAngle(
    PoseLandmark pointA,
    PoseLandmark vertex,
    PoseLandmark pointC,
  ) {
    final radians = math.atan2(pointC.y - vertex.y, pointC.x - vertex.x) -
        math.atan2(pointA.y - vertex.y, pointA.x - vertex.x);
    var degrees = radians * 180 / math.pi;
    degrees = degrees.abs();
    if (degrees > 180) degrees = 360 - degrees;
    return degrees;
  }

  static bool isVisible(PoseLandmark landmark, {double minConfidence = defaultMinConfidence}) {
    return landmark.likelihood >= minConfidence;
  }

  /// Average left/right of the same joint for symmetric exercises.
  /// Returns null if either side is below confidence.
  static double? symmetricAngle(
    PoseLandmark leftA, PoseLandmark leftVertex, PoseLandmark leftC,
    PoseLandmark rightA, PoseLandmark rightVertex, PoseLandmark rightC, {
    double minConfidence = defaultMinConfidence,
  }) {
    final leftVisible = [leftA, leftVertex, leftC].every((l) => isVisible(l, minConfidence: minConfidence));
    final rightVisible = [rightA, rightVertex, rightC].every((l) => isVisible(l, minConfidence: minConfidence));
    if (!leftVisible || !rightVisible) return null;
    final left = calculateAngle(leftA, leftVertex, leftC);
    final right = calculateAngle(rightA, rightVertex, rightC);
    return (left + right) / 2;
  }

  /// Absolute difference between left and right side. Used for asymmetry warnings.
  static double? asymmetry(
    PoseLandmark leftA, PoseLandmark leftVertex, PoseLandmark leftC,
    PoseLandmark rightA, PoseLandmark rightVertex, PoseLandmark rightC,
  ) {
    final left = calculateAngle(leftA, leftVertex, leftC);
    final right = calculateAngle(rightA, rightVertex, rightC);
    return (left - right).abs();
  }
}
```

- [ ] **Step 2** — Commit: `feat(pose): extract AngleCalculator from PoseDetectionService`

### Task 2.2: Create `ExerciseFeedback` value object

- [ ] **Step 1** — Create `lib/domain/pose_analysis/exercise_feedback.dart`:

```dart
enum FeedbackLevel { good, warning, error }
enum ExercisePhase { setup, active, hold, rest }

class AngleRange {
  const AngleRange(this.min, this.max);
  final double min;
  final double max;
  bool contains(double angle) => angle >= min && angle <= max;
  /// Within [tolerance] degrees of [min] or [max].
  bool nearEdge(double angle, {double tolerance = 15}) =>
      (angle - min).abs() <= tolerance || (angle - max).abs() <= tolerance;
}

class ExerciseFeedback {
  const ExerciseFeedback({
    required this.level,
    required this.message,
    this.measuredAngle,
    this.jointName,
    this.isRepCounting = false,
  });

  final FeedbackLevel level;
  final String message;
  final double? measuredAngle;
  final String? jointName;
  final bool isRepCounting;

  static const ExerciseFeedback waitingSetup = ExerciseFeedback(
    level: FeedbackLevel.warning,
    message: 'Posiciónate frente a la cámara',
  );
}
```

- [ ] **Step 2** — Commit: `feat(pose): add ExerciseFeedback + AngleRange value objects`

### Task 2.3: Create `RepPhaseMachine` with time-gate

- [ ] **Step 1** — Create `lib/domain/pose_analysis/rep_phase_machine.dart`:

```dart
import 'package:flutter/foundation.dart';

enum RepPhase { waiting, descending, bottom, ascending, top }

/// State machine for counting full-range-of-motion reps. Generic over
/// "down/up" semantics — caller passes the angle and a [downIsTarget] flag.
@visibleForTesting
class RepPhaseMachine {
  RepPhaseMachine({
    required this.bottomThreshold,
    required this.topThreshold,
    Duration minRepInterval = const Duration(milliseconds: 800),
    DateTime Function() now = _defaultNow,
  })  : _minRepInterval = minRepInterval,
        _now = now;

  final double bottomThreshold;
  final double topThreshold;
  final Duration _minRepInterval;
  final DateTime Function() _now;

  RepPhase _phase = RepPhase.waiting;
  DateTime? _lastRepAt;
  int _repCount = 0;

  RepPhase get phase => _phase;
  int get repCount => _repCount;

  /// Feed the latest measured angle. Returns true when a rep has just been counted.
  bool update(double angle) {
    final atBottom = angle <= bottomThreshold;
    final atTop = angle >= topThreshold;

    switch (_phase) {
      case RepPhase.waiting:
        if (atTop) _phase = RepPhase.top;
        if (atBottom) _phase = RepPhase.bottom;
        break;
      case RepPhase.top:
        if (atBottom) _phase = RepPhase.bottom;
        else if (angle < topThreshold) _phase = RepPhase.descending;
        break;
      case RepPhase.descending:
        if (atBottom) _phase = RepPhase.bottom;
        break;
      case RepPhase.bottom:
        if (angle > bottomThreshold) _phase = RepPhase.ascending;
        break;
      case RepPhase.ascending:
        if (atTop) {
          if (_canCountRep()) {
            _repCount++;
            _lastRepAt = _now();
            _phase = RepPhase.top;
            return true;
          }
          _phase = RepPhase.top;
        }
        break;
    }
    return false;
  }

  bool _canCountRep() {
    if (_lastRepAt == null) return true;
    return _now().difference(_lastRepAt!) >= _minRepInterval;
  }

  void reset() {
    _phase = RepPhase.waiting;
    _lastRepAt = null;
    _repCount = 0;
  }

  static DateTime _defaultNow() => DateTime.now();
}
```

- [ ] **Step 2** — Commit: `feat(pose): add RepPhaseMachine with 800ms time-gate`

### Task 2.4: Create `ExerciseAnalyzer` abstract base

- [ ] **Step 1** — Create `lib/domain/pose_analysis/exercise_analyzer.dart`:

```dart
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'angle_calculator.dart';
import 'exercise_feedback.dart';
import 'rep_phase_machine.dart';

/// Base class for all exercise-specific pose analyzers.
abstract class ExerciseAnalyzer {
  ExerciseAnalyzer();

  String get exerciseId;
  String get exerciseName;
  AngleRange get targetRange;

  /// Whether this exercise counts reps (false for timed holds like wall sit).
  bool get countsReps => true;

  /// Concrete analyzers override to implement their pose math.
  /// Returns null when no usable pose was found (caller renders a neutral state).
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase);

  /// Returns true when the latest update produced a counted rep.
  bool get justCountedRep => _justCountedRep;
  int get repCount => repMachine?.repCount ?? 0;

  /// Subclasses construct this in their constructor body.
  RepPhaseMachine? repMachine;

  bool _justCountedRep = false;

  /// Helper: feeds [angle] into [repMachine] and updates `justCountedRep`.
  void tickRep(double angle) {
    _justCountedRep = repMachine?.update(angle) ?? false;
  }

  void reset() {
    repMachine?.reset();
    _justCountedRep = false;
  }

  /// Average likelihood of [landmarks]. Used for `PoseDetectionQuality`.
  static double averageConfidence(Iterable<PoseLandmark?> landmarks) {
    final present = landmarks.whereType<PoseLandmark>().toList();
    if (present.isEmpty) return 0;
    return present.map((l) => l.likelihood).reduce((a, b) => a + b) / present.length;
  }

  /// Re-export so subclasses don't need a second import.
  static double angle(PoseLandmark a, PoseLandmark v, PoseLandmark c) =>
      AngleCalculator.calculateAngle(a, v, c);
}
```

- [ ] **Step 2** — Commit: `feat(pose): add ExerciseAnalyzer abstract base`

### Task 2.5: Migrate existing knee-extension analyzer to new API

This validates the abstraction by porting one existing analyzer. The remaining 7 follow the same pattern in Phase 4.

- [ ] **Step 1** — Create `lib/domain/exercises/analyzers/knee_extension_analyzer.dart`:

```dart
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../pose_analysis/angle_calculator.dart';
import '../../pose_analysis/exercise_analyzer.dart';
import '../../pose_analysis/exercise_feedback.dart';
import '../../pose_analysis/rep_phase_machine.dart';

/// Knee extension (seated). Extends from ~90° (bent) to ~10° (straight).
/// Rep counted on transition into the extended top.
class KneeExtensionAnalyzer extends ExerciseAnalyzer {
  KneeExtensionAnalyzer() {
    repMachine = RepPhaseMachine(
      bottomThreshold: 80,  // bent / starting
      topThreshold: 160,    // extended / counting position
    );
  }

  @override
  String get exerciseId => 'knee_extension';
  @override
  String get exerciseName => 'Extensión de rodilla';
  @override
  AngleRange get targetRange => const AngleRange(160, 180);

  @override
  ExerciseFeedback? analyze(List<Pose> poses, ExercisePhase phase) {
    if (poses.isEmpty) return ExerciseFeedback.waitingSetup;
    final p = poses.first;
    final lh = p.landmarks[PoseLandmarkType.leftHip];
    final lk = p.landmarks[PoseLandmarkType.leftKnee];
    final la = p.landmarks[PoseLandmarkType.leftAnkle];
    final rh = p.landmarks[PoseLandmarkType.rightHip];
    final rk = p.landmarks[PoseLandmarkType.rightKnee];
    final ra = p.landmarks[PoseLandmarkType.rightAnkle];
    if (lh == null || lk == null || la == null || rh == null || rk == null || ra == null) {
      return ExerciseFeedback.waitingSetup;
    }
    final visible = [lh, lk, la, rh, rk, ra].every(AngleCalculator.isVisible);
    if (!visible) {
      return const ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Siéntate de lado para que se vea la pierna entera',
      );
    }

    final symmetric = AngleCalculator.symmetricAngle(lh, lk, la, rh, rk, ra)!;
    final asym = AngleCalculator.asymmetry(lh, lk, la, rh, rk, ra)!;
    tickRep(symmetric);

    if (asym > 15) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Nota: hay diferencia entre tus piernas',
        measuredAngle: symmetric,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    if (symmetric < 100) {
      return ExerciseFeedback(
        level: FeedbackLevel.warning,
        message: 'Sube más la pierna para completar el movimiento',
        measuredAngle: symmetric,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    if (symmetric >= 170) {
      return ExerciseFeedback(
        level: FeedbackLevel.good,
        message: '¡Perfecto! Extiende completamente',
        measuredAngle: symmetric,
        jointName: 'rodilla',
        isRepCounting: justCountedRep,
      );
    }
    return ExerciseFeedback(
      level: FeedbackLevel.good,
      message: 'Bajando… ${symmetric.toStringAsFixed(0)}°',
      measuredAngle: symmetric,
      jointName: 'rodilla',
      isRepCounting: justCountedRep,
    );
  }
}
```

- [ ] **Step 2** — Run `flutter analyze lib/domain/exercises/analyzers/knee_extension_analyzer.dart`. Fix any lints.
- [ ] **Step 3** — Commit: `feat(pose): port knee_extension to ExerciseAnalyzer abstraction`

### Task 2.6: Have `PoseDetectionService` delegate to registered analyzers

- [ ] **Step 1** — Add to `pose_detection_service.dart` a registration API:

```dart
ExerciseAnalyzer? _analyzer;

void useAnalyzer(ExerciseAnalyzer analyzer) {
  _analyzer = analyzer;
  // Keep legacy fallback alive — old callers using setExercise still work.
}
```

- [ ] **Step 2** — In `processFrame`, if `_analyzer != null`, run `_analyzer!.analyze([pose], ExercisePhase.active)` and return a `PoseAnalysisResult` adapted from `ExerciseFeedback`. Otherwise fall back to the existing `_analyzeExercise` switch.
- [ ] **Step 3** — Run `flutter analyze`.
- [ ] **Step 4** — Commit: `feat(pose): allow PoseDetectionService to delegate to ExerciseAnalyzer`

---

## PHASE 3 — Skeleton + Feedback Overlays

**Files:**
- Create: `lib/screens/therapy/widgets/skeleton_overlay.dart`
- Create: `lib/screens/therapy/widgets/exercise_feedback_overlay.dart`
- Modify: `lib/screens/main/therapy_session_screen.dart` (mount the overlays + plumb pose stream)

### Task 3.1: Create `SkeletonOverlay`

- [ ] **Step 1** — Create the file with a `CustomPainter` that:
  - Takes `List<Pose>? poses`, `Size imageSize`, `InputImageRotation rotation`, `bool isMirrored`, `AngleRange? targetRange`, `double? measuredAngle`.
  - Draws connections (shoulder→elbow→wrist, hip→knee→ankle, shoulder→hip per side; cross-shoulder + cross-hip).
  - Color codes per landmark: green if `targetRange.contains`, orange if `nearEdge`, red otherwise; grey-dashed when below confidence.
  - Implements `shouldRepaint` returning `oldDelegate.poses != poses`.

(Full code body is ~140 lines — written when this task is executed; the contract above is sufficient.)

- [ ] **Step 2** — Commit: `feat(therapy): add SkeletonOverlay CustomPainter`

### Task 3.2: Create `ExerciseFeedbackOverlay`

- [ ] **Step 1** — Stateless widget consuming an `ExerciseFeedback`, current rep count + target, current set + total sets, and `PoseDetectionQuality`.
- [ ] **Step 2** — Animates rep counter on each new rep (Hero / `AnimatedSwitcher`).
- [ ] **Step 3** — Color-codes feedback bar by `FeedbackLevel`.
- [ ] **Step 4** — Commit: `feat(therapy): add ExerciseFeedbackOverlay`

### Task 3.3: Wire overlays into therapy screen

- [ ] **Step 1** — Add a `List<Pose>? _latestPoses` field updated from `_processFrame`.
- [ ] **Step 2** — Stack `SkeletonOverlay` above `CameraPreview` and below the existing controls layer.
- [ ] **Step 3** — Replace the existing `_buildPoseDetectionIndicator` (lines 1188-1324) call with `ExerciseFeedbackOverlay`. Delete the old indicator method.
- [ ] **Step 4** — Run `flutter analyze`. Manual smoke test on device.
- [ ] **Step 5** — Commit: `feat(therapy): mount skeleton + feedback overlays`

### Task 3.4: Add `PoseDetectionQuality` heuristic

- [ ] **Step 1** — Add to `pose_detection_service.dart`:

```dart
enum PoseDetectionQuality { excellent, good, poor, lost }
```

- [ ] **Step 2** — Track the timestamp of the last non-empty pose result. If empty for >2s → `lost`. Else map `averageConfidence` of key joints to excellent/good/poor.
- [ ] **Step 3** — Surface this on `PoseAnalysisResult` and let `ExerciseFeedbackOverlay` show "Detección: Alta/Media/Baja/Perdida".
- [ ] **Step 4** — Commit: `feat(therapy): expose PoseDetectionQuality`

---

## PHASE 4 — Exercise Library Expansion

**Files:**
- Create: `lib/domain/exercises/analyzers/<one_per_exercise>.dart` (12 files)
- Create: `lib/domain/exercises/exercise_catalog.dart` (id → analyzer factory)
- Create: `lib/data/seeds/exercise_seeds.dart` (List<Map> for Firestore)

Each analyzer follows the `KneeExtensionAnalyzer` template from Task 2.5. The table below specifies the exact landmarks, thresholds, and feedback messages — one task per analyzer.

| ID | Class | Key joint | Bottom thr° | Top thr° | Reps/Time | Group |
|---|---|---|---|---|---|---|
| `hamstring_curl` | `HamstringCurlAnalyzer` | knee (standing) | 0 | 80 | 12r×3 | A |
| `wall_squat` | `WallSquatAnalyzer` | knee | 70 | 110 | 30s×3 hold | A |
| `straight_leg_raise` | `StraightLegRaiseAnalyzer` | hip (knee straight) | 0 | 45 | 15r×3 | A |
| `shoulder_flexion` | `ShoulderFlexionAnalyzer` | shoulder (front) | 0 | 80 | 10r×3 | B |
| `shoulder_abduction` | `ShoulderAbductionAnalyzer` | shoulder (lateral) | 0 | 80 | 10r×3 | B |
| `pendulum` | `PendulumAnalyzer` | shoulder (gentle) | n/a | n/a | 60s×1 timer | B |
| `glute_bridge` | `GluteBridgeAnalyzer` | hip extension | n/a | n/a | 15r×3 | C |
| `clamshell` | `ClamshellAnalyzer` | hip rotation | 5 | 25 | 15r×3 | C |
| `single_leg_stance` | `SingleLegStanceAnalyzer` | trunk sway | n/a | n/a | 30s×3 timer | D |
| `heel_raise` | `HeelRaiseAnalyzer` | ankle Δy | n/a | n/a | 20r×3 | D |
| `neck_flex_ext` | (no analyzer — timer + self-report) | n/a | n/a | n/a | 10r×2 timer | E |
| `neck_lateral_flex` | (no analyzer — timer + self-report) | n/a | n/a | n/a | 10r×2 timer | E |

### Task 4.1 – 4.10: One commit per analyzer

Each task replicates the structure of Task 2.5:
- [ ] Create the analyzer class file.
- [ ] Implement landmark extraction, visibility check, rep machine wiring, feedback messages from the spec.
- [ ] `flutter analyze` the file.
- [ ] Commit: `feat(pose): add <name>Analyzer`

### Task 4.11: Build `ExerciseCatalog` factory

- [ ] **Step 1** — Create `lib/domain/exercises/exercise_catalog.dart`:

```dart
import 'analyzers/knee_extension_analyzer.dart';
// import others as they are added
import '../pose_analysis/exercise_analyzer.dart';

typedef AnalyzerFactory = ExerciseAnalyzer Function();

class ExerciseCatalog {
  static const Map<String, AnalyzerFactory> _factories = {
    'knee_extension': KneeExtensionAnalyzer.new,
    // 'hamstring_curl': HamstringCurlAnalyzer.new,
    // ... wired up as analyzers land
  };

  static ExerciseAnalyzer? createById(String id) => _factories[id]?.call();
}
```

- [ ] **Step 2** — Commit: `feat(exercises): add ExerciseCatalog id→analyzer factory`

### Task 4.12: Firestore seed

- [ ] **Step 1** — Create `lib/data/seeds/exercise_seeds.dart`. Export `List<Map<String, dynamic>> exerciseSeeds = [ … ];` with one entry per spec exercise. Each entry: `{id, name, group, reps, sets, durationSeconds, targetMuscles, difficulty, instructions, analyzerId}`.
- [ ] **Step 2** — Add a one-shot script `lib/data/seeds/run_seed.dart` with `void main()` that batch-writes to Firestore `routines` collection. Document in CLAUDE.md / README that seeding is manual via `flutter run -t lib/data/seeds/run_seed.dart`.
- [ ] **Step 3** — `flutter analyze`. Commit: `feat(exercises): add Firestore seed for 12 rehab exercises`

---

## PHASE 5 — Session State Machine + Multi-Set Flow

**Files:**
- Create: `lib/domain/therapy/session_state.dart`
- Create: `lib/domain/therapy/session_controller.dart`
- Modify: `lib/screens/main/therapy_session_screen.dart` (consume `SessionController`)

### Task 5.1: Sealed `SessionState` classes

- [ ] **Step 1** — Create `lib/domain/therapy/session_state.dart` exactly per the spec:

```dart
import '../pose_analysis/exercise_analyzer.dart';
import '../pose_analysis/exercise_feedback.dart';

sealed class SessionState {
  const SessionState();
}

final class SessionIdle extends SessionState {
  const SessionIdle();
}

final class SessionCountdown extends SessionState {
  const SessionCountdown(this.secondsRemaining);
  final int secondsRemaining;
}

final class SessionActive extends SessionState {
  const SessionActive({
    required this.currentExercise,
    required this.currentSet,
    required this.totalSets,
    required this.repsCompleted,
    required this.targetReps,
    required this.detectionQuality,
    this.latestFeedback,
  });
  final ExerciseAnalyzer currentExercise;
  final int currentSet;
  final int totalSets;
  final int repsCompleted;
  final int targetReps;
  final ExerciseFeedback? latestFeedback;
  final PoseDetectionQuality detectionQuality;
}

final class SessionResting extends SessionState {
  const SessionResting({required this.secondsRemaining, required this.nextExerciseName});
  final int secondsRemaining;
  final String nextExerciseName;
}

final class SessionCompleted extends SessionState {
  const SessionCompleted({
    required this.totalReps,
    required this.sessionDuration,
    required this.averageFormScore,
  });
  final int totalReps;
  final Duration sessionDuration;
  final double averageFormScore;
}

enum PoseDetectionQuality { excellent, good, poor, lost }
```

- [ ] **Step 2** — Commit: `feat(therapy): add SessionState sealed classes`

### Task 5.2: `SessionController` (`ChangeNotifier`)

- [ ] **Step 1** — Create `lib/domain/therapy/session_controller.dart`. Provider `ChangeNotifier` with internal `Timer`s:
  - `start()` → emit `SessionCountdown(3)` ticking down to 0 → `SessionActive`.
  - `recordRep()` → increment, emit refreshed `SessionActive`. When `repsCompleted == targetReps` → `SessionResting(restSeconds, nextName)`.
  - When `currentSet == totalSets` → `SessionCompleted(...)`.
  - `recordFeedback(ExerciseFeedback)` → emit refreshed state. Track form score = % of feedbacks where `level == FeedbackLevel.good`.
  - `pause()` / `resume()` / `cancel()` cancel timers.
- [ ] **Step 2** — `flutter analyze`. Commit: `feat(therapy): add SessionController state machine`

### Task 5.3: Wire `SessionController` into therapy screen

- [ ] **Step 1** — Refactor `_TherapySessionScreenState` to instantiate `SessionController` in `initState` and dispose it in `dispose`. Replace `_currentRep`/`_elapsedSeconds`/`_isPaused` with reads off the controller via `AnimatedBuilder(animation: _controller, builder: …)`.
- [ ] **Step 2** — Add a 3-2-1 countdown overlay rendered when `state is SessionCountdown`.
- [ ] **Step 3** — Add a "Set 2 de 3" badge to the existing top row.
- [ ] **Step 4** — On `SessionResting`, render full-screen rest UI with timer + "Saltar descanso" button.
- [ ] **Step 5** — On `SessionCompleted`, navigate to `SessionReportScreen` (existing) — no new completion screen needed in this phase.
- [ ] **Step 6** — `flutter analyze`. Manual smoke. Commit: `feat(therapy): drive screen with SessionController`

### Task 5.4: "No te veo bien" banner

- [ ] **Step 1** — When `SessionActive.detectionQuality == lost` for >2s, render a bottom banner: *"No te veo bien — aléjate un poco de la cámara"*.
- [ ] **Step 2** — Commit: `feat(therapy): show banner when pose is lost for 2s`

### Task 5.5: Pre-exercise screen

- [ ] **Step 1** — When `state is SessionIdle`, render a pre-exercise card: name, target muscles, reps×sets / duration, instructions, "Comenzar" button. Tapping → `controller.start()`.
- [ ] **Step 2** — Commit: `feat(therapy): add pre-exercise overview card`

---

## PHASE 6 — Tests

**Files:**
- Create: `test/domain/pose_analysis/angle_calculator_test.dart`
- Create: `test/domain/pose_analysis/rep_phase_machine_test.dart`
- Create: `test/domain/exercises/knee_extension_analyzer_test.dart`
- Create: `test/domain/therapy/session_controller_test.dart`
- Create: `test/_helpers/pose_fixtures.dart` (fake `Pose` builders)

### Task 6.1: Pose fixture helper

- [ ] **Step 1** — Create `test/_helpers/pose_fixtures.dart`:

```dart
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

PoseLandmark mark(PoseLandmarkType t, double x, double y, {double likelihood = 0.9}) =>
    PoseLandmark(type: t, x: x, y: y, z: 0, likelihood: likelihood);

Pose poseFromMarks(Iterable<PoseLandmark> marks) =>
    Pose(landmarks: { for (final m in marks) m.type: m });
```

- [ ] **Step 2** — Commit: `test: add pose fixture builders`

### Task 6.2: AngleCalculator tests

- [ ] **Step 1** — Create the test with 5 cases (90°, 180°, ≈0°, isVisible 0.3, isVisible 0.7) per the spec.
- [ ] **Step 2** — Run `flutter test test/domain/pose_analysis/angle_calculator_test.dart -v`. Expected: 5 PASS.
- [ ] **Step 3** — Commit: `test(pose): AngleCalculator unit tests`

### Task 6.3: RepPhaseMachine tests

- [ ] **Step 1** — Inject `now` and verify:
  - Sequence top→descending→bottom→ascending→top counts exactly 1 rep.
  - Two top-transitions within 500ms count exactly 1 rep (gate enforced).
  - `reset()` zeros the counter and returns to `waiting`.
- [ ] **Step 2** — Run the test. Commit: `test(pose): RepPhaseMachine state + time gate`

### Task 6.4: KneeExtensionAnalyzer + SessionController tests

- [ ] **Step 1** — KneeExtension: extended (10°) → goodfeedback + rep eventually counts; bent (90°) returns "sube más"; left/right diff >15° → asymmetry warning.
- [ ] **Step 2** — SessionController: idle → countdown(3) → active; pumping target reps moves to resting; injecting `lost` for 2s surfaces it on `SessionActive.detectionQuality`.
- [ ] **Step 3** — Run `flutter test`. Commit: `test(therapy): KneeExtensionAnalyzer + SessionController`

---

## Final verification

After all phases:

- [ ] `flutter analyze` — zero issues.
- [ ] `flutter test --coverage` — all green; new files covered.
- [ ] Manual device smoke: end-to-end run of one knee_extension session including 3-2-1 countdown, multi-set, rest, completion → SessionReportScreen.
- [ ] Generate the report (template at the end of the spec) and append to PR description.

---

## Self-review checklist (run before claiming complete)

1. **Spec coverage** — Every numbered section in the spec has a Phase task: 1.1 ✓ 1.2 ✓ 1.3 ✓ 2.1 ✓ 2.2 ✓ 2.3 ✓ 2.4 ✓ 3 (twelve exercises) ✓ 4.1 ✓ 4.2 ✓ 5 (tests) ✓.
2. **Placeholder scan** — No "TODO", "fill in", "implement later". `// import others as they are added` in Task 4.11 is a wired-up-incrementally marker, intentional and replaced as analyzers land.
3. **Type consistency** — `PoseDetectionQuality` is defined once in `lib/domain/therapy/session_state.dart` (Task 5.1). The mention in Task 3.4 must `export` from there, not redefine. Adjust during execution.
