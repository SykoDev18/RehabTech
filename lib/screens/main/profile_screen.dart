import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rehabtech/presentation/providers/theme_provider.dart';
import 'package:rehabtech/services/progress_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProgressService _progressService = ProgressService();
  late UserProfile _profile;
  String? _patientId;
  
  @override
  void initState() {
    super.initState();
    _profile = _progressService.userProfile;
    _loadPatientId();
  }

  Future<void> _loadPatientId() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (mounted && doc.exists) {
        setState(() {
          _patientId = doc.data()?['patientId'];
        });
      }
    }
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
                  await context.push('/profile/edit');
                  _refreshProfile();
                },
              ),
              _MenuItem(
                icon: LucideIcons.shield,
                title: 'Seguridad',
                subtitle: 'Contraseña y autenticación',
                onTap: () => context.push('/profile/security'),
              ),
              _MenuItem(
                icon: LucideIcons.stethoscope,
                title: 'Mi Terapeuta',
                subtitle: _profile.therapistName.isNotEmpty 
                    ? _profile.therapistName 
                    : 'No asignado',
                onTap: () => context.push('/profile/therapist'),
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
                onTap: () => context.push('/profile/text-size'),
              ),
              _MenuItem(
                icon: LucideIcons.contrast,
                title: 'Alto Contraste',
                subtitle: 'Mejora la visibilidad',
                onTap: () => context.push('/profile/high-contrast'),
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
                onTap: () => context.push('/profile/notifications'),
              ),
            ]),
          ),
        ),

        // Sección Apariencia (Dark Mode)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Apariencia'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildThemeCard(),
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
                onTap: () => context.push('/profile/help'),
              ),
              _MenuItem(
                icon: LucideIcons.fileText,
                title: 'Política de Privacidad',
                subtitle: 'Términos y condiciones',
                onTap: () => context.push('/profile/privacy'),
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
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (_patientId != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _patientId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID copiado al portapapeles'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.hash, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'ID: $_patientId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.copy, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_profile.condition.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) context.go('/login');
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

  Widget _buildThemeCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  // Modo Oscuro Toggle
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                        color: const Color(0xFF1E293B),
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'Activado' : 'Desactivado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: const Color(0xFF3B82F6),
                    ),
                  ),
                  const Divider(height: 1),
                  // Tema del sistema
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.smartphone,
                        color: Colors.purple,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Usar tema del sistema',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.system ? 'Activado' : 'Desactivado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: themeProvider.themeMode == ThemeMode.system,
                      onChanged: (value) {
                        if (value) {
                          themeProvider.setThemeMode(ThemeMode.system);
                        }
                      },
                      activeColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
