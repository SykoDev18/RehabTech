
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/presentation/widgets/common/app_gradient_background.dart';
import 'package:rehabtech/presentation/widgets/common/connectivity_banner.dart';
import 'package:rehabtech/screens/chat/conversations_screen.dart';
import 'package:rehabtech/screens/main/home_screen.dart';
import 'package:rehabtech/screens/main/exercises_screen.dart';
import 'package:rehabtech/screens/main/progress_screen.dart';
import 'package:rehabtech/screens/main/profile_screen.dart';
import 'package:rehabtech/services/chat_badge_service.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  final ChatBadgeService _badgeService = ChatBadgeService();

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(onProfileTapped: () => _onItemTapped(4)),
      ExercisesScreen(onProfileTapped: () => _onItemTapped(4)),
      ConversationsScreen(),
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
                icon: _ChatNavIcon(
                  service: _badgeService,
                  color: inactiveColor,
                ),
                activeIcon: _ChatNavIcon(
                  service: _badgeService,
                  color: activeColor,
                ),
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

/// Bottom-nav messages icon with an unread badge driven by
/// [ChatBadgeService]. Hides itself when the user is signed out or has
/// 0 unread messages.
class _ChatNavIcon extends StatelessWidget {
  const _ChatNavIcon({required this.service, required this.color});

  final ChatBadgeService service;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final icon = Icon(LucideIcons.messageCircle, color: color);
    if (uid == null) return icon;
    return StreamBuilder<int>(
      stream: service.watchTotalUnread(uid),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        if (count <= 0) return icon;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
