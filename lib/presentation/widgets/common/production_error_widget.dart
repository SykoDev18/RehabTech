import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Friendly replacement for Flutter's red `ErrorWidget` in release builds.
///
/// Wired via `ErrorWidget.builder` in `main.dart` — debug builds keep the
/// default red screen so devs see the actual exception. Release builds
/// render this card with a generic "something went wrong" message and an
/// optional retry that just rebuilds the offending subtree.
class ProductionErrorWidget extends StatelessWidget {
  const ProductionErrorWidget({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.circleAlert,
                  size: 40,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Algo salió mal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estamos trabajando para resolverlo. Si el problema persiste, '
                'cierra y vuelve a abrir la app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
