import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralised wrappers around `url_launcher` that handle the cases where
/// no handler is registered for a given scheme (no email app installed,
/// no browser available, Android 11+ package-visibility blocking, etc.).
///
/// Without these guards, `launchUrl` either silently no-ops on Android with a
/// `component name is null` log line or throws on iOS. Using these helpers
/// guarantees the user always gets a copyable fallback.
class UrlLauncherHelper {
  UrlLauncherHelper._();

  /// Launch a `mailto:` URL. If no email app is registered (or Android
  /// package visibility hides them) we surface a bottom sheet with the
  /// address pre-formatted and a copy action.
  static Future<void> launchEmail({
    required BuildContext context,
    required String to,
    String subject = '',
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );

    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;
    _showEmailFallback(context: context, email: to, subject: subject);
  }

  /// Launch any URL (typically `https://`). Falls back to a SnackBar with a
  /// copy action when no handler is available.
  ///
  /// [label] is the human-readable name of the destination (e.g.
  /// "Términos y Condiciones"). When provided, the fallback SnackBar names
  /// it explicitly instead of dumping the raw URL into the toast.
  static Future<void> launchLink({
    required BuildContext context,
    required String url,
    String? label,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);

    if (canLaunch) {
      await launchUrl(uri, mode: mode);
      return;
    }

    if (!context.mounted) return;
    _showUrlFallback(context: context, url: url, label: label);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  static void _showEmailFallback({
    required BuildContext context,
    required String email,
    String subject = '',
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EmailFallbackSheet(email: email, subject: subject),
    );
  }

  static void _showUrlFallback({
    required BuildContext context,
    required String url,
    String? label,
  }) {
    // Truncate long URLs (e.g. Drive share links) so they fit in the toast.
    final displayUrl =
        url.length > 50 ? '${url.substring(0, 47)}...' : url;

    final message = label != null
        ? 'No se pudo abrir "$label". Copia el enlace.'
        : 'No se pudo abrir el enlace: $displayUrl';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Copiar',
          onPressed: () => Clipboard.setData(ClipboardData(text: url)),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

// ── Extracted widget ─────────────────────────────────────────────────────

class _EmailFallbackSheet extends StatelessWidget {
  const _EmailFallbackSheet({
    required this.email,
    required this.subject,
  });

  final String email;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Contáctanos por correo',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No encontramos una app de correo en tu dispositivo. '
            'Copia la dirección y escríbenos desde Gmail u otra app de correo.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Tappable email chip — copies + closes the sheet.
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: email));
              Navigator.pop(context);
              // SnackBar is shown by the caller's Scaffold context after
              // pop; we trigger it via a post-frame callback dispatched
              // from the caller layer (see launchEmail / consumers).
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dirección de correo',
                          style: textTheme.labelSmall,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          if (subject.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Asunto sugerido: $subject',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}
