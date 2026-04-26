
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/presentation/widgets/common/app_gradient_background.dart';
import 'package:rehabtech/presentation/widgets/common/connectivity_banner.dart';
import 'package:rehabtech/screens/main/home_screen.dart';
import 'package:rehabtech/screens/main/exercises_screen.dart';
import 'package:rehabtech/screens/main/messages_screen.dart';
import 'package:rehabtech/screens/main/progress_screen.dart';
import 'package:rehabtech/screens/main/profile_screen.dart';

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
      HomeScreen(onProfileTapped: () => _onItemTapped(4)),
      ExercisesScreen(onProfileTapped: () => _onItemTapped(4)),
      const MessagesScreen(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color activeColor = Color(0xFF2563EB); // blue-600
    final Color inactiveColor = isDark
        ? const Color(0xFF94A3B8) // slate-400
        : const Color(0xFF4B5563); // gray-600

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: AppGradientBackground(
              child: IndexedStack(
                index: _selectedIndex,
                children: _widgetOptions,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: BottomNavigationBar(
            backgroundColor: themedGlassColor(context, alpha: 0.4),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/house.svg', colorFilter: ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/house.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/dumbbell.svg', colorFilter: ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/dumbbell.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Ejercicios',
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.messageCircle, color: inactiveColor),
                activeIcon: Icon(LucideIcons.messageCircle, color: activeColor),
                label: 'Mensajes',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/trending-up.svg', colorFilter: ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
                activeIcon: SvgPicture.asset('assets/trending-up.svg', colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn)),
                label: 'Progreso',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/user.svg', colorFilter: ColorFilter.mode(inactiveColor, BlendMode.srcIn)),
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
