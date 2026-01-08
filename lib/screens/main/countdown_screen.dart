import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rehabtech/models/exercise.dart';
import 'package:rehabtech/screens/main/therapy_session_screen.dart';

class CountdownScreen extends StatefulWidget {
  final Exercise exercise;

  const CountdownScreen({super.key, required this.exercise});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int _countdown = 5;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _animationController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
        _animationController.reset();
        _animationController.forward();
      } else {
        timer.cancel();
        _navigateToSession();
      }
    });
  }

  void _navigateToSession() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TherapySessionScreen(exercise: widget.exercise),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Color _getCountdownColor() {
    if (_countdown >= 4) {
      return const Color(0xFF22C55E); // Verde
    } else if (_countdown == 3) {
      return const Color(0xFFF59E0B); // Amarillo/Naranja
    } else {
      return const Color(0xFFEF4444); // Rojo
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCountdownColor();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo borrosa
          Image.network(
            widget.exercise.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1F2937),
              );
            },
          ),
          // Efecto de blur sobre la imagen
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          // Contenido centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Texto "PREPÁRATE"
                const Text(
                  'PREPÁRATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
                // Círculo animado con número
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo de fondo gris
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      // Círculo de progreso con color
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (6 - _countdown) / 5),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            );
                          },
                        ),
                      ),
                      // Número
                      Text(
                        '$_countdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Nombre del ejercicio
                Text(
                  widget.exercise.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Botón cancelar
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
