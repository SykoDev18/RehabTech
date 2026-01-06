import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rehabtech/services/progress_service.dart';
import 'package:rehabtech/screens/profile/edit_profile_screen.dart';
import 'package:rehabtech/screens/profile/security_screen.dart';
import 'package:rehabtech/screens/profile/my_therapist_screen.dart';
import 'package:rehabtech/screens/profile/text_size_screen.dart';
import 'package:rehabtech/screens/profile/high_contrast_screen.dart';
import 'package:rehabtech/screens/profile/notifications_screen.dart';
import 'package:rehabtech/screens/profile/help_center_screen.dart';
import 'package:rehabtech/screens/profile/privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProgressService _progressService = ProgressService();
  late UserProfile _profile;
  
  @override
  void initState() {
    super.initState();
    _profile = _progressService.userProfile;
  }
  
  void _refreshProfile() {
    setState(() {
      _profile = _progressService.userProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _profile.name.isNotEmpty 
        ? '${_profile.name} ${_profile.lastName}'
        : user?.displayName ?? 'Usuario';
    final email = _profile.email.isNotEmpty 
        ? _profile.email 
        : user?.email ?? 'correo@ejemplo.com';
    
    return CustomScrollView(
      slivers: [
        // Header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          sliver: SliverToBoxAdapter(
            child: const Text(
              'Mi Perfil',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),

        // Tarjeta de perfil
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildProfileCard(displayName, email),
          ),
        ),

        // Sección Cuenta
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Cuenta'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildMenuCard([
              _MenuItem(
                icon: LucideIcons.userPen,
                title: 'Editar Perfil',
                subtitle: 'Actualiza tu información personal',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                  _refreshProfile();
                },
              ),
              _MenuItem(
                icon: LucideIcons.shield,
                title: 'Seguridad',
                subtitle: 'Contraseña y autenticación',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                ),
              ),
              _MenuItem(
                icon: LucideIcons.stethoscope,
                title: 'Mi Terapeuta',
                subtitle: _profile.therapistName.isNotEmpty 
                    ? _profile.therapistName 
                    : 'No asignado',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTherapistScreen()),
                ),
              ),
            ]),
          ),
        ),

        // Sección Accesibilidad
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Accesibilidad'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildMenuCard([
              _MenuItem(
                icon: LucideIcons.type,
                title: 'Tamaño de Texto',
                subtitle: 'Ajusta el tamaño de la fuente',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TextSizeScreen()),
                ),
              ),
              _MenuItem(
                icon: LucideIcons.contrast,
                title: 'Alto Contraste',
                subtitle: 'Mejora la visibilidad',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HighContrastScreen()),
                ),
              ),
            ]),
          ),
        ),

        // Sección Preferencias
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Preferencias'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildMenuCard([
              _MenuItem(
                icon: LucideIcons.bell,
                title: 'Notificaciones',
                subtitle: 'Configura tus alertas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ]),
          ),
        ),

        // Sección Soporte
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Soporte'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildMenuCard([
              _MenuItem(
                icon: LucideIcons.info,
                title: 'Centro de Ayuda',
                subtitle: 'Preguntas frecuentes y soporte',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                ),
              ),
              _MenuItem(
                icon: LucideIcons.fileText,
                title: 'Política de Privacidad',
                subtitle: 'Términos y condiciones',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
            ]),
          ),
        ),

        // Botón Cerrar Sesión
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          sliver: SliverToBoxAdapter(
            child: _buildLogoutButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(String name, String email) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: _profile.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _profile.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            LucideIcons.user,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      )
                    : const Icon(
                        LucideIcons.user,
                        color: Colors.white,
                        size: 35,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (_profile.condition.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _profile.condition,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildMenuItem(item),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.icon,
          color: const Color(0xFF3B82F6),
          size: 22,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Colors.grey[400],
        size: 20,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: _showLogoutDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.logOut,
                  color: Colors.red[600],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
