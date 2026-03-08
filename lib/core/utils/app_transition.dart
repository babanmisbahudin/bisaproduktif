import 'package:flutter/material.dart';

/// Custom page transitions untuk seluruh navigasi BisaProduktif.
/// Konsisten: slide dari kanan + fade ringan (feel modern & smooth).
class AppTransition {
  // ── Slide from Right (standar push screen) ────────────────────────────────

  static Route<T> slideRight<T>({required Widget child}) {
    return _AppPageRoute<T>(
      child: child,
      beginOffset: const Offset(1.0, 0.0),
    );
  }

  // ── Slide from Bottom (add/edit form, detail) ─────────────────────────────

  static Route<T> slideUp<T>({required Widget child}) {
    return _AppPageRoute<T>(
      child: child,
      beginOffset: const Offset(0.0, 1.0),
      duration: const Duration(milliseconds: 360),
    );
  }

  // ── Fade saja (onboarding, transisi halus) ────────────────────────────────

  static Route<T> fade<T>({required Widget child}) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => child,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, _, ch) =>
          FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: ch),
    );
  }

  // ── go_router CustomTransitionPage builders ───────────────────────────────

  /// Dipakai oleh go_router: slide kanan + fade
  static Widget slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.6)));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  /// Dipakai oleh go_router: fade saja
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

// ── Internal helper ────────────────────────────────────────────────────────

class _AppPageRoute<T> extends PageRouteBuilder<T> {
  _AppPageRoute({
    required Widget child,
    required Offset beginOffset,
    Duration duration = const Duration(milliseconds: 320),
  }) : super(
          pageBuilder: (_, _, _) => child,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (_, animation, _, ch) {
            final slide = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
              ),
            );

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: ch),
            );
          },
        );
}
