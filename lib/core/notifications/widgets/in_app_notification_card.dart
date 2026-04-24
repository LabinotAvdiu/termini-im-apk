import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../models/in_app_notification.dart';

// ---------------------------------------------------------------------------
// InAppNotificationCard
// ---------------------------------------------------------------------------

/// Card animée d'une notification in-app.
///
/// Gère :
/// - Slide-in + fade-in à l'entrée (direction configurable).
/// - Progress bar de countdown.
/// - MouseRegion pour pause hover (desktop).
/// - Dismissible pour swipe (mobile).
/// - Tap → callback [onTap] + dismiss.
class InAppNotificationCard extends StatefulWidget {
  const InAppNotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onPause,
    this.onResume,
    this.slideFromTop = false,
  });

  final InAppNotification notification;

  /// Appelé quand l'utilisateur dismiss ou que le card est tapé.
  final VoidCallback onDismiss;

  /// Appelé quand le pointeur entre dans la card (hover desktop). Doit
  /// annuler le Timer d'auto-dismiss côté provider — sans ça, la card
  /// disparaît malgré la progress bar en pause.
  final VoidCallback? onPause;

  /// Appelé quand le pointeur sort. Doit reprogrammer le Timer.
  final VoidCallback? onResume;

  /// Si `true`, l'entrée vient du haut (mobile). Sinon de la droite (desktop).
  final bool slideFromTop;

  @override
  State<InAppNotificationCard> createState() => _InAppNotificationCardState();
}

class _InAppNotificationCardState extends State<InAppNotificationCard>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Progress bar — démarre à 1.0, finit à 0.0 sur la durée de la notif.
  late final AnimationController _progressCtrl;
  bool _paused = false;

  @override
  void initState() {
    super.initState();

    // ── Entrée (slide + fade) ────────────────────────────────────────────
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    );

    final slideBegin = widget.slideFromTop
        ? const Offset(0, -0.6)
        : const Offset(1.0, 0);

    _slideAnim = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    ));

    _ctrl.forward();

    // ── Progress bar ─────────────────────────────────────────────────────
    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.notification.duration,
      value: 1.0,
    )..animateTo(0.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // ── Slide-out puis dismiss ────────────────────────────────────────────────

  Future<void> _animateDismiss() async {
    _progressCtrl.stop();
    await _ctrl.reverse();
    widget.onDismiss();
  }

  // ── Hover ────────────────────────────────────────────────────────────────

  void _onHoverEnter() {
    if (_paused) return;
    _paused = true;
    _progressCtrl.stop();
    // Coupe aussi le Timer côté provider — sinon le dismiss fire malgré la
    // progress bar pausée visuellement.
    widget.onPause?.call();
  }

  void _onHoverExit() {
    if (!_paused) return;
    _paused = false;
    // Reprogramme le Timer côté provider avec le temps restant (basé sur la
    // position actuelle du progressCtrl : 1.0 = pleine durée, 0.0 = fini).
    final remaining = Duration(
      milliseconds:
          (widget.notification.duration.inMilliseconds * _progressCtrl.value)
              .round(),
    );
    widget.onResume?.call();
    _progressCtrl.animateTo(
      0.0,
      duration: remaining,
    );
  }

  // ── Colors helpers ────────────────────────────────────────────────────────

  Color get _accentColor => switch (widget.notification.variant) {
        InAppNotificationVariant.positive => AppColors.secondary,
        InAppNotificationVariant.info => AppColors.primary,
        InAppNotificationVariant.attention => AppColors.primaryDark,
      };

  Color get _iconBgColor => switch (widget.notification.variant) {
        InAppNotificationVariant.positive =>
          const Color(0xFFC89B47).withValues(alpha: 0.14),
        InAppNotificationVariant.info =>
          const Color(0xFF7A2232).withValues(alpha: 0.09),
        InAppNotificationVariant.attention =>
          const Color(0xFF7A2232).withValues(alpha: 0.15),
      };

  Color get _cardBgColor => switch (widget.notification.variant) {
        InAppNotificationVariant.positive => AppColors.surface,
        InAppNotificationVariant.info => AppColors.surface,
        InAppNotificationVariant.attention => AppColors.background,
      };

  double get _leftBorderWidth =>
      widget.notification.variant == InAppNotificationVariant.attention
          ? 4.0
          : 3.0;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: MouseRegion(
          onEnter: (_) => _onHoverEnter(),
          onExit: (_) => _onHoverExit(),
          child: Dismissible(
            key: ValueKey(widget.notification.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => widget.onDismiss(),
            background: const SizedBox.shrink(),
            child: GestureDetector(
              onTap: () {
                widget.notification.onTap?.call();
                _animateDismiss();
              },
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    // NB : Flutter Web ne supporte pas `borderRadius` combiné à des couleurs
    // de bordure non-uniformes (crash au paint). On pose donc une bordure
    // uniforme + un overlay rectangulaire bordeaux à gauche pour l'accent.
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.09),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: _buildContent(),
        ),
        // Accent vertical à gauche — overlay plutôt que border-left.
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: Container(
            width: _leftBorderWidth,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main content row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.notification.icon,
                    size: 18,
                    color: _accentColor,
                  ),
                ),

                const SizedBox(width: 10),

                // Title + body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.notification.body,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          color: AppColors.textHint,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // CTA uniquement pour les variantes positives
                      if (widget.notification.variant ==
                          InAppNotificationVariant.positive) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Voir →',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: _animateDismiss,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.textHint.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _progressCtrl,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: 2,
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          width: double.infinity,
                          color: _accentColor.withValues(alpha: 0.10),
                        ),
                        // Fill
                        Container(
                          width: constraints.maxWidth * _progressCtrl.value,
                          color: _accentColor.withValues(alpha: 0.65),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
    );
  }
}
