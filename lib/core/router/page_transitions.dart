/// Editorial page transitions — cohérentes avec l'esthétique Prishtina.
///
/// Deux helpers:
///   - [editorialFadeRoute] : fondu 260ms — routes modales, login, auth prompts.
///   - [editorialSlideRoute] : slide léger (8% offset) + fade, 280ms —
///     navigation standard d'une écran vers un autre.
///
/// Pour GoRouter : utiliser [editorialFadePage] / [editorialSlidePage]
/// qui retournent [CustomTransitionPage].
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Shared curve
// ---------------------------------------------------------------------------

const _kEditorialCurve = Curves.easeOutCubic;

// ---------------------------------------------------------------------------
// MaterialPageRoute helpers (pour les push() impératifs)
// ---------------------------------------------------------------------------

/// Fondu 260ms — idéal pour les routes modales (login, lightbox, auth prompt).
Route<T> editorialFadeRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: _kEditorialCurve),
        child: child,
      );
    },
  );
}

/// Slide léger (8% offset) + fade, 280ms.
/// [fromBottom] : true pour les sheets montant du bas.
Route<T> editorialSlideRoute<T>(Widget child, {bool fromBottom = false}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: _kEditorialCurve);

      final begin = fromBottom
          ? const Offset(0.0, 0.08)
          : const Offset(0.08, 0.0);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// CustomTransitionPage helpers (pour GoRouter pageBuilder:)
// ---------------------------------------------------------------------------

/// [CustomTransitionPage] avec fondu 260ms — pour GoRouter.
CustomTransitionPage<T> editorialFadePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: _kEditorialCurve),
        child: child,
      );
    },
  );
}

/// [CustomTransitionPage] avec slide + fade, 280ms — pour GoRouter.
CustomTransitionPage<T> editorialSlidePage<T>({
  required LocalKey key,
  required Widget child,
  bool fromBottom = false,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: _kEditorialCurve);
      final begin =
          fromBottom ? const Offset(0.0, 0.08) : const Offset(0.08, 0.0);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
