import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/services/progress_service.dart';

class HighContrastScreen extends StatefulWidget {
  const HighContrastScreen({super.key});

  @override
  State<HighContrastScreen> createState() => _HighContrastScreenState();
}

class _HighContrastScreenState extends State<HighContrastScreen> {
  bool _highContrastEnabled = false;
  final ProgressService _progressService = ProgressService();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  void _loadSettings() async {
    final saved = _progressService.getSetting('highContrast');
    if (saved != null) {
      setState(() => _highContrastEnabled = saved == 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _highContrastEnabled
              ? const LinearGradient(
                  colors: [Colors.black, Color(0xFF1A1A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue[50]!,
                    Colors.green[50]!,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _highContrastEnabled
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: _highContrastEnabled
                              ? Border.all(color: Colors.white)
                              : null,
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 22,
                          color: _highContrastEnabled ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Alto Contraste',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _highContrastEnabled
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle de alto contraste
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _highContrastEnabled
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: _highContrastEnabled
                              ? Border.all(color: Colors.white, width: 2)
                              : Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _highContrastEnabled
                                    ? Colors.yellow
                                    : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.contrast,
                                color: _highContrastEnabled
                                    ? Colors.black
                                    : const Color(0xFF3B82F6),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modo Alto Contraste',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _highContrastEnabled
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mejora la visibilidad con colores de alto contraste',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _highContrastEnabled
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _highContrastEnabled,
                              onChanged: (value) {
                                setState(() => _highContrastEnabled = value);
                              },
                              activeTrackColor: Colors.yellow.withAlpha(128),
                              activeThumbColor: Colors.yellow,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Vista previa
                      Text(
                        'Vista Previa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _highContrastEnabled
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _highContrastEnabled
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _highContrastEnabled
                                ? Colors.yellow
                                : Colors.white.withValues(alpha: 0.3),
                            width: _highContrastEnabled ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Extensión de Rodilla',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _highContrastEnabled
                                    ? Colors.yellow
                                    : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Este ejercicio fortalece los músculos del cuádriceps.',
                              style: TextStyle(
                                fontSize: 14,
                                color: _highContrastEnabled
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildPreviewButton(
                                  'Iniciar',
                                  _highContrastEnabled
                                      ? Colors.yellow
                                      : const Color(0xFF3B82F6),
                                  _highContrastEnabled
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                const SizedBox(width: 12),
                                _buildPreviewButton(
                                  'Detalles',
                                  _highContrastEnabled
                                      ? Colors.black
                                      : Colors.white,
                                  _highContrastEnabled
                                      ? Colors.yellow
                                      : const Color(0xFF3B82F6),
                                  outlined: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Información
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _highContrastEnabled
                              ? Colors.yellow.withValues(alpha: 0.1)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _highContrastEnabled
                                ? Colors.yellow.withValues(alpha: 0.3)
                                : const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              color: _highContrastEnabled
                                  ? Colors.yellow
                                  : const Color(0xFF3B82F6),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'El modo de alto contraste mejora la legibilidad para personas con dificultades visuales.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _highContrastEnabled
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _progressService.saveSetting(
                              'highContrast',
                              _highContrastEnabled ? 1.0 : 0.0,
                            );
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Configuración guardada'),
                                backgroundColor: _highContrastEnabled
                                    ? Colors.yellow
                                    : const Color(0xFF22C55E),
                              ),
                            );
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _highContrastEnabled
                                ? Colors.yellow
                                : const Color(0xFF3B82F6),
                            foregroundColor: _highContrastEnabled
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPreviewButton(
    String text,
    Color bgColor,
    Color textColor, {
    bool outlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: outlined
              ? (_highContrastEnabled ? Colors.yellow : const Color(0xFF3B82F6))
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: outlined
              ? (_highContrastEnabled ? Colors.yellow : const Color(0xFF3B82F6))
              : textColor,
        ),
      ),
    );
  }
}
