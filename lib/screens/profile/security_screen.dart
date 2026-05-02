import 'dart:ui';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/logger.dart';
import '../../domain/validators/password_validator.dart';
import '../../presentation/widgets/auth/password_strength_indicator.dart';
import '../../presentation/widgets/common/app_gradient_background.dart';
import '../../router/app_router.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Both flags are read-only placeholders for now — Face ID + 2FA toggles are
  // stubbed as "Próximamente" until the underlying integrations land.
  final bool _faceIdEnabled = false;
  final bool _twoFactorEnabled = false;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppGradientBackground(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
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
                          color: themedGlassColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 22,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Seguridad',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
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
                          subtitle: 'Próximamente — aún no disponible',
                          value: _faceIdEnabled,
                          onChanged: null,
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
                          subtitle: 'Próximamente — aún no disponible',
                          value: _twoFactorEnabled,
                          onChanged: null,
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
                          title: 'Cerrar Sesión en este Dispositivo',
                          subtitle: 'Solo cierra la sesión actual',
                          onTap: _signOutThisDevice,
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
    return Builder(
      builder: (context) => Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSecurityCard(List<Widget> children) {
    return Builder(
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: themedGlassColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themedGlassBorder(context)),
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
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                  ],
                );
              }).toList(),
            ),
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
    required ValueChanged<bool>? onChanged,
  }) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: ListTile(
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: newPasswordController,
                builder: (context, value, _) =>
                    PasswordStrengthIndicator(password: value.text),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final passwordResult =
                  PasswordValidator.validate(newPasswordController.text);
              if (!passwordResult.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      passwordResult.errorMessage ?? 'Contraseña inválida',
                    ),
                  ),
                );
                return;
              }

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
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                final msg = switch (e.code) {
                  'wrong-password' => 'La contraseña actual es incorrecta',
                  'invalid-credential' => 'Credenciales inválidas',
                  'weak-password' => 'La nueva contraseña es demasiado débil',
                  'requires-recent-login' =>
                    'Debes volver a iniciar sesión para cambiar la contraseña',
                  'too-many-requests' =>
                    'Demasiados intentos. Intenta más tarde',
                  _ => 'Error de autenticación: ${e.code}',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
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
  
  /// Local sign-out only. Real cross-device session revocation requires
  /// `auth.revokeRefreshTokens` on the Admin SDK; until that Cloud Function
  /// exists, surfacing "close all sessions" would mislead users — so the
  /// label and copy match the actual scope.
  void _signOutThisDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text(
          '¿Cerrar sesión en este dispositivo? Tendrás que volver a iniciar sesión.',
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
              AppRouter.clearUserTypeCache();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Eliminar Cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Esta acción es irreversible. Se eliminarán permanentemente '
                'tu perfil, sesiones, citas, conversaciones y rutinas.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirma con tu contraseña actual para continuar:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                enabled: !isDeleting,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(LucideIcons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      await _performAccountDeletion(
                        dialogContext: dialogContext,
                        password: passwordController.text,
                        onError: () =>
                            setDialogState(() => isDeleting = false),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Eliminar Cuenta',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reauthenticates the user with their password (defence-in-depth: a stale
  /// token shouldn't be enough to wipe a medical-data account), then invokes
  /// the `deleteAccount` Cloud Function which atomically removes Firestore
  /// data plus the auth record.
  Future<void> _performAccountDeletion({
    required BuildContext dialogContext,
    required String password,
    required VoidCallback onError,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('No hay sesión activa.'),
          backgroundColor: Colors.red,
        ),
      );
      onError();
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Ingresa tu contraseña.')),
      );
      onError();
      return;
    }

    try {
      // Step 1 — refresh credentials so the Cloud Function call carries a
      // fresh ID token; this also catches a wrong-password attempt before
      // we touch any data.
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2 — atomic deletion via Cloud Function.
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteAccount',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      await callable.call<Map<dynamic, dynamic>>();

      // Step 3 — local cleanup. The Cloud Function already deleted the auth
      // user, but the client still holds a stale FirebaseUser; signOut clears
      // it cleanly and goToLogin() resets the GoRouter cache.
      await FirebaseAuth.instance.signOut();
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext); // close the dialog
      if (!mounted) return;
      AppRouter.clearUserTypeCache();
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta ha sido eliminada.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'Reauth falló al eliminar cuenta',
        error: e,
        tag: 'Security',
      );
      if (!dialogContext.mounted) return;
      final msg = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Contraseña incorrecta.',
        'too-many-requests' =>
          'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
        _ => 'No se pudo verificar tu identidad: ${e.code}',
      };
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      onError();
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
        'Cloud Function deleteAccount falló',
        error: e,
        tag: 'Security',
      );
      if (!dialogContext.mounted) return;
      final msg = e.code == 'data-loss'
          ? 'Tus datos se eliminaron pero la cuenta de auth quedó. '
              'Contacta a soporte: ${e.message ?? ''}'
          : 'No se pudo eliminar la cuenta: ${e.message ?? e.code}';
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      onError();
    } catch (e, st) {
      AppLogger.error(
        'Error inesperado eliminando cuenta',
        error: e,
        stackTrace: st,
        tag: 'Security',
      );
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
      onError();
    }
  }
}
