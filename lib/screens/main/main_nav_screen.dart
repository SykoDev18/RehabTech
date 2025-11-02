
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myapp/screens/main/home_screen.dart';
import 'package:myapp/screens/main/exercises_screen.dart';
import 'package:myapp/screens/main/progress_screen.dart';
import 'package:myapp/screens/main/profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExercisesScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFD1FAE5)], // blue-100 to green-100
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), // backdrop-blur-xl
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.40), // bg-white/40
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF2563EB), // text-blue-600
            unselectedItemColor: const Color(0xFF4B5563), // text-gray-600
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Ejercicios'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progreso'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
