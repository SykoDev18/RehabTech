import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget para estados vacíos (sin datos)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color iconColor;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon = LucideIcons.inbox,
    this.iconColor = const Color(0xFF9CA3AF),
    this.action,
  });

  /// Factory para lista de ejercicios vacía
  factory EmptyStateWidget.noExercises({Widget? action}) {
    return EmptyStateWidget(
      title: 'Sin ejercicios',
      message: 'No tienes ejercicios asignados aún',
      icon: LucideIcons.dumbbell,
      iconColor: const Color(0xFF6366F1),
      action: action,
    );
  }

  /// Factory para historial vacío
  factory EmptyStateWidget.noHistory({Widget? action}) {
    return EmptyStateWidget(
      title: 'Sin historial',
      message: 'Aún no has completado ningún ejercicio',
      icon: LucideIcons.history,
      iconColor: const Color(0xFF10B981),
      action: action,
    );
  }

  /// Factory para conversaciones vacías
  factory EmptyStateWidget.noConversations({Widget? action}) {
    return EmptyStateWidget(
      title: 'Sin conversaciones',
      message: 'Inicia una conversación con Nora',
      icon: LucideIcons.messageCircle,
      iconColor: const Color(0xFF8B5CF6),
      action: action,
    );
  }

  /// Factory para pacientes vacíos (terapeutas)
  factory EmptyStateWidget.noPatients({Widget? action}) {
    return EmptyStateWidget(
      title: 'Sin pacientes',
      message: 'Aún no tienes pacientes asignados',
      icon: LucideIcons.users,
      iconColor: const Color(0xFF3B82F6),
      action: action,
    );
  }

  /// Factory para resultados de búsqueda vacíos
  factory EmptyStateWidget.noSearchResults({String? query}) {
    return EmptyStateWidget(
      title: 'Sin resultados',
      message: query != null 
          ? 'No encontramos resultados para "$query"' 
          : 'No encontramos lo que buscas',
      icon: LucideIcons.search,
      iconColor: const Color(0xFF9CA3AF),
    );
  }

  /// Factory para notificaciones vacías
  factory EmptyStateWidget.noNotifications() {
    return const EmptyStateWidget(
      title: 'Todo al día',
      message: 'No tienes notificaciones pendientes',
      icon: LucideIcons.bellOff,
      iconColor: Color(0xFF10B981),
    );
  }

  /// Factory para rutinas vacías
  factory EmptyStateWidget.noRoutines({Widget? action}) {
    return EmptyStateWidget(
      title: 'Sin rutinas',
      message: 'No tienes rutinas asignadas todavía',
      icon: LucideIcons.listTodo,
      iconColor: const Color(0xFFF59E0B),
      action: action,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
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
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compacto para estados vacíos en listas pequeñas
class CompactEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon = LucideIcons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
