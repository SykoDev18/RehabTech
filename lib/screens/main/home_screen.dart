
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onProfileTapped;

  const HomeScreen({super.key, required this.onProfileTapped});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildRoutineCard(),
          const SizedBox(height: 24),
          _buildProgressCard(),
          const SizedBox(height: 24),
          _buildNextExercisesCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buenos días, Marco',
                style: TextStyle(color: Color(0xFF111827), fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Domingo, 2 de Noviembre',
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: SvgPicture.asset('assets/sparkles.svg', color: const Color(0xFF2563EB), width: 28, height: 28),
                  onPressed: () {
                    Navigator.pushNamed(context, '/ai_chat');
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
                  icon: SvgPicture.asset('assets/user.svg', color: Colors.white, width: 28, height: 28),
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
              const Text('Tu Rutina de Hoy', style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Fortalecimiento de Rodilla', style: TextStyle(color: Color(0xFF4B5563), fontSize: 16)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF), // indigo-100
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/clock.svg', color: const Color(0xFF4338CA), width: 16, height: 16), // indigo-700
                    const SizedBox(width: 6),
                    const Text('25 minutos', style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {},
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
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/play.svg', color: Colors.white, width: 20, height: 20),
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
              const Text(
                'Progreso Diario',
                style: TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildProgressCircle(),
                  const SizedBox(width: 24),
                  _buildProgressDetails(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 0.75,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
           Center(
            child: Text(
              '75%',
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetails() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5), // orange-100
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset('assets/flame.svg', color: const Color(0xFFEA580C), width: 20, height: 20), // orange-600
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3/4', style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Ejercicios', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
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
                  color: const Color(0xFFDBEAFE), // blue-100
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset('assets/clock.svg', color: const Color(0xFF2563EB), width: 20, height: 20), // blue-600
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('18 min', style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Tiempo Activo', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNextExercisesCard() {
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
              const Text(
                'Próximos Ejercicios',
                style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildExerciseRow('assets/dumbbell.svg', 'Movilidad de Hombro', '15 min', const Color(0xFF9333EA)), // purple-600
              const SizedBox(height: 12),
              _buildExerciseRow('assets/heart.svg', 'Ejercicios Cardiovasculares', '20 min', const Color(0xFFE11D48)), // red-600
              const SizedBox(height: 12),
              _buildExerciseRow('assets/footprints.svg', 'Equilibrio y Coordinación', '12 min', const Color(0xFF16A34A)), // green-600
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRow(String iconPath, String title, String duration, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(iconPath, color: color, width: 28, height: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  SvgPicture.asset('assets/clock.svg', color: const Color(0xFF4B5563), width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(duration, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        SvgPicture.asset('assets/chevron-right.svg', color: const Color(0xFF9CA3AF), width: 24, height: 24), // gray-400
      ],
    );
  }
}
