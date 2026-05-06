import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../presentation/widgets/common/app_gradient_background.dart';
import '../../presentation/widgets/common/connectivity_banner.dart';
import '../../services/chat_badge_service.dart';
import '../../widgets/therapist_unverified_banner.dart';
import 'patients_screen.dart';
import 'routines_screen.dart';
import 'calendar_screen.dart';
import 'therapist_messages_screen.dart';
import 'therapist_profile_screen.dart';

class TherapistMainNavScreen extends StatefulWidget {
  const TherapistMainNavScreen({super.key});

  @override
  State<TherapistMainNavScreen> createState() => _TherapistMainNavScreenState();
}

class _TherapistMainNavScreenState extends State<TherapistMainNavScreen> {
  int _currentIndex = 0;
  final ChatBadgeService _badgeService = ChatBadgeService();

  final List<Widget> _screens = const [
    PatientsScreen(),
    RoutinesScreen(),
    CalendarScreen(),
    TherapistMessagesScreen(),
    TherapistProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          const TherapistUnverifiedBanner(),
          Expanded(
            child: AppGradientBackground(
              threeStop: true,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: themedGlassColor(context, alpha: 0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, LucideIcons.users, 'Pacientes'),
                  _buildNavItem(1, LucideIcons.dumbbell, 'Rutinas'),
                  _buildNavItem(2, LucideIcons.calendar, 'Calendario'),
                  _buildNavItem(
                    3,
                    LucideIcons.messageCircle,
                    'Mensajes',
                    badgeStream: _badgeUidStream(),
                  ),
                  _buildNavItem(4, LucideIcons.user, 'Perfil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    Stream<int>? badgeStream,
  }) {
    final isSelected = _currentIndex == index;
    final color =
        isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF);

    Widget iconWidget = Icon(icon, color: color, size: 22);
    if (badgeStream != null) {
      iconWidget = StreamBuilder<int>(
        stream: badgeStream,
        builder: (context, snap) {
          final count = snap.data ?? 0;
          if (count <= 0) return iconWidget;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 22),
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

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Returns the unread-count stream for the current user, or an empty
  /// stream if signed out (the badge widget hides itself on count 0).
  Stream<int> _badgeUidStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream<int>.empty();
    return _badgeService.watchTotalUnread(uid);
  }
}
