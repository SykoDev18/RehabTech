import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rehabtech/services/progress_service.dart';
import 'package:rehabtech/services/pdf_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = 'Semanal';
  final ProgressService _progressService = ProgressService();
  
  final List<String> _weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  
  // Datos reales calculados
  List<double> _movementData = [];
  List<double> _adherenceData = [];
  Map<String, dynamic> _stats = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    setState(() {
      switch (_selectedPeriod) {
        case 'Semanal':
          _stats = _progressService.getWeeklyStats();
          _movementData = _getWeeklyMovementData();
          _adherenceData = _getWeeklyAdherenceData();
          break;
        case 'Mensual':
          _stats = _progressService.getMonthlyStats();
          _movementData = _getMonthlyMovementData();
          _adherenceData = _getMonthlyAdherenceData();
          break;
        default:
          _stats = _progressService.getTotalStats();
          _movementData = _getTotalMovementData();
          _adherenceData = _getTotalAdherenceData();
      }
    });
  }
  
  List<double> _getWeeklyMovementData() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    List<double> data = List.filled(7, 0);
    
    for (var progress in _progressService.progressList) {
      if (progress.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        int dayIndex = progress.date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          // Usar completion percentage como indicador de movimiento
          data[dayIndex] = (data[dayIndex] + progress.completionPercentage) / 2;
          if (data[dayIndex] == progress.completionPercentage / 2) {
            data[dayIndex] = progress.completionPercentage;
          }
        }
      }
    }
    return data;
  }
  
  List<double> _getWeeklyAdherenceData() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    List<double> data = List.filled(7, 0);
    
    for (var progress in _progressService.progressList) {
      if (progress.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        int dayIndex = progress.date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          data[dayIndex] += 1;
        }
      }
    }
    return data;
  }
  
  List<double> _getMonthlyMovementData() {
    // Dividir el mes en 4 semanas
    List<double> data = List.filled(4, 0);
    List<int> counts = List.filled(4, 0);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    for (var progress in _progressService.progressList) {
      if (progress.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        int weekIndex = ((progress.date.day - 1) / 7).floor();
        if (weekIndex >= 0 && weekIndex < 4) {
          data[weekIndex] += progress.completionPercentage;
          counts[weekIndex]++;
        }
      }
    }
    
    for (int i = 0; i < 4; i++) {
      if (counts[i] > 0) {
        data[i] = data[i] / counts[i];
      }
    }
    return data;
  }
  
  List<double> _getMonthlyAdherenceData() {
    List<double> data = List.filled(4, 0);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    for (var progress in _progressService.progressList) {
      if (progress.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        int weekIndex = ((progress.date.day - 1) / 7).floor();
        if (weekIndex >= 0 && weekIndex < 4) {
          data[weekIndex] += 1;
        }
      }
    }
    return data;
  }
  
  List<double> _getTotalMovementData() {
    // Últimos 6 meses
    List<double> data = List.filled(6, 0);
    List<int> counts = List.filled(6, 0);
    final now = DateTime.now();
    
    for (var progress in _progressService.progressList) {
      int monthDiff = (now.year - progress.date.year) * 12 + (now.month - progress.date.month);
      int index = 5 - monthDiff;
      if (index >= 0 && index < 6) {
        data[index] += progress.completionPercentage;
        counts[index]++;
      }
    }
    
    for (int i = 0; i < 6; i++) {
      if (counts[i] > 0) {
        data[i] = data[i] / counts[i];
      }
    }
    return data;
  }
  
  List<double> _getTotalAdherenceData() {
    List<double> data = List.filled(6, 0);
    final now = DateTime.now();
    
    for (var progress in _progressService.progressList) {
      int monthDiff = (now.year - progress.date.year) * 12 + (now.month - progress.date.month);
      int index = 5 - monthDiff;
      if (index >= 0 && index < 6) {
        data[index] += 1;
      }
    }
    return data;
  }
  
  void _shareProgress() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Compartir Progreso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.share2, color: const Color(0xFF3B82F6)),
              ),
              title: const Text('Compartir PDF'),
              subtitle: Text('Enviar reporte $_selectedPeriod'),
              onTap: () async {
                Navigator.pop(context);
                _showLoadingDialog();
                try {
                  await PdfService.sharePdf(_selectedPeriod);
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al compartir: $e')),
                  );
                }
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.printer, color: const Color(0xFF22C55E)),
              ),
              title: const Text('Imprimir'),
              subtitle: const Text('Vista previa e impresión'),
              onTap: () async {
                Navigator.pop(context);
                _showLoadingDialog();
                try {
                  await PdfService.printPdf(_selectedPeriod);
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al imprimir: $e')),
                  );
                }
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      ),
    );
  }

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
                  onTap: _shareProgress,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
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
        
        // Empty state si no hay datos
        if (_progressService.progressList.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
            sliver: SliverToBoxAdapter(
              child: _buildEmptyState(),
            ),
          )
        else ...[
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

          // Resumen
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            sliver: SliverToBoxAdapter(
              child: _buildWeeklySummary(),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.chartLine,
                  size: 48,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sin datos aún',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completa tu primera sesión de ejercicios para comenzar a ver tu progreso aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ir a Ejercicios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = period);
                    _loadData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
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
    List<String> labels;
    int maxX;
    
    switch (_selectedPeriod) {
      case 'Mensual':
        labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
        maxX = 3;
        break;
      case 'Total':
        labels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
        final now = DateTime.now();
        labels = List.generate(6, (i) {
          final month = DateTime(now.year, now.month - 5 + i, 1);
          return ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][month.month - 1];
        });
        maxX = 5;
        break;
      default:
        labels = _weekDays;
        maxX = 6;
    }
    
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso de Ejercicios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_stats['avgCompletion']?.toStringAsFixed(0) ?? 0}% prom.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Porcentaje de completitud - $_selectedPeriod',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: _movementData.every((e) => e == 0)
                  ? Center(
                      child: Text(
                        'Sin datos para este período',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[value.toInt()],
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
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: maxX.toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _movementData.asMap().entries.map((entry) {
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
                              const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              const Color(0xFF3B82F6).withValues(alpha: 0.0),
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
    List<String> labels;
    double maxY;
    
    switch (_selectedPeriod) {
      case 'Mensual':
        labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
        maxY = (_adherenceData.isEmpty ? 8 : (_adherenceData.reduce((a, b) => a > b ? a : b) + 2)).ceilToDouble();
        break;
      case 'Total':
        final now = DateTime.now();
        labels = List.generate(6, (i) {
          final month = DateTime(now.year, now.month - 5 + i, 1);
          return ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][month.month - 1];
        });
        maxY = (_adherenceData.isEmpty ? 20 : (_adherenceData.reduce((a, b) => a > b ? a : b) + 5)).ceilToDouble();
        break;
      default:
        labels = _weekDays;
        maxY = 8;
    }
    
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Adherencia al Tratamiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_stats['totalExercises'] ?? 0} total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ejercicios completados - $_selectedPeriod',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: _adherenceData.every((e) => e == 0)
                  ? Center(
                      child: Text(
                        'Sin datos para este período',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
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
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[value.toInt()],
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
                          interval: maxY > 10 ? 5 : 2,
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
                      horizontalInterval: maxY > 10 ? 5 : 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: _adherenceData.asMap().entries.map((entry) {
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
                            width: _selectedPeriod == 'Total' ? 20 : 28,
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
    String periodLabel;
    switch (_selectedPeriod) {
      case 'Mensual':
        periodLabel = 'Mensual';
        break;
      case 'Total':
        periodLabel = 'Total';
        break;
      default:
        periodLabel = 'Semanal';
    }
    
    final totalSeconds = _stats['totalSeconds'] ?? 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    
    final totalExercises = _stats['totalExercises'] ?? 0;
    final avgPain = _stats['avgPain'] ?? 0.0;
    final streak = _stats['streak'] ?? 0;
    
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
              Text(
                'Resumen $periodLabel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow(
                label: 'Tiempo Activo:',
                value: totalSeconds == 0 ? '0m' : timeString,
                icon: LucideIcons.clock,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Ejercicios Completados:',
                value: '$totalExercises',
                icon: LucideIcons.circleCheck,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Nivel de Dolor (Promedio):',
                value: totalExercises == 0 ? '-' : '${avgPain.toStringAsFixed(1)}/10',
                icon: LucideIcons.activity,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Racha actual:',
                value: streak > 0 ? '$streak días 🔥' : '0 días',
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
            color: color.withValues(alpha: 0.1),
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
