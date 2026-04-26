import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Full-screen "¡Excelente trabajo!" celebration shown right after a
/// session completes. Auto-dismisses after [displayDuration] so the caller
/// can follow up with the pain prompt.
///
/// Use [CompletionCelebration.show] from your screen — this widget is not
/// designed to be inserted directly into a build tree.
class CompletionCelebration extends StatefulWidget {
  const CompletionCelebration({
    super.key,
    required this.exercisesCompleted,
    required this.durationSeconds,
    this.displayDuration = const Duration(milliseconds: 2000),
  });

  final int exercisesCompleted;
  final int durationSeconds;
  final Duration displayDuration;

  /// Shows the celebration as a non-dismissible dialog and resolves once it
  /// has auto-closed. Safe to `await` before opening the next screen/dialog.
  static Future<void> show(
    BuildContext context, {
    required int exercisesCompleted,
    required int durationSeconds,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => CompletionCelebration(
        exercisesCompleted: exercisesCompleted,
        durationSeconds: durationSeconds,
      ),
    );
  }

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration> {
  late final ConfettiController _controller;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.displayDuration);
    _controller.play();
    _autoDismiss = Timer(widget.displayDuration, () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirection: pi / 2,
              maxBlastForce: 18,
              minBlastForce: 8,
              emissionFrequency: 0.06,
              numberOfParticles: 24,
              gravity: 0.25,
              colors: const [
                Color(0xFF2563EB),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
                Color(0xFFEF4444),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.partyPopper,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Excelente trabajo!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      icon: LucideIcons.dumbbell,
                      label: 'Repeticiones',
                      value: '${widget.exercisesCompleted}',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade200,
                    ),
                    _Stat(
                      icon: LucideIcons.timer,
                      label: 'Duración',
                      value: _formatDuration(widget.durationSeconds),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF2563EB)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
