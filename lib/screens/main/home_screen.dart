
import 'dart:ui';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
          IconButton(
            icon: const Icon(Icons.star, color: Color(0xFF2563EB), size: 30),
            onPressed: () {
              Navigator.pushNamed(context, '/ai_chat');
            },
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
              // Aquí va la barra de progreso
              const SizedBox(height: 16),
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
                  child: const Center(
                    child: Text(
                      'Comenzar Rutina',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          child: Row(
            children: [
              _buildProgressCircle(),
              const SizedBox(width: 20),
              _buildProgressDetails(),
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
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade300,
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso Diario',
          style: TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('3/4', style: TextStyle(color: Color(0xFF111827), fontSize: 18)),
            SizedBox(width: 8),
            Text('Ejercicios Completados', style: TextStyle(color: Color(0xFF4B5563), fontSize: 16)),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.timer, color: Colors.lightBlueAccent, size: 20),
            SizedBox(width: 8),
            Text('18 min', style: TextStyle(color: Color(0xFF111827), fontSize: 18)),
            SizedBox(width: 8),
            Text('Tiempo Activo', style: TextStyle(color: Color(0xFF4B5563), fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
