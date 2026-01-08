import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget reutilizable para mostrar errores de forma consistente
class AppErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onRetry;
  final String retryText;

  const AppErrorWidget({
    super.key,
    this.title = 'Algo salió mal',
    this.message,
    this.icon = LucideIcons.circleAlert,
    this.iconColor = const Color(0xFFEF4444),
    this.onRetry,
    this.retryText = 'Reintentar',
  });

  /// Factory para errores de red
  factory AppErrorWidget.network({
    VoidCallback? onRetry,
    String? message,
  }) {
    return AppErrorWidget(
      title: 'Sin conexión',
      message: message ?? 'Verifica tu conexión a internet e intenta de nuevo',
      icon: LucideIcons.wifiOff,
      iconColor: const Color(0xFFF59E0B),
      onRetry: onRetry,
    );
  }

  /// Factory para errores de servidor
  factory AppErrorWidget.server({
    VoidCallback? onRetry,
    String? message,
  }) {
    return AppErrorWidget(
      title: 'Error del servidor',
      message: message ?? 'Hubo un problema con el servidor. Intenta más tarde',
      icon: LucideIcons.serverCrash,
      iconColor: const Color(0xFFEF4444),
      onRetry: onRetry,
    );
  }

  /// Factory para errores de permisos
  factory AppErrorWidget.permission({
    VoidCallback? onRetry,
    String? message,
  }) {
    return AppErrorWidget(
      title: 'Permiso denegado',
      message: message ?? 'No tienes permiso para acceder a este recurso',
      icon: LucideIcons.shieldOff,
      iconColor: const Color(0xFFF59E0B),
      onRetry: onRetry,
      retryText: 'Configurar permisos',
    );
  }

  /// Factory para errores de autenticación
  factory AppErrorWidget.auth({
    VoidCallback? onRetry,
    String? message,
  }) {
    return AppErrorWidget(
      title: 'Sesión expirada',
      message: message ?? 'Tu sesión ha expirado. Inicia sesión de nuevo',
      icon: LucideIcons.logOut,
      iconColor: const Color(0xFF6366F1),
      onRetry: onRetry,
      retryText: 'Iniciar sesión',
    );
  }

  /// Factory para errores de timeout
  factory AppErrorWidget.timeout({
    VoidCallback? onRetry,
    String? message,
  }) {
    return AppErrorWidget(
      title: 'Tiempo agotado',
      message: message ?? 'La solicitud tardó demasiado. Intenta de nuevo',
      icon: LucideIcons.clock,
      iconColor: const Color(0xFFF59E0B),
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compacto para errores inline
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleAlert,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(
                LucideIcons.refreshCw,
                color: Color(0xFFDC2626),
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
