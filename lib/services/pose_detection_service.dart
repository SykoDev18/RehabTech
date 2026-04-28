import 'dart:math' as math;
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../core/utils/logger.dart';
import '../domain/pose_analysis/exercise_analyzer.dart' as ea;
import '../domain/pose_analysis/exercise_feedback.dart' as ef;
import '../domain/pose_analysis/pose_detection_quality.dart';

/// Tipos de ejercicio soportados con detección de poses
enum ExerciseType {
  squat,           // Sentadilla
  bicepCurl,       // Curl de bíceps
  shoulderPress,   // Press de hombros
  lunge,           // Zancada
  kneeExtension,   // Extensión de rodilla
  legRaise,        // Elevación de pierna
  armRaise,        // Elevación de brazo
  hipFlexion,      // Flexión de cadera
  generic,         // Ejercicio genérico
}

/// Estado de una repetición
enum RepState {
  initial,    // Posición inicial
  inProgress, // En movimiento
  completed,  // Repetición completada
}

/// Resultado del análisis de pose
class PoseAnalysisResult {
  final bool isCorrectForm;
  final double primaryAngle;
  final double? secondaryAngle;
  final RepState repState;
  final String feedback;
  final List<String> corrections;
  final double confidence;
  final PoseDetectionQuality quality;
  final List<Pose> poses;

  PoseAnalysisResult({
    required this.isCorrectForm,
    required this.primaryAngle,
    this.secondaryAngle,
    required this.repState,
    required this.feedback,
    this.corrections = const [],
    this.confidence = 0.0,
    this.quality = PoseDetectionQuality.poor,
    this.poses = const [],
  });
}

/// Servicio para detección de poses y validación de ejercicios
class PoseDetectionService {
  PoseDetector? _poseDetector;
  ExerciseType _currentExercise = ExerciseType.generic;

  // Estado de la máquina de estados para conteo
  // ignore: unused_field
  bool _wasInStartPosition = true;
  bool _wasInEndPosition = false;
  int _repCount = 0;

  // Umbrales configurables por ejercicio
  late double _startAngleThreshold;
  late double _endAngleThreshold;

  // Optional new-style analyzer. When non-null, processFrame delegates to it
  // instead of running the legacy switch.
  ea.ExerciseAnalyzer? _analyzer;
  DateTime? _lastSuccessfulFrameAt;
  static const Duration _lostThreshold = Duration(seconds: 2);

  // Callback para notificar cambios
  Function(int repCount)? onRepCompleted;
  Function(String feedback)? onFeedback;
  Function(PoseAnalysisResult result)? onPoseAnalyzed;

  /// Inicializa el detector de poses
  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
  }

  /// Registers a new-style [ExerciseAnalyzer]. When non-null, [processFrame]
  /// delegates analysis to it. Pass null to fall back to the legacy switch.
  void useAnalyzer(ea.ExerciseAnalyzer? analyzer) {
    _analyzer = analyzer;
    _repCount = 0;
    _wasInStartPosition = true;
    _wasInEndPosition = false;
    _lastSuccessfulFrameAt = null;
  }

  /// Configura el ejercicio actual
  void setExercise(ExerciseType type) {
    _currentExercise = type;
    _repCount = 0;
    _wasInStartPosition = true;
    _wasInEndPosition = false;
    
    // Configurar umbrales según el ejercicio
    switch (type) {
      case ExerciseType.squat:
        _startAngleThreshold = 160; // Piernas casi rectas
        _endAngleThreshold = 90;    // Rodilla doblada (paralelo)
        break;
      case ExerciseType.bicepCurl:
        _startAngleThreshold = 160; // Brazo extendido
        _endAngleThreshold = 45;    // Brazo contraído
        break;
      case ExerciseType.shoulderPress:
        _startAngleThreshold = 90;  // Codos a 90°
        _endAngleThreshold = 170;   // Brazos extendidos arriba
        break;
      case ExerciseType.kneeExtension:
        _startAngleThreshold = 90;  // Rodilla doblada
        _endAngleThreshold = 160;   // Pierna extendida
        break;
      case ExerciseType.legRaise:
        _startAngleThreshold = 170; // Pierna abajo
        _endAngleThreshold = 90;    // Pierna levantada
        break;
      case ExerciseType.armRaise:
        _startAngleThreshold = 20;  // Brazo abajo
        _endAngleThreshold = 160;   // Brazo arriba
        break;
      case ExerciseType.lunge:
        _startAngleThreshold = 160;
        _endAngleThreshold = 90;
        break;
      case ExerciseType.hipFlexion:
        _startAngleThreshold = 170;
        _endAngleThreshold = 90;
        break;
      case ExerciseType.generic:
        _startAngleThreshold = 160;
        _endAngleThreshold = 90;
        break;
    }
  }

  /// Procesa un frame de la cámara
  Future<PoseAnalysisResult?> processFrame(CameraImage image, CameraDescription camera) async {
    if (_poseDetector == null) return null;

    try {
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage == null) return null;

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) {
        final lost = _isLostNow();
        return PoseAnalysisResult(
          isCorrectForm: false,
          primaryAngle: 0,
          repState: RepState.initial,
          feedback: 'No se detecta pose. Asegúrate de estar visible en la cámara.',
          confidence: 0,
          quality: lost ? PoseDetectionQuality.lost : PoseDetectionQuality.poor,
          poses: const [],
        );
      }

      _lastSuccessfulFrameAt = DateTime.now();

      // Prefer new-style analyzer when registered.
      if (_analyzer != null) {
        return _runAnalyzer(_analyzer!, poses);
      }

      // Legacy path
      final pose = poses.first;
      final result = _analyzeExercise(pose);
      return PoseAnalysisResult(
        isCorrectForm: result.isCorrectForm,
        primaryAngle: result.primaryAngle,
        secondaryAngle: result.secondaryAngle,
        repState: result.repState,
        feedback: result.feedback,
        corrections: result.corrections,
        confidence: result.confidence,
        quality: PoseDetectionQualityX.fromConfidence(result.confidence),
        poses: poses,
      );
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'PlatformException procesando frame de pose',
        error: e,
        stackTrace: st,
        tag: 'PoseDetection',
      );
      return null;
    } catch (e, st) {
      AppLogger.error(
        'Error procesando frame de pose',
        error: e,
        stackTrace: st,
        tag: 'PoseDetection',
      );
      return null;
    }
  }

  bool _isLostNow() {
    final last = _lastSuccessfulFrameAt;
    if (last == null) return false;
    return DateTime.now().difference(last) > _lostThreshold;
  }

  /// Runs the registered new-style analyzer and adapts its result into
  /// a [PoseAnalysisResult] for legacy callers. Side-effect: invokes
  /// [onRepCompleted] / [onFeedback] when the analyzer counts a rep.
  PoseAnalysisResult _runAnalyzer(ea.ExerciseAnalyzer analyzer, List<Pose> poses) {
    final fb = analyzer.analyze(poses, ef.ExercisePhase.active);
    final pose = poses.first;
    final keyJoints = <PoseLandmark?>[
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.rightShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.rightHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.rightKnee],
    ];
    final present = keyJoints.whereType<PoseLandmark>().toList();
    final avg = present.isEmpty
        ? 0.0
        : present.map((l) => l.likelihood).reduce((a, b) => a + b) / present.length;

    if (analyzer.justCountedRep) {
      _repCount = analyzer.repCount;
      onRepCompleted?.call(_repCount);
      onFeedback?.call('¡Repetición $_repCount completada! 💪');
    }

    final corrections = <String>[];
    if (fb != null && fb.level != ef.FeedbackLevel.good) {
      corrections.add(fb.message);
    }

    return PoseAnalysisResult(
      isCorrectForm: fb?.level == ef.FeedbackLevel.good,
      primaryAngle: fb?.measuredAngle ?? 0,
      repState: analyzer.justCountedRep ? RepState.completed : RepState.inProgress,
      feedback: fb?.message ?? 'Detección activa.',
      corrections: corrections,
      confidence: avg,
      quality: PoseDetectionQualityX.fromConfidence(avg),
      poses: poses,
    );
  }

  /// Convierte CameraImage a InputImage para ML Kit
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    
    final rotation = _getImageRotation(camera);
    if (rotation == null) return null;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _getImageRotation(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Analiza el ejercicio según el tipo configurado
  PoseAnalysisResult _analyzeExercise(Pose pose) {
    switch (_currentExercise) {
      case ExerciseType.squat:
        return _analyzeSquat(pose);
      case ExerciseType.bicepCurl:
        return _analyzeBicepCurl(pose);
      case ExerciseType.shoulderPress:
        return _analyzeShoulderPress(pose);
      case ExerciseType.kneeExtension:
        return _analyzeKneeExtension(pose);
      case ExerciseType.legRaise:
        return _analyzeLegRaise(pose);
      case ExerciseType.armRaise:
        return _analyzeArmRaise(pose);
      case ExerciseType.lunge:
        return _analyzeLunge(pose);
      case ExerciseType.hipFlexion:
        return _analyzeHipFlexion(pose);
      case ExerciseType.generic:
        return _analyzeGeneric(pose);
    }
  }

  /// ANÁLISIS DE SENTADILLA (Squat)
  PoseAnalysisResult _analyzeSquat(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    // Verificar detección
    if (!_checkLandmarksValid([leftHip, leftKnee, leftAnkle, rightHip, rightKnee, rightAnkle])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Ponte de lado para mejor detección',
        confidence: 0,
      );
    }

    // Calcular ángulos de ambas rodillas
    final leftKneeAngle = calculateAngle(leftHip!, leftKnee!, leftAnkle!);
    final rightKneeAngle = calculateAngle(rightHip!, rightKnee!, rightAnkle!);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Calcular confianza promedio
    final confidence = _avgConfidence([leftHip, leftKnee, leftAnkle, rightHip, rightKnee, rightAnkle]);

    // Detectar errores de forma
    final corrections = <String>[];
    
    // Verificar si las rodillas van muy adelante
    if (leftKnee.x - leftAnkle.x > 50 || rightKnee.x - rightAnkle.x > 50) {
      corrections.add('Evita que las rodillas pasen los dedos del pie');
    }

    // Verificar espalda recta (si tenemos hombro)
    if (leftShoulder != null && leftHip.likelihood > 0.5 && leftShoulder.likelihood > 0.5) {
      final backAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
      if (backAngle < 160) {
        corrections.add('Mantén la espalda más recta');
      }
    }

    // Lógica de conteo con máquina de estados
    final result = _updateRepCounter(avgKneeAngle, true); // true = menor ángulo es el objetivo
    
    String feedback;
    if (avgKneeAngle > _startAngleThreshold) {
      feedback = '¡Arriba! Posición inicial. Ángulo: ${avgKneeAngle.toStringAsFixed(0)}°';
    } else if (avgKneeAngle < _endAngleThreshold) {
      feedback = '¡Excelente profundidad! ${avgKneeAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Bajando... ${avgKneeAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: corrections.isEmpty,
      primaryAngle: avgKneeAngle,
      repState: result,
      feedback: feedback,
      corrections: corrections,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE CURL DE BÍCEPS
  PoseAnalysisResult _analyzeBicepCurl(Pose pose) {
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    // Usar el lado con mejor detección
    double elbowAngle = 0;
    double confidence = 0;

    if (_checkLandmarksValid([rightShoulder, rightElbow, rightWrist])) {
      elbowAngle = calculateAngle(rightShoulder!, rightElbow!, rightWrist!);
      confidence = _avgConfidence([rightShoulder, rightElbow, rightWrist]);
    } else if (_checkLandmarksValid([leftShoulder, leftElbow, leftWrist])) {
      elbowAngle = calculateAngle(leftShoulder!, leftElbow!, leftWrist!);
      confidence = _avgConfidence([leftShoulder, leftElbow, leftWrist]);
    } else {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Muestra tu brazo completo a la cámara',
        confidence: 0,
      );
    }

    final corrections = <String>[];
    
    // Verificar que el codo no se mueva mucho
    if (rightShoulder != null && rightElbow != null) {
      if ((rightShoulder.x - rightElbow.x).abs() > 80) {
        corrections.add('Mantén el codo pegado al cuerpo');
      }
    }

    final result = _updateRepCounter(elbowAngle, true);

    String feedback;
    if (elbowAngle > _startAngleThreshold) {
      feedback = 'Brazo extendido. Ángulo: ${elbowAngle.toStringAsFixed(0)}°';
    } else if (elbowAngle < _endAngleThreshold) {
      feedback = '¡Contracción máxima! ${elbowAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Subiendo... ${elbowAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: corrections.isEmpty,
      primaryAngle: elbowAngle,
      repState: result,
      feedback: feedback,
      corrections: corrections,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE PRESS DE HOMBROS
  PoseAnalysisResult _analyzeShoulderPress(Pose pose) {
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (!_checkLandmarksValid([rightShoulder, rightElbow, rightWrist])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Muestra tu brazo completo',
        confidence: 0,
      );
    }

    final elbowAngle = calculateAngle(rightShoulder!, rightElbow!, rightWrist!);
    final confidence = _avgConfidence([rightShoulder, rightElbow, rightWrist]);
    
    final result = _updateRepCounter(elbowAngle, false); // false = mayor ángulo es objetivo

    String feedback;
    if (elbowAngle < _startAngleThreshold) {
      feedback = 'Posición inicial: codos a 90°';
    } else if (elbowAngle > _endAngleThreshold) {
      feedback = '¡Brazos extendidos! ${elbowAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Subiendo... ${elbowAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: true,
      primaryAngle: elbowAngle,
      repState: result,
      feedback: feedback,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE EXTENSIÓN DE RODILLA (Rehabilitación)
  PoseAnalysisResult _analyzeKneeExtension(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (!_checkLandmarksValid([hip, knee, ankle])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Siéntate y muestra tu pierna derecha',
        confidence: 0,
      );
    }

    final kneeAngle = calculateAngle(hip!, knee!, ankle!);
    final confidence = _avgConfidence([hip, knee, ankle]);
    
    final result = _updateRepCounter(kneeAngle, false); // Mayor ángulo = pierna extendida

    String feedback;
    if (kneeAngle < _startAngleThreshold) {
      feedback = 'Rodilla doblada. Ángulo: ${kneeAngle.toStringAsFixed(0)}°';
    } else if (kneeAngle > _endAngleThreshold) {
      feedback = '¡Pierna extendida! ${kneeAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Extendiendo... ${kneeAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: true,
      primaryAngle: kneeAngle,
      repState: result,
      feedback: feedback,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE ELEVACIÓN DE PIERNA
  PoseAnalysisResult _analyzeLegRaise(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (!_checkLandmarksValid([hip, knee, shoulder])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Acuéstate y muestra tu cuerpo completo',
        confidence: 0,
      );
    }

    final legAngle = calculateAngle(shoulder!, hip!, knee!);
    final confidence = _avgConfidence([hip, knee, shoulder]);
    
    final result = _updateRepCounter(legAngle, true);

    String feedback;
    if (legAngle > _startAngleThreshold) {
      feedback = 'Pierna abajo. Ángulo: ${legAngle.toStringAsFixed(0)}°';
    } else if (legAngle < _endAngleThreshold) {
      feedback = '¡Pierna arriba! ${legAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Elevando... ${legAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: true,
      primaryAngle: legAngle,
      repState: result,
      feedback: feedback,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE ELEVACIÓN DE BRAZO
  PoseAnalysisResult _analyzeArmRaise(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];

    if (!_checkLandmarksValid([shoulder, elbow, hip])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Muestra tu brazo y torso',
        confidence: 0,
      );
    }

    final armAngle = calculateAngle(hip!, shoulder!, elbow!);
    final confidence = _avgConfidence([shoulder, elbow, hip]);
    
    final result = _updateRepCounter(armAngle, false);

    String feedback;
    if (armAngle < _startAngleThreshold) {
      feedback = 'Brazo abajo. Ángulo: ${armAngle.toStringAsFixed(0)}°';
    } else if (armAngle > _endAngleThreshold) {
      feedback = '¡Brazo arriba! ${armAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Elevando... ${armAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: true,
      primaryAngle: armAngle,
      repState: result,
      feedback: feedback,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE ZANCADA
  PoseAnalysisResult _analyzeLunge(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (!_checkLandmarksValid([hip, knee, ankle])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Ponte de lado para ver la pierna',
        confidence: 0,
      );
    }

    final kneeAngle = calculateAngle(hip!, knee!, ankle!);
    final confidence = _avgConfidence([hip, knee, ankle]);
    
    final result = _updateRepCounter(kneeAngle, true);

    final corrections = <String>[];
    if (knee.x - ankle.x > 60) {
      corrections.add('Rodilla no debe pasar el tobillo');
    }

    String feedback;
    if (kneeAngle > _startAngleThreshold) {
      feedback = 'Posición inicial. Ángulo: ${kneeAngle.toStringAsFixed(0)}°';
    } else if (kneeAngle < _endAngleThreshold) {
      feedback = '¡Buena profundidad! ${kneeAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Bajando... ${kneeAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: corrections.isEmpty,
      primaryAngle: kneeAngle,
      repState: result,
      feedback: feedback,
      corrections: corrections,
      confidence: confidence,
    );
  }

  /// ANÁLISIS DE FLEXIÓN DE CADERA
  PoseAnalysisResult _analyzeHipFlexion(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (!_checkLandmarksValid([shoulder, hip, knee])) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Muestra tu torso y pierna',
        confidence: 0,
      );
    }

    final hipAngle = calculateAngle(shoulder!, hip!, knee!);
    final confidence = _avgConfidence([shoulder, hip, knee]);
    
    final result = _updateRepCounter(hipAngle, true);

    String feedback;
    if (hipAngle > _startAngleThreshold) {
      feedback = 'Posición erguida. Ángulo: ${hipAngle.toStringAsFixed(0)}°';
    } else if (hipAngle < _endAngleThreshold) {
      feedback = '¡Buena flexión! ${hipAngle.toStringAsFixed(0)}°';
    } else {
      feedback = 'Flexionando... ${hipAngle.toStringAsFixed(0)}°';
    }

    return PoseAnalysisResult(
      isCorrectForm: true,
      primaryAngle: hipAngle,
      repState: result,
      feedback: feedback,
      confidence: confidence,
    );
  }

  /// ANÁLISIS GENÉRICO
  PoseAnalysisResult _analyzeGeneric(Pose pose) {
    // Análisis básico de cualquier movimiento
    final landmarks = pose.landmarks.values.where((l) => l.likelihood > 0.5).toList();
    
    if (landmarks.isEmpty) {
      return PoseAnalysisResult(
        isCorrectForm: false,
        primaryAngle: 0,
        repState: RepState.initial,
        feedback: 'Posiciónate frente a la cámara',
        confidence: 0,
      );
    }

    final avgConfidence = landmarks.map((l) => l.likelihood).reduce((a, b) => a + b) / landmarks.length;

    return PoseAnalysisResult(
      isCorrectForm: true,
      primaryAngle: 0,
      repState: RepState.inProgress,
      feedback: 'Detección activa. Confianza: ${(avgConfidence * 100).toStringAsFixed(0)}%',
      confidence: avgConfidence,
    );
  }

  /// Calcula el ángulo entre tres puntos (landmark)
  static double calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    final result = math.atan2(last.y - middle.y, last.x - middle.x) -
                   math.atan2(first.y - middle.y, first.x - middle.x);
    
    double angle = result * (180 / math.pi);
    angle = angle.abs();
    
    if (angle > 180) {
      angle = 360.0 - angle;
    }
    
    return angle;
  }

  /// Verifica si los landmarks tienen buena probabilidad
  bool _checkLandmarksValid(List<PoseLandmark?> landmarks) {
    const minLikelihood = 0.5;
    return landmarks.every((l) => l != null && l.likelihood > minLikelihood);
  }

  /// Calcula la confianza promedio de un conjunto de landmarks
  double _avgConfidence(List<PoseLandmark?> landmarks) {
    final valid = landmarks.where((l) => l != null).cast<PoseLandmark>().toList();
    if (valid.isEmpty) return 0;
    return valid.map((l) => l.likelihood).reduce((a, b) => a + b) / valid.length;
  }

  /// Actualiza el contador de repeticiones usando máquina de estados
  RepState _updateRepCounter(double angle, bool lowerIsBetter) {
    final isInStartPosition = lowerIsBetter 
        ? angle > _startAngleThreshold 
        : angle < _startAngleThreshold;
    final isInEndPosition = lowerIsBetter 
        ? angle < _endAngleThreshold 
        : angle > _endAngleThreshold;

    RepState state = RepState.inProgress;

    if (isInStartPosition) {
      state = RepState.initial;
      if (_wasInEndPosition) {
        // Completó una repetición
        _repCount++;
        _wasInEndPosition = false;
        state = RepState.completed;
        onRepCompleted?.call(_repCount);
        onFeedback?.call('¡Repetición $_repCount completada! 💪');
      }
      _wasInStartPosition = true;
    } else if (isInEndPosition) {
      _wasInEndPosition = true;
      _wasInStartPosition = false;
    }

    return state;
  }

  /// Obtiene el conteo actual de repeticiones
  int get repCount => _repCount;

  /// Reinicia el contador
  void resetCounter() {
    _repCount = 0;
    _wasInStartPosition = true;
    _wasInEndPosition = false;
  }

  /// Mapea el nombre del ejercicio al tipo
  static ExerciseType getExerciseType(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    if (name.contains('sentadilla') || name.contains('squat')) {
      return ExerciseType.squat;
    } else if (name.contains('curl') || name.contains('bíceps') || name.contains('biceps')) {
      return ExerciseType.bicepCurl;
    } else if (name.contains('press') || name.contains('hombro')) {
      return ExerciseType.shoulderPress;
    } else if (name.contains('extensión') || name.contains('extension') && name.contains('rodilla')) {
      return ExerciseType.kneeExtension;
    } else if (name.contains('elevación') || name.contains('elevacion')) {
      if (name.contains('pierna') || name.contains('leg')) {
        return ExerciseType.legRaise;
      } else if (name.contains('brazo') || name.contains('arm')) {
        return ExerciseType.armRaise;
      }
    } else if (name.contains('zancada') || name.contains('lunge')) {
      return ExerciseType.lunge;
    } else if (name.contains('flexión') || name.contains('flexion')) {
      if (name.contains('rodilla')) {
        return ExerciseType.kneeExtension;
      } else if (name.contains('cadera')) {
        return ExerciseType.hipFlexion;
      }
    }
    
    return ExerciseType.generic;
  }

  /// Libera recursos
  Future<void> dispose() async {
    await _poseDetector?.close();
    _poseDetector = null;
  }
}
