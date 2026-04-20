import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/brand_logo.dart';

// ---------------------------------------------------------------------------
// Layout rationale — Option B, split-screen éditorial :
//
// Panneau gauche (40 % de la largeur, fond bordeaux dégradé) : identité de
// marque — logo, overline, titre display Fraunces en grand, sous-titre.
// Ce côté ne bouge pas ; il porte la personnalité de Termini im.
//
// Panneau droit (60 %, ivoire) : action — les deux cartes de rôle centrées
// verticalement, avec interactions hover riches.
//
// Un arc SVG or (`_GoldArcDivider`) sépare les deux panneaux côté droit du
// panneau gauche, donnant du relief sans bord droit brutalement coupé.
//
// Ce split est cohérent avec les conventions des apps booking premium
// (Fresha, Treatwell, Vagaro) sur desktop : la marque à gauche capte l'œil
// en premier (lecture Z), l'action à droite est accessible immédiatement.
// ---------------------------------------------------------------------------

class RoleSelectionScreenDesktop extends ConsumerWidget {
  const RoleSelectionScreenDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ---- Left editorial panel (brand identity) ----
          Expanded(
            flex: 40,
            child: _LeftPanel(),
          ),

          // ---- Right action panel (role cards) ----
          Expanded(
            flex: 60,
            child: _RightPanel(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left panel — bordeaux gradient, logo, Fraunces display title
// ---------------------------------------------------------------------------
class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF511522),
                  Color(0xFF7A2232),
                  Color(0xFF9E3D4F),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // Decorative large monogram watermark — opacité très faible pour
        // donner de la profondeur sans surcharger.
        Positioned(
          bottom: -40,
          right: -60,
          child: Opacity(
            opacity: 0.06,
            child: BrandLogo(
              variant: BrandLogoVariant.ivory,
              size: 360,
            ),
          ),
        ),

        // Arc divider painted on the right edge (clips into the right panel)
        Positioned(
          right: -1,
          top: 0,
          bottom: 0,
          child: CustomPaint(
            size: const Size(48, double.infinity),
            painter: _ArcEdgePainter(),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + brand name
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: BrandLogo(
                          variant: BrandLogoVariant.ivory,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Termini im',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Overline éditoriale — numéro de section façon magazine
                Text(
                  '01 — Profil',
                  style: GoogleFonts.fraunces(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondary.withValues(alpha: 0.85),
                    letterSpacing: 3.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Titre display en deux lignes — le plus grand élément
                // typographique de l'écran, ancre visuelle principale.
                Text(
                  context.l10n.chooseRoleSubtitle,
                  style: GoogleFonts.fraunces(
                    fontSize: 52,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: -1.5,
                    height: 1.08,
                  ),
                ),

                const SizedBox(height: 24),

                // Sous-titre corps
                Text(
                  context.l10n.chooseRole,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 2),

                // Login link en bas du panel gauche — discret, blanc
                _DesktopLoginLink(onDarkBackground: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Right panel — ivoire, les deux cartes de rôle centrées
// ---------------------------------------------------------------------------
class _RightPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Limite la largeur des cartes pour qu'elles ne s'étirent pas
            // sur un viewport ultra-large — plaisir visuel maintenu à 1440+.
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DesktopRoleCard(
                    editorialNumber: '01',
                    icon: Icons.person_rounded,
                    title: context.l10n.iAmUser,
                    subtitle: context.l10n.iAmUserSubtitle,
                    role: 'user',
                    // Carte ivoire avec accent or — le client est le profil
                    // "lumineux", positif, accessible. L'or évoque la qualité
                    // des prestations beauté.
                    cardBackground: AppColors.surface,
                    accentColor: AppColors.secondary,
                    numberColor: AppColors.secondary,
                  ),

                  const SizedBox(height: 20),

                  _DesktopRoleCard(
                    editorialNumber: '02',
                    icon: Icons.storefront_rounded,
                    title: context.l10n.iAmCompany,
                    subtitle: context.l10n.iAmCompanySubtitle,
                    role: 'company',
                    // Carte bordeaux pour le professionnel — autorité,
                    // expertise, contraste marqué avec la carte client
                    // pour faciliter la discrimination visuelle.
                    cardBackground: AppColors.primary,
                    accentColor: AppColors.secondary,
                    numberColor: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte de rôle desktop avec hover riche
// ---------------------------------------------------------------------------
class _DesktopRoleCard extends StatefulWidget {
  final String editorialNumber;
  final IconData icon;
  final String title;
  final String subtitle;
  final String role;
  final Color cardBackground;
  final Color accentColor;
  final Color numberColor;

  const _DesktopRoleCard({
    required this.editorialNumber,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.cardBackground,
    required this.accentColor,
    required this.numberColor,
  });

  @override
  State<_DesktopRoleCard> createState() => _DesktopRoleCardState();
}

class _DesktopRoleCardState extends State<_DesktopRoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _elevationAnim;
  late final Animation<double> _translateYAnim;
  late final Animation<double> _arrowOffsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Translation Y: 0 → -4px
    _translateYAnim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Box shadow blur: 8 → 28 (via un proxy 0→1)
    _elevationAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Flèche glisse de 0 → 6px vers la droite au hover
    _arrowOffsetAnim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(_) => _controller.forward();

  void _onExit(_) => _controller.reverse();

  // Dérive les couleurs texte selon le fond de la carte
  bool get _isDark =>
      widget.cardBackground == AppColors.primary ||
      widget.cardBackground.computeLuminance() < 0.2;

  Color get _titleColor => _isDark ? Colors.white : AppColors.textPrimary;

  Color get _subtitleColor => _isDark
      ? Colors.white.withValues(alpha: 0.65)
      : AppColors.textHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.title}. ${widget.subtitle}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: _onEnter,
        onExit: _onExit,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final blur = 8 + _elevationAnim.value * 20;
            final shadowOpacity = 0.10 + _elevationAnim.value * 0.14;
            final shadowOffset = 4.0 + _elevationAnim.value * 8;

            return Transform.translate(
              offset: Offset(0, _translateYAnim.value),
              child: GestureDetector(
                onTap: () {
                  final returnTo = GoRouterState.of(context)
                      .uri
                      .queryParameters['returnTo'];
                  context.goNamed(
                    RouteNames.signup,
                    queryParameters: {
                      'role': widget.role,
                      if (returnTo != null && returnTo.isNotEmpty)
                        'returnTo': returnTo,
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.cardBackground,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: _isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark
                            .withValues(alpha: shadowOpacity),
                        blurRadius: blur,
                        offset: Offset(0, shadowOffset),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Numéro éditorial + icône ----
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Numéro façon magazine — opacité or faible,
                            // ambiance revue de mode plutôt qu'app générique.
                            Text(
                              widget.editorialNumber,
                              style: GoogleFonts.fraunces(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: widget.numberColor
                                    .withValues(alpha: 0.55),
                                letterSpacing: 1.5,
                              ),
                            ),

                            const Spacer(),

                            // Médaillon icône
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.accentColor
                                    .withValues(alpha: _isDark ? 0.18 : 0.12),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.accentColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ---- Titre Fraunces ----
                        Text(
                          widget.title,
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: _titleColor,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ---- Sous-titre corps ----
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: _subtitleColor,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ---- CTA — "Continuer" + flèche animée ----
                        Row(
                          children: [
                            Text(
                              context.l10n.continueLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isDark
                                    ? widget.accentColor
                                    : AppColors.primary,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(width: 6),

                            // Flèche qui glisse vers la droite au hover
                            Transform.translate(
                              offset:
                                  Offset(_arrowOffsetAnim.value, 0),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: _isDark
                                    ? widget.accentColor
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lien de connexion (partagé entre les deux variantes d'emplacement)
// ---------------------------------------------------------------------------
class _DesktopLoginLink extends StatefulWidget {
  final bool onDarkBackground;

  const _DesktopLoginLink({required this.onDarkBackground});

  @override
  State<_DesktopLoginLink> createState() => _DesktopLoginLinkState();
}

class _DesktopLoginLinkState extends State<_DesktopLoginLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.onDarkBackground
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.textHint;
    final linkColor =
        widget.onDarkBackground ? Colors.white : AppColors.primary;

    return Row(
      children: [
        Text(
          '${context.l10n.alreadyHaveAccount} ',
          style: TextStyle(fontSize: 13, color: baseColor),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => context.goNamed(RouteNames.login),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: linkColor,
                decoration: _hovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: linkColor,
              ),
              child: Text(context.l10n.loginNow),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Arc doré sur le bord droit du panneau bordeaux — crée une séparation
// organique et premium entre les deux panneaux, évite la coupure brutale
// d'un bord vertical simple. L'arc est convexe vers la gauche (bordeaux)
// et concave vers la droite (ivoire).
// ---------------------------------------------------------------------------
class _ArcEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Or semi-transparent pour un séparateur délicat
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      // Courbe de Bézier : l'arc part du coin haut-gauche, bombe à droite
      // au milieu de la hauteur, et revient au coin bas-gauche.
      ..cubicTo(
        size.width * 2,
        size.height * 0.25,
        size.width * 2,
        size.height * 0.75,
        0,
        size.height,
      )
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Fine ligne or sur le bord de l'arc pour le définir
    final strokePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final strokePath = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        size.width * 2,
        size.height * 0.25,
        size.width * 2,
        size.height * 0.75,
        0,
        size.height,
      );

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(_ArcEdgePainter oldDelegate) => false;
}

