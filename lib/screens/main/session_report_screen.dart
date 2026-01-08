import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rehabtech/models/exercise.dart';

class SessionReportScreen extends StatelessWidget {
  final Exercise exercise;
  final int completedReps;
  final int totalReps;
  final int elapsedSeconds;
  final List<String> feedbackGood;
  final List<String> feedbackImprove;
  final int painLevel;

  const SessionReportScreen({
    super.key,
    required this.exercise,
    required this.completedReps,
    required this.totalReps,
    required this.elapsedSeconds,
    required this.feedbackGood,
    required this.feedbackImprove,
    this.painLevel = 0,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  double get completionPercentage => (completedReps / totalReps) * 100;

  String get performanceRating {
    if (completionPercentage >= 90) return 'Excelente';
    if (completionPercentage >= 70) return 'Muy Bien';
    if (completionPercentage >= 50) return 'Bien';
    return 'Sigue Practicando';
  }

  Color get performanceColor {
    if (completionPercentage >= 90) return const Color(0xFF22C55E);
    if (completionPercentage >= 70) return const Color(0xFF3B82F6);
    if (completionPercentage >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resumen de Sesión',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.x,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // Puntuación principal
                _buildMainScoreCard(),
                const SizedBox(height: 20),

                // Estadísticas de la sesión
                _buildSessionStats(),
                const SizedBox(height: 20),

                // Comparación con sesión anterior
                _buildComparisonCard(),
                const SizedBox(height: 20),

                // Lo que hiciste bien
                _buildFeedbackCard(
                  title: '¡Lo que hiciste bien!',
                  icon: LucideIcons.circleCheck,
                  iconColor: const Color(0xFF22C55E),
                  items: feedbackGood.isEmpty
                      ? ['Completaste la sesión', 'Mantuviste buen ritmo']
                      : feedbackGood,
                ),
                const SizedBox(height: 16),

                // Áreas de mejora
                _buildFeedbackCard(
                  title: 'Áreas de mejora',
                  icon: LucideIcons.target,
                  iconColor: const Color(0xFFF59E0B),
                  items: feedbackImprove.isEmpty
                      ? ['Intenta mantener la postura más tiempo', 'Controla la respiración']
                      : feedbackImprove,
                ),
                const SizedBox(height: 20),

                // Retroalimentación personalizada
                _buildAiFeedbackCard(),
                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: LucideIcons.repeat,
                        label: 'Repetir',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: LucideIcons.house,
                        label: 'Inicio',
                        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScoreCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Círculo de progreso
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: completionPercentage / 100,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(performanceColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${completionPercentage.toInt()}%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: performanceColor,
                          ),
                        ),
                        Text(
                          'Completado',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Calificación
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: performanceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.award,
                      color: performanceColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      performanceRating,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: performanceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStats() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: LucideIcons.clock,
                value: _formatTime(elapsedSeconds),
                label: 'Duración',
                color: const Color(0xFF3B82F6),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                icon: LucideIcons.repeat,
                value: '$completedReps/$totalReps',
                label: 'Repeticiones',
                color: const Color(0xFF22C55E),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                icon: LucideIcons.flame,
                value: '${(elapsedSeconds * 0.15).toInt()}',
                label: 'Calorías',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    // Datos simulados de sesión anterior
    final previousReps = (totalReps * 0.75).toInt();
    final improvement = ((completedReps - previousReps) / previousReps * 100).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.trendingUp, color: const Color(0xFF22C55E), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Comparación con sesión anterior',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mini gráfica de barras comparativa
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: totalReps.toDouble() * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final titles = ['Anterior', 'Hoy'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                titles[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: previousReps.toDouble(),
                            color: const Color(0xFF9CA3AF),
                            width: 40,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: completedReps.toDouble(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 40,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Indicador de mejora
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: improvement >= 0
                      ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      improvement >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: improvement >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${improvement >= 0 ? '+' : ''}$improvement% vs sesión anterior',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: improvement >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiFeedbackCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                const Color(0xFF22D3EE).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Retroalimentación de Nora',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                completionPercentage >= 80
                    ? '¡Excelente sesión, ${exercise.title}! Tu constancia está dando frutos. '
                        'Noté que mantienes un buen ritmo durante los ejercicios. '
                        'Para la próxima sesión, intenta enfocarte en la respiración durante cada repetición '
                        'para maximizar los beneficios del ejercicio. ¡Sigue así! 💪'
                    : completionPercentage >= 50
                        ? 'Buen trabajo completando la sesión. Cada repetición cuenta para tu recuperación. '
                            'Te sugiero que en la próxima sesión intentes mantener un ritmo más constante '
                            'y recuerda que la calidad del movimiento es más importante que la cantidad. '
                            '¡Vas por buen camino! 🎯'
                        : 'Completar parte de la sesión ya es un logro. Escucha a tu cuerpo y no te exijas demasiado. '
                            'Para mejorar, intenta dividir el ejercicio en bloques más pequeños con descansos entre ellos. '
                            'La constancia es clave en la rehabilitación. ¡Ánimo! 🌟',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: const Color(0xFF3B82F6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF3B82F6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF3B82F6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
