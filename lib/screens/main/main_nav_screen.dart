
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(onProfileTapped: () => _onItemTapped(3)),
      ExercisesScreen(onProfileTapped: () => _onItemTapped(3)),
      const ProgressScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF2563EB); // blue-600
    const Color inactiveColor = Color(0xFF4B5563); // gray-600

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
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.40),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/house.svg', colorFilter: const ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/house.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/dumbbell.svg', colorFilter: const ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/dumbbell.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Ejercicios',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/trending-up.svg', colorFilter: const ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/trending-up.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Progreso',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/user.svg', colorFilter: const ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/user.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
