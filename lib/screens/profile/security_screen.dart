import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _faceIdEnabled = false;
  bool _twoFactorEnabled = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Seguridad',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección Autenticación Biométrica
                      _buildSectionTitle('Autenticación Biométrica'),
                      const SizedBox(height: 12),
                      _buildSecurityCard([
                        _buildSwitchTile(
                          icon: LucideIcons.scan,
                          title: 'Face ID / Touch ID',
                          subtitle: 'Usa biometría para iniciar sesión',
                          value: _faceIdEnabled,
                          onChanged: (value) {
                            setState(() => _faceIdEnabled = value);
                          },
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Sección Contraseña
                      _buildSectionTitle('Contraseña'),
                      const SizedBox(height: 12),
                      _buildSecurityCard([
                        _buildActionTile(
                          icon: LucideIcons.keyRound,
                          title: 'Cambiar Contraseña',
                          subtitle: 'Actualiza tu contraseña actual',
                          onTap: _showChangePasswordDialog,
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Sección Autenticación en dos pasos
                      _buildSectionTitle('Verificación'),
                      const SizedBox(height: 12),
                      _buildSecurityCard([
                        _buildSwitchTile(
                          icon: LucideIcons.shieldCheck,
                          title: 'Autenticación de 2 Factores',
                          subtitle: 'Agrega una capa extra de seguridad',
                          value: _twoFactorEnabled,
                          onChanged: (value) {
                            setState(() => _twoFactorEnabled = value);
                            if (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('2FA habilitado. Recibirás códigos por SMS.'),
                                ),
                              );
                            }
                          },
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Sección Sesiones
                      _buildSectionTitle('Sesiones Activas'),
                      const SizedBox(height: 12),
                      _buildSecurityCard([
                        _buildActionTile(
                          icon: LucideIcons.smartphone,
                          title: 'Dispositivos Conectados',
                          subtitle: '1 dispositivo activo',
                          onTap: _showDevicesDialog,
                        ),
                        _buildActionTile(
                          icon: LucideIcons.logOut,
                          title: 'Cerrar Todas las Sesiones',
                          subtitle: 'Cierra sesión en todos los dispositivos',
                          onTap: _closeAllSessions,
                          isDestructive: true,
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Zona de peligro
                      _buildSectionTitle('Zona de Peligro'),
                      const SizedBox(height: 12),
                      _buildDangerCard(),
                    ],
                  ),
                ),
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
  
  Widget _buildSecurityCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF3B82F6).withAlpha(128),
        activeThumbColor: const Color(0xFF3B82F6),
      ),
    );
  }
  
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red[600]! : const Color(0xFF3B82F6);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red[600] : const Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Colors.grey[400],
        size: 20,
      ),
    );
  }
  
  Widget _buildDangerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            onTap: _showDeleteAccountDialog,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.trash2, color: Colors.red[600], size: 22),
            ),
            title: Text(
              'Eliminar Cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            subtitle: const Text(
              'Elimina permanentemente tu cuenta y datos',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            trailing: Icon(
              LucideIcons.chevronRight,
              color: Colors.red[300],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña Actual',
                prefixIcon: const Icon(LucideIcons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                prefixIcon: const Icon(LucideIcons.keyRound),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: const Icon(LucideIcons.keyRound),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden')),
                );
                return;
              }
              
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Cambiar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Dispositivos Conectados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.smartphone, color: Color(0xFF22C55E)),
              ),
              title: const Text('Este dispositivo'),
              subtitle: const Text('Activo ahora'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Actual',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  void _closeAllSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Todas las Sesiones'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión en todos los dispositivos? Tendrás que volver a iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Cerrar Sesiones',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción es irreversible y perderás todos tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (!context.mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes volver a iniciar sesión para eliminar tu cuenta'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar Cuenta',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
