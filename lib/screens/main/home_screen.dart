import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/exercise.dart';
import 'package:myapp/screens/main/ai_chat_screen.dart';
import 'package:myapp/screens/main/exercise_detail_screen.dart';
import 'package:myapp/services/progress_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onProfileTapped;

  const HomeScreen({super.key, required this.onProfileTapped});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();
  
  // Obtener el ejercicio del día basado en el día de la semana
  Exercise get todayExercise {
    final dayOfWeek = DateTime.now().weekday; // 1 = Lunes, 7 = Domingo
    final exerciseIndex = (dayOfWeek - 1) % allExercises.length;
    return allExercises[exerciseIndex];
  }

  // Obtener ejercicios de los próximos días
  List<Map<String, dynamic>> get upcomingExercises {
    final today = DateTime.now();
    List<Map<String, dynamic>> upcoming = [];
    
    for (int i = 1; i <= 5; i++) {
      final futureDate = today.add(Duration(days: i));
      final exerciseIndex = (futureDate.weekday - 1) % allExercises.length;
      final exercise = allExercises[exerciseIndex];
      
      upcoming.add({
        'exercise': exercise,
        'date': futureDate,
        'dayName': _getDayName(futureDate.weekday),
      });
    }
    
    return upcoming;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return '';
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d \'de\' MMMM', 'es_ES');
    String formatted = formatter.format(now);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  // Obtener estadísticas del día actual
  Map<String, dynamic> _getTodayStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final todayProgress = _progressService.progressList.where((p) =>
      p.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
      p.date.isBefore(todayStart.add(const Duration(days: 1)))
    ).toList();
    
    int exercisesCompleted = todayProgress.length;
    int totalSeconds = todayProgress.fold(0, (sum, p) => sum + p.durationSeconds);
    
    const int dailyGoal = 4;
    double progressPercentage = (exercisesCompleted / dailyGoal).clamp(0.0, 1.0);
    
    return {
      'exercisesCompleted': exercisesCompleted,
      'dailyGoal': dailyGoal,
      'totalSeconds': totalSeconds,
      'progressPercentage': progressPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final userName = _progressService.userProfile.name.isNotEmpty 
        ? _progressService.userProfile.name 
        : 'Usuario';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
        child: Column(
          children: [
            _buildHeader(userName),
            const SizedBox(height: 24),
            _buildRoutineCard(),
            const SizedBox(height: 24),
            _buildProgressCard(),
            const SizedBox(height: 24),
            _buildNextExercisesCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $userName',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 16),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/sparkles.svg',
                    colorFilter: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcIn),
                    width: 28,
                    height: 28,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiChatScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/user.svg',
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    width: 28,
                    height: 28,
                  ),
                  onPressed: widget.onProfileTapped,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRoutineCard() {
    final exercise = todayExercise;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.40),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: exercise.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      exercise.icon,
                      color: exercise.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu Rutina de Hoy',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        ),
                        Text(
                          exercise.title,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                exercise.description,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/clock.svg',
                          colorFilter: const ColorFilter.mode(Color(0xFF4338CA), BlendMode.srcIn),
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exercise.duration,
                          style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/dumbbell.svg',
                          colorFilter: const ColorFilter.mode(Color(0xFF16A34A), BlendMode.srcIn),
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${exercise.series}x${exercise.reps} reps',
                          style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailScreen(exercise: exercise),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/play.svg',
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Comenzar Rutina',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final stats = _getTodayStats();
    final progressPercentage = stats['progressPercentage'] as double;
    final exercisesCompleted = stats['exercisesCompleted'] as int;
    final dailyGoal = stats['dailyGoal'] as int;
    final totalSeconds = stats['totalSeconds'] as int;
    final minutes = totalSeconds ~/ 60;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.40),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso Diario',
                    style: TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressPercentage >= 1.0 
                          ? const Color(0xFFDCFCE7) 
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      progressPercentage >= 1.0 ? '¡Completado!' : 'En progreso',
                      style: TextStyle(
                        color: progressPercentage >= 1.0 
                            ? const Color(0xFF16A34A) 
                            : const Color(0xFFD97706),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildProgressCircle(progressPercentage),
                  const SizedBox(width: 24),
                  _buildProgressDetails(exercisesCompleted, dailyGoal, minutes),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(double progress) {
    final percentage = (progress * 100).toInt();
    
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? const Color(0xFF22C55E) : const Color(0xFF2563EB),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: progress >= 1.0 ? const Color(0xFF22C55E) : const Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (progress >= 1.0)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetails(int completed, int goal, int minutes) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/flame.svg',
                  colorFilter: const ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$completed/$goal',
                    style: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('Ejercicios', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/clock.svg',
                  colorFilter: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcIn),
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$minutes min',
                    style: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('Tiempo Activo', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNextExercisesCard() {
    final upcoming = upcomingExercises;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.40),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Próximos Ejercicios',
                    style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${upcoming.length} días',
                      style: const TextStyle(
                        color: Color(0xFF4338CA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...upcoming.map((item) {
                final exercise = item['exercise'] as Exercise;
                final dayName = item['dayName'] as String;
                final date = item['date'] as DateTime;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExerciseRow(
                    exercise: exercise,
                    dayName: dayName,
                    date: date,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRow({
    required Exercise exercise,
    required String dayName,
    required DateTime date,
  }) {
    final dateFormatter = DateFormat('d MMM', 'es_ES');
    
    return InkWell(
      onTap: () => _showExercisePreview(exercise, dayName, date),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: exercise.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                exercise.icon,
                color: exercise.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dayName,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/clock.svg',
                            colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise.duration,
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFormatter.format(date),
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExercisePreview(Exercise exercise, String dayName, DateTime date) {
    final dateFormatter = DateFormat('EEEE, d \'de\' MMMM', 'es_ES');
    String formattedDate = dateFormatter.format(date);
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: exercise.iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    exercise.icon,
                    color: exercise.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              exercise.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildPreviewStat('Duración', exercise.duration, Icons.timer_outlined),
                const SizedBox(width: 16),
                _buildPreviewStat('Series', '${exercise.series}', Icons.repeat),
                const SizedBox(width: 16),
                _buildPreviewStat('Reps', '${exercise.reps}', Icons.fitness_center),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF6B7280), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este ejercicio estará disponible el $dayName. ¡Prepárate!',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6B7280), size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
