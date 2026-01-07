import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/core/utils/logger.dart';
import 'package:rehabtech/models/exercise.dart';
import 'package:rehabtech/screens/main/session_report_screen.dart';
import 'package:rehabtech/services/progress_service.dart';
import 'package:rehabtech/services/pose_detection_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TherapySessionScreen extends StatefulWidget {
  final Exercise exercise;

  const TherapySessionScreen({super.key, required this.exercise});

  @override
  State<TherapySessionScreen> createState() => _TherapySessionScreenState();
}

class _TherapySessionScreenState extends State<TherapySessionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  CameraDescription? _currentCamera;
  bool _isCameraInitialized = false;
  bool _isPaused = false;
  
  // Detección de poses
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isPoseDetectionEnabled = true;
  bool _isProcessingFrame = false;
  String _poseStatus = 'Iniciando detección...';
  double _currentAngle = 0;
  double _poseConfidence = 0;
  List<String> _formCorrections = [];
  
  // Contadores
  int _currentRep = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  
  // Asistente de voz IA
  final List<String> _aiMessages = [];
  bool _isAiThinking = false;
  late GenerativeModel _model;
  ChatSession? _chatSession;
  
  // Feedback para el reporte
  final List<String> _feedbackGood = [];
  final List<String> _feedbackImprove = [];
  
  // Consejos predefinidos para mostrar periódicamente
  final List<String> _tips = [
    '¡Excelente postura! Mantén la espalda recta.',
    'Recuerda respirar: inhala al bajar, exhala al subir.',
    'Muy bien, controla el movimiento lentamente.',
    '¡Vas muy bien! Mantén el ritmo.',
    'Asegúrate de no bloquear las rodillas completamente.',
    'Siente la contracción en el músculo objetivo.',
  ];
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePoseDetection();
    _initializeCamera();
    _initializeAI();
    _startTimer();
    _scheduleAiTips();
  }

  Future<void> _initializePoseDetection() async {
    try {
      await _poseService.initialize();
      
      // Configurar el tipo de ejercicio
      final exerciseType = PoseDetectionService.getExerciseType(widget.exercise.title);
      _poseService.setExercise(exerciseType);
      
      // Configurar callbacks
      _poseService.onRepCompleted = (repCount) {
        if (mounted) {
          setState(() {
            _currentRep = repCount;
          });
          
          // Feedback automático
          if (_currentRep == widget.exercise.reps ~/ 2) {
            _addAiMessage('¡Mitad de camino! Sigue así 🔥');
            _feedbackGood.add('Mantuviste un buen ritmo hasta la mitad');
          } else if (_currentRep >= widget.exercise.reps) {
            _addAiMessage('¡Serie completada! Excelente trabajo 🎉');
            _feedbackGood.add('Completaste todas las repeticiones');
          }
        }
      };
      
      _poseService.onFeedback = (feedback) {
        if (mounted && !_isPaused) {
          _addAiMessage(feedback);
        }
      };
      
      AppLogger.info('Detección de poses inicializada', 
        data: {'ejercicio': widget.exercise.title, 'tipo': exerciseType.name}, 
        tag: 'PoseDetection');
        
    } catch (e, st) {
      AppLogger.error('Error al inicializar detección de poses', 
        error: e, stackTrace: st, tag: 'PoseDetection');
      setState(() {
        _isPoseDetectionEnabled = false;
        _poseStatus = 'Detección no disponible';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Usar cámara frontal si está disponible
        _currentCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        
        _cameraController = CameraController(
          _currentCamera!,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21, // Formato compatible con ML Kit
        );
        
        await _cameraController!.initialize();
        
        // Iniciar streaming de frames para detección de poses
        if (_isPoseDetectionEnabled) {
          await _cameraController!.startImageStream(_processFrame);
        }
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e, st) {
      AppLogger.error('Error al inicializar cámara', error: e, stackTrace: st, tag: 'TherapySession');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || _isPaused || !_isPoseDetectionEnabled || _currentCamera == null) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final result = await _poseService.processFrame(image, _currentCamera!);
      
      if (result != null && mounted) {
        setState(() {
          _poseStatus = result.feedback;
          _currentAngle = result.primaryAngle;
          _poseConfidence = result.confidence;
          _formCorrections = result.corrections;
          
          // Actualizar rep count desde el servicio
          if (_poseService.repCount > _currentRep) {
            _currentRep = _poseService.repCount;
          }
        });
        
        // Mostrar correcciones de forma
        if (result.corrections.isNotEmpty && _formCorrections != result.corrections) {
          for (final correction in result.corrections) {
            _addAiMessage('⚠️ $correction');
            if (!_feedbackImprove.contains(correction)) {
              _feedbackImprove.add(correction);
            }
          }
        }
      }
    } catch (e) {
      // Ignorar errores de procesamiento de frames individuales
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _initializeAI() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
      );
      _chatSession = _model.startChat(
        history: [
          Content.text('''
Eres un asistente de voz para ejercicios de fisioterapia. Tu rol es dar consejos cortos y motivadores durante la sesión.
El usuario está haciendo: ${widget.exercise.title}
Músculos objetivo: ${widget.exercise.targetMuscles}
Descripción: ${widget.exercise.description}

Reglas:
1. Respuestas MUY cortas (máximo 2 oraciones)
2. Sé motivador y positivo
3. Da consejos de técnica específicos para este ejercicio
4. Si el usuario reporta dolor, recomienda parar inmediatamente
5. Usa emojis ocasionalmente para ser amigable
'''),
        ],
      );
      
      // Mensaje inicial
      _addAiMessage('¡Comenzamos! Recuerda mantener buena postura 💪');
    }
  }

  void _scheduleAiTips() {
    // Dar un consejo cada 20 segundos
    Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!mounted || _isPaused) return;
      
      if (_tipIndex < _tips.length) {
        _addAiMessage(_tips[_tipIndex]);
        _tipIndex++;
      } else {
        _tipIndex = 0;
      }
    });
  }

  void _addAiMessage(String message) {
    if (mounted) {
      setState(() {
        _aiMessages.add(message);
        // Mantener solo los últimos 3 mensajes
        if (_aiMessages.length > 3) {
          _aiMessages.removeAt(0);
        }
      });
    }
  }

  Future<void> _askAiForHelp() async {
    if (_chatSession == null || _isAiThinking) return;
    
    setState(() {
      _isAiThinking = true;
    });
    
    try {
      final response = await _chatSession!.sendMessage(
        Content.text('Dame un consejo rápido para mejorar mi técnica en este ejercicio.'),
      );
      
      if (response.text != null && mounted) {
        _addAiMessage(response.text!);
      }
    } catch (e, st) {
      AppLogger.warning('Error al obtener consejo de IA', data: {'error': e.toString()}, tag: 'TherapySession');
    } finally {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _addAiMessage('Sesión pausada. Tómate un respiro 🧘');
    } else {
      _addAiMessage('¡Continuamos! Vamos con todo 💪');
    }
  }

  /// Incrementa manualmente la repetición (backup si la detección falla)
  void _incrementRep() {
    if (_currentRep < widget.exercise.reps) {
      setState(() {
        _currentRep++;
      });
      
      // Registrar feedback positivo
      if (_currentRep == 1) {
        _feedbackGood.add('Iniciaste el ejercicio correctamente');
      }
      
      // Feedback por repetición
      if (_currentRep == widget.exercise.reps ~/ 2) {
        _addAiMessage('¡Mitad de camino! Sigue así 🔥');
        _feedbackGood.add('Mantuviste un buen ritmo hasta la mitad');
      } else if (_currentRep == widget.exercise.reps) {
        _addAiMessage('¡Serie completada! Excelente trabajo 🎉');
        _feedbackGood.add('Completaste todas las repeticiones');
      }
    }
  }

  /// Toggle para activar/desactivar la detección de poses
  void _togglePoseDetection() {
    setState(() {
      _isPoseDetectionEnabled = !_isPoseDetectionEnabled;
    });
    
    if (_isPoseDetectionEnabled) {
      _addAiMessage('🎯 Detección automática activada');
      // Reiniciar streaming si estaba pausado
      if (_cameraController != null && _currentCamera != null) {
        _cameraController!.startImageStream(_processFrame);
      }
    } else {
      _addAiMessage('✋ Modo manual - toca para contar');
      // Detener streaming
      _cameraController?.stopImageStream();
    }
  }

  void _navigateToReport() {
    // Agregar feedback basado en el rendimiento
    if (_currentRep >= widget.exercise.reps * 0.8) {
      _feedbackGood.add('Excelente resistencia durante la sesión');
    }
    if (_elapsedSeconds < widget.exercise.series * 60) {
      _feedbackImprove.add('Intenta tomarte más tiempo entre repeticiones');
    }
    if (_currentRep < widget.exercise.reps * 0.5) {
      _feedbackImprove.add('Trabaja en aumentar el número de repeticiones');
    }
    
    // Mostrar diálogo de dolor antes de ir al reporte
    _showPainLevelDialog();
  }
  
  void _showPainLevelDialog() {
    int painLevel = 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getPainColor(painLevel).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPainIcon(painLevel),
                  size: 48,
                  color: _getPainColor(painLevel),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Sentiste dolor durante el ejercicio?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu respuesta nos ayuda a personalizar tu rehabilitación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                  Text(
                    'Nivel de dolor: $painLevel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    '10',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getPainColor(painLevel),
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: _getPainColor(painLevel),
                  overlayColor: _getPainColor(painLevel).withOpacity(0.2),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                ),
                child: Slider(
                  value: painLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (value) {
                    setDialogState(() {
                      painLevel = value.round();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sin dolor', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('Dolor severo', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 24),
              _buildPainIndicator(painLevel),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveProgressAndNavigate(painLevel);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continuar al Reporte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPainIndicator(int level) {
    String message;
    Color bgColor;
    IconData icon;
    
    if (level == 0) {
      message = '¡Excelente! Sin molestias';
      bgColor = Colors.green[50]!;
      icon = LucideIcons.thumbsUp;
    } else if (level <= 3) {
      message = 'Molestia leve - Normal durante rehabilitación';
      bgColor = Colors.green[50]!;
      icon = LucideIcons.circleCheck;
    } else if (level <= 5) {
      message = 'Dolor moderado - Reduce la intensidad';
      bgColor = Colors.amber[50]!;
      icon = LucideIcons.triangleAlert;
    } else if (level <= 7) {
      message = 'Dolor considerable - Consulta con tu terapeuta';
      bgColor = Colors.orange[50]!;
      icon = LucideIcons.circleAlert;
    } else {
      message = 'Dolor severo - Detén el ejercicio y consulta médico';
      bgColor = Colors.red[50]!;
      icon = LucideIcons.octagonAlert;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _getPainColor(level), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: _getPainColor(level),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getPainColor(int level) {
    if (level <= 3) return const Color(0xFF22C55E);
    if (level <= 5) return const Color(0xFFF59E0B);
    if (level <= 7) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
  
  IconData _getPainIcon(int level) {
    if (level == 0) return LucideIcons.smile;
    if (level <= 3) return LucideIcons.meh;
    if (level <= 6) return LucideIcons.frown;
    return LucideIcons.angry;
  }
  
  void _saveProgressAndNavigate(int painLevel) async {
    // Guardar progreso
    final progressService = ProgressService();
    final completionPercentage = ((_currentRep / widget.exercise.reps) * 100).clamp(0.0, 100.0);
    
    final progressData = ProgressData(
      date: DateTime.now(),
      exerciseId: widget.exercise.id,
      exerciseName: widget.exercise.title,
      completedReps: _currentRep,
      totalReps: widget.exercise.reps,
      durationSeconds: _elapsedSeconds,
      painLevel: painLevel,
      completionPercentage: completionPercentage,
    );
    
    await progressService.saveProgress(progressData);
    
    // Navegar al reporte
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionReportScreen(
          exercise: widget.exercise,
          completedReps: _currentRep,
          totalReps: widget.exercise.reps,
          elapsedSeconds: _elapsedSeconds,
          feedbackGood: _feedbackGood,
          feedbackImprove: _feedbackImprove,
          painLevel: painLevel,
        ),
      ),
    );
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Finalizar sesión?'),
        content: Text(
          'Has completado $_currentRep/${widget.exercise.reps} repeticiones en ${_formatTime(_elapsedSeconds)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToReport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Ver Reporte', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vista de la cámara
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: const Color(0xFF1F2937),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Overlay con información
          SafeArea(
            child: Column(
              children: [
                // Header con información del ejercicio
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info del ejercicio
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoBadge(
                              'EJERCICIO: ${widget.exercise.title}',
                              const Color(0xFF111827),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoBadge(
                              'REPS: ${_currentRep.toString().padLeft(2, '0')}/${widget.exercise.reps}',
                              const Color(0xFF111827),
                            ),
                            const SizedBox(height: 8),
                            _buildTimerBadge(),
                          ],
                        ),
                      ),
                      // Botón Asistente de Voz
                      GestureDetector(
                        onTap: _askAiForHelp,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF22D3EE),
                                          Color(0xFF3B82F6),
                                          Color(0xFFA855F7),
                                          Color(0xFFF97316),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isAiThinking
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            LucideIcons.sparkles,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Asistente de Voz',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Mensajes del asistente IA
                if (_aiMessages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _aiMessages.map((msg) => _buildAiMessageBubble(msg)).toList(),
                    ),
                  ),

                // Indicador de detección de poses
                if (_isPoseDetectionEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildPoseDetectionIndicator(),
                  ),

                const Spacer(),

                // Área táctil para contar repetición manual (solo si detección está desactivada)
                GestureDetector(
                  onTap: !_isPoseDetectionEnabled ? _incrementRep : null,
                  child: Container(
                    color: Colors.transparent,
                    height: 150,
                    width: double.infinity,
                    child: Center(
                      child: !_isPoseDetectionEnabled
                          ? Text(
                              'Toca para contar rep',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                // Controles inferiores
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón Pausar
                            _buildControlButton(
                              icon: _isPaused ? LucideIcons.play : LucideIcons.pause,
                              onTap: _togglePause,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            // Botón Toggle Detección
                            _buildControlButton(
                              icon: _isPoseDetectionEnabled ? LucideIcons.scan : LucideIcons.hand,
                              onTap: _togglePoseDetection,
                              color: _isPoseDetectionEnabled ? const Color(0xFF22C55E) : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            // Botón Asistente IA
                            _buildControlButton(
                              icon: LucideIcons.sparkles,
                              onTap: _askAiForHelp,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            // Botón Cancelar
                            _buildControlButton(
                              icon: LucideIcons.x,
                              onTap: _endSession,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overlay de pausa
          if (_isPaused)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.pause,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PAUSADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(LucideIcons.play),
                      label: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color bgColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isPaused ? Colors.orange : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiMessageBubble(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  /// Widget para mostrar el estado de la detección de poses
  Widget _buildPoseDetectionIndicator() {
    final confidencePercent = (_poseConfidence * 100).toStringAsFixed(0);
    final angleText = _currentAngle > 0 ? '${_currentAngle.toStringAsFixed(0)}°' : '--';
    
    Color statusColor;
    if (_poseConfidence > 0.7) {
      statusColor = const Color(0xFF22C55E); // Verde
    } else if (_poseConfidence > 0.4) {
      statusColor = const Color(0xFFF59E0B); // Amarillo
    } else {
      statusColor = const Color(0xFFEF4444); // Rojo
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detección Activa',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Ángulo actual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      angleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Barra de confianza
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _poseConfidence,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$confidencePercent%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Estado del movimiento
              Text(
                _poseStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Correcciones de forma (si las hay)
              if (_formCorrections.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.triangleAlert, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formCorrections.first,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
