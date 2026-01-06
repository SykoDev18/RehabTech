import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = 'Semanal';
  
  // Datos simulados
  final List<double> _weeklyMovementData = [45, 55, 58, 52, 68, 72, 75];
  final List<double> _weeklyAdherenceData = [6, 5, 4, 7, 6, 7, 6];
  final List<String> _weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tu Progreso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compartir progreso...')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.share2,
                      color: const Color(0xFF3B82F6),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tabs de período
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildPeriodTabs(),
          ),
        ),

        // Gráfica de Rango de Movimiento
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildMovementRangeCard(),
          ),
        ),

        // Gráfica de Adherencia
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildAdherenceCard(),
          ),
        ),

        // Resumen Semanal
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          sliver: SliverToBoxAdapter(
            child: _buildWeeklySummary(),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    final periods = ['Semanal', 'Mensual', 'Total'];
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      period,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF111827)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementRangeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rango de Movimiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mejora de la rodilla izquierda',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _weekDays.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _weekDays[value.toInt()],
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _weeklyMovementData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value);
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF3B82F6),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: const Color(0xFF3B82F6),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.3),
                              const Color(0xFF3B82F6).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
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

  Widget _buildAdherenceCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adherencia al Tratamiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Rutinas completadas (últimos 7 días)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 8,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => const Color(0xFF111827),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} ejercicios',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _weekDays.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _weekDays[value.toInt()],
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          reservedSize: 25,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: _weeklyAdherenceData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 28,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen Semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow(
                label: 'Tiempo Activo:',
                value: '2h 45m',
                icon: LucideIcons.clock,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Ejercicios Completados:',
                value: '48/50',
                icon: LucideIcons.circleCheck,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Nivel de Dolor (Promedio):',
                value: '3/10',
                icon: LucideIcons.activity,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Racha actual:',
                value: '7 días 🔥',
                icon: LucideIcons.flame,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
