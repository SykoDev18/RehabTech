import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builders for `go_router` `CustomTransitionPage`s.
///
/// Use these on routes where the platform default doesn't match the desired
/// feel — auth flows usually want a soft fade, and profile sub-screens read
/// better with a slide from the right on both Android and iOS.
class TransitionHelper {
  TransitionHelper._();

  static Page<T> fade<T>({required Widget child, LocalKey? key}) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Page<T> slideFromRight<T>({required Widget child, LocalKey? key}) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  static Page<T> scaleFade<T>({required Widget child, LocalKey? key}) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
