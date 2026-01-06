import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:myapp/models/exercise.dart';
import 'package:myapp/screens/main/session_report_screen.dart';
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
  bool _isCameraInitialized = false;
  bool _isPaused = false;
  
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
    _initializeCamera();
    _initializeAI();
    _startTimer();
    _scheduleAiTips();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Usar cámara frontal si está disponible
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error al inicializar cámara: $e');
    }
  }

  void _initializeAI() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
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
    } catch (e) {
      print('Error al obtener consejo de IA: $e');
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
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionReportScreen(
          exercise: widget.exercise,
          completedReps: _currentRep,
          totalReps: widget.exercise.reps,
          elapsedSeconds: _elapsedSeconds,
          feedbackGood: _feedbackGood,
          feedbackImprove: _feedbackImprove,
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
    _cameraController?.dispose();
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

                const Spacer(),

                // Botón para contar repetición (toca la pantalla)
                GestureDetector(
                  onTap: _incrementRep,
                  child: Container(
                    color: Colors.transparent,
                    height: 200,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Toca para contar rep',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
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
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
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
                            const SizedBox(width: 16),
                            // Botón Asistente IA
                            _buildControlButton(
                              icon: LucideIcons.sparkles,
                              onTap: _askAiForHelp,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
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
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
