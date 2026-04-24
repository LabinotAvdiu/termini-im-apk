import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_brand_wordmark.dart';

// ---------------------------------------------------------------------------
// AppTopBar — barre universelle Termini Im
//
// Cinq constructeurs nommés couvrant toutes les catégories de routes :
//   • standard  — écrans standalone avec titre + back
//   • shell     — shell authentifié (wordmark ou titre selon le tab)
//   • modal     — fullscreen bottom-sheet (close X + titre centré)
//   • minimal   — auth (pas de titre, back discret)
//   • asSliver  — retourne un SliverAppBar hero/transparent (≠ PreferredSizeWidget)
//
// Toutes les variantes partagent [_CircleIconButton] pour les boutons back/close.
// ---------------------------------------------------------------------------

/// Hauteur standard de la barre.
const double _kBarHeight = 64.0;

// ---------------------------------------------------------------------------
// Widget principal — PreferredSizeWidget pour Scaffold.appBar
// ---------------------------------------------------------------------------

/// AppBar universelle Termini Im.
///
/// Utilise l'un des cinq constructeurs nommés selon la catégorie de la route.
/// Implémente [PreferredSizeWidget] pour être utilisée comme `Scaffold.appBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  // ── Champs internes ───────────────────────────────────────────────────────

  final _AppTopBarVariant _variant;

  // standard / standalone
  final String? _title;
  final String? _subtitle;
  final VoidCallback? _onBack;
  final VoidCallback? _onClose;
  final List<Widget>? _actions;

  // shell
  final Widget? _leading;
  final List<Widget>? _trailing;

  // ── Constructeurs nommés ──────────────────────────────────────────────────

  /// Écrans standalone : back + titre Fraunces h3 + actions optionnelles.
  ///
  /// Le bouton back apparaît si [onBack] est fourni OU si [Navigator.canPop].
  const AppTopBar.standard({
    super.key,
    required String title,
    VoidCallback? onBack,
    List<Widget>? actions,
  })  : _variant = _AppTopBarVariant.standard,
        _title = title,
        _subtitle = null,
        _onBack = onBack,
        _onClose = null,
        _actions = actions,
        _leading = null,
        _trailing = null;

  /// Shell authentifié : wordmark (ou titre) à gauche + actions à droite.
  ///
  /// Si [title] est fourni, il remplace le wordmark (pour les tabs non-home
  /// qui vivent dans le shell sans bouton back).
  /// [leading] personnalise le widget gauche (défaut : [AppBrandWordmark]).
  const AppTopBar.shell({
    super.key,
    String? title,
    Widget? leading,
    List<Widget>? trailing,
  })  : _variant = _AppTopBarVariant.shell,
        _title = title,
        _subtitle = null,
        _onBack = null,
        _onClose = null,
        _actions = null,
        _leading = leading,
        _trailing = trailing;

  /// Modal fullscreen (slide-from-bottom) : close X à gauche, titre centré.
  ///
  /// [subtitle] optionnel pour l'indicateur d'étape ("Étape 2 / 3").
  const AppTopBar.modal({
    super.key,
    required String title,
    VoidCallback? onClose,
    String? subtitle,
  })  : _variant = _AppTopBarVariant.modal,
        _title = title,
        _subtitle = subtitle,
        _onBack = null,
        _onClose = onClose,
        _actions = null,
        _leading = null,
        _trailing = null;

  /// Auth flows : fond transparent, back discret si canPop, pas de titre.
  ///
  /// [trailing] : liste optionnelle de widgets à droite (ex: sélecteur de langue).
  const AppTopBar.minimal({
    super.key,
    VoidCallback? onBack,
    List<Widget>? trailing,
  })  : _variant = _AppTopBarVariant.minimal,
        _title = null,
        _subtitle = null,
        _onBack = onBack,
        _onClose = null,
        _actions = null,
        _leading = null,
        _trailing = trailing;

  // ── PreferredSizeWidget ───────────────────────────────────────────────────

  @override
  Size get preferredSize {
    final subtitle = _subtitle;
    final extraHeight = (_variant == _AppTopBarVariant.modal &&
            subtitle != null &&
            subtitle.isNotEmpty)
        ? 12.0
        : 0.0;
    // Toutes les variantes hors minimal rendent un Divider de 1px en bas.
    final dividerHeight =
        _variant == _AppTopBarVariant.minimal ? 0.0 : 1.0;
    return Size.fromHeight(_kBarHeight + extraHeight + dividerHeight);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _AppTopBarVariant.standard => _buildStandard(context),
      _AppTopBarVariant.shell => _buildShell(context),
      _AppTopBarVariant.modal => _buildModal(context),
      _AppTopBarVariant.minimal => _buildMinimal(context),
    };
  }

  // ── Standard ──────────────────────────────────────────────────────────────

  Widget _buildStandard(BuildContext context) {
    // Les écrans standalone ont toujours un back. Si la route a été atteinte
    // via `context.go` (replace), `Navigator.canPop` est faux — on utilise
    // alors `GoRouter.canPop` pour pop la stack logique GoRouter.
    return _BarContainer(
      height: _kBarHeight,
      color: AppColors.surface,
      withBottomDivider: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _onBack ?? () => _defaultPop(context),
            semanticsLabel: 'Retour',
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _title ?? '',
              style: AppTextStyles.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_actions case final actions?) ...actions,
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }

  // ── Shell ─────────────────────────────────────────────────────────────────

  Widget _buildShell(BuildContext context) {
    Widget leftWidget;
    final leading = _leading;
    final title = _title;
    if (leading != null) {
      leftWidget = leading;
    } else if (title != null) {
      leftWidget = Text(title, style: AppTextStyles.h3, maxLines: 1);
    } else {
      leftWidget = const AppBrandWordmark(fontSize: 22);
    }

    return _BarContainer(
      height: _kBarHeight,
      color: AppColors.surface,
      withBottomDivider: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: AppSpacing.md),
          leftWidget,
          const Spacer(),
          if (_trailing case final trailing?) ...trailing,
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }

  // ── Modal ─────────────────────────────────────────────────────────────────

  Widget _buildModal(BuildContext context) {
    final modalSubtitle = _subtitle;
    final hasSubtitle = modalSubtitle != null && modalSubtitle.isNotEmpty;
    final height = _kBarHeight + (hasSubtitle ? 12.0 : 0.0);

    return _BarContainer(
      height: height,
      color: AppColors.surface,
      withBottomDivider: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Titre + sous-titre centrés
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _title ?? '',
                style: AppTextStyles.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (modalSubtitle != null && modalSubtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  modalSubtitle,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                ),
              ],
            ],
          ),

          // Close X à gauche, ne pousse pas le titre
          Positioned(
            left: AppSpacing.sm,
            child: _CircleIconButton(
              icon: Icons.close_rounded,
              onTap: _onClose ?? () => _defaultPop(context),
              semanticsLabel: 'Fermer',
            ),
          ),
        ],
      ),
    );
  }

  // ── Minimal ───────────────────────────────────────────────────────────────

  Widget _buildMinimal(BuildContext context) {
    final canGoBack = _onBack != null ||
        Navigator.of(context).canPop() ||
        GoRouter.of(context).canPop();

    return _BarContainer(
      height: _kBarHeight,
      color: Colors.transparent,
      withBottomDivider: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canGoBack)
            _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: _onBack ?? () => _defaultPop(context),
              semanticsLabel: 'Retour',
            )
          else
            const SizedBox(width: _kBarHeight),
          const Spacer(),
          if (_trailing case final trailing?) ...trailing,
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _defaultPop — fallback robuste Navigator + GoRouter
//
// Si la route a été atteinte via `context.go` (replace), `Navigator.canPop`
// est faux alors que la stack GoRouter peut encore pop. On essaie les deux
// mécanismes dans l'ordre avant de laisser un no-op.
// ---------------------------------------------------------------------------
void _defaultPop(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
    return;
  }
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  }
}

// ---------------------------------------------------------------------------
// SliverAppBar hero/transparent — retourné par AppTopBar.asSliver(...)
//
// N'implémente PAS PreferredSizeWidget : à placer dans un [CustomScrollView].
// ---------------------------------------------------------------------------

/// Factory qui produit un [SliverAppBar] hero transparent pour [CompanyDetailScreenMobile].
///
/// Le fond passe de transparent à [AppColors.surface] quand l'image hero
/// disparaît sous la barre. Le titre est invisible en mode expanded et apparaît
/// en mode collapsed.
class AppTopBarSliver extends StatelessWidget {
  /// Hauteur totale de la zone hero expandée (ex: 280 px pour l'image salon).
  final double heroExtent;

  /// Titre affiché uniquement en mode collapsed (scroll).
  final String? title;

  /// Actions à droite (favoris, partage…).
  final List<Widget>? actions;

  /// Back button — fond ivoire 85 % avec ombre douce pour lisibilité sur photo.
  final VoidCallback? onBack;

  const AppTopBarSliver({
    super.key,
    required this.heroExtent,
    this.title,
    this.actions,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Ce widget doit être construit dans un SliverAppBar. On le délègue
    // directement — l'appelant place le widget dans son CustomScrollView.
    return _HeroSliverAppBar(
      heroExtent: heroExtent,
      title: title,
      actions: actions,
      onBack: onBack,
    );
  }
}

class _HeroSliverAppBar extends StatefulWidget {
  final double heroExtent;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const _HeroSliverAppBar({
    required this.heroExtent,
    this.title,
    this.actions,
    this.onBack,
  });

  @override
  State<_HeroSliverAppBar> createState() => _HeroSliverAppBarState();
}

class _HeroSliverAppBarState extends State<_HeroSliverAppBar> {
  // Pas de ScrollController ici : SliverAppBar gère le pinned/floating.
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: widget.heroExtent,
      pinned: true,
      floating: false,
      backgroundColor: AppColors.surface,
      // Empêche le tint Material 3 en mode scrolledUnder
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.cardShadow,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      leading: _CircleIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
        semanticsLabel: 'Retour',
        // Pastille ivoire légèrement opaque pour lisibilité sur photo
        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
        withShadow: true,
      ),
      title: widget.title != null
          ? Text(widget.title!, style: AppTextStyles.h3, maxLines: 1)
          : null,
      actions: widget.actions,
    );
  }
}

// ---------------------------------------------------------------------------
// _BarContainer — conteneur commun avec SafeArea top + divider optionnel
// ---------------------------------------------------------------------------

class _BarContainer extends StatelessWidget {
  final double height;
  final Color color;
  final bool withBottomDivider;
  final Widget child;

  const _BarContainer({
    required this.height,
    required this.color,
    required this.withBottomDivider,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zone de statut
          SizedBox(height: topPadding),
          // Contenu de la barre
          SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: child,
            ),
          ),
          // Divider bas
          if (withBottomDivider)
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CircleIconButton — bouton rond partagé (back et close)
// ---------------------------------------------------------------------------

/// Bouton icône rond 36×36 utilisé pour tous les back/close de l'app.
///
/// Fond [AppColors.surface] à 90 % d'opacité par défaut, ombre très discrète
/// si [withShadow] est vrai (mode hero transparent).
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;
  final Color? backgroundColor;
  final bool withShadow;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.backgroundColor,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surface.withValues(alpha: 0.9);

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: withShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Enum interne
// ---------------------------------------------------------------------------

enum _AppTopBarVariant { standard, shell, modal, minimal }
