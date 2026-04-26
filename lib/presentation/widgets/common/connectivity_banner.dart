import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../services/connectivity_service.dart';

/// Slim banner that appears at the top of the screen when the device loses
/// connectivity. Subscribes to [ConnectivityService] directly — drop it into
/// the app shell once and it manages itself.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().isOnline,
      // Optimistic default: assume online until first probe arrives.
      initialData: ConnectivityService().isCurrentlyOnline,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: online
              ? const SizedBox.shrink()
              : const _OfflineBanner(key: ValueKey('offline')),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFFBBF24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFF78350F)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Sin conexión — los cambios se sincronizarán al reconectar',
                style: TextStyle(
                  color: Color(0xFF78350F),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
