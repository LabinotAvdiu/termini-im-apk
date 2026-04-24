import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// AppCard — charte graphique unifiée des blocs Termini Im
//
// Six constructeurs nommés couvrant toutes les familles de blocs :
//   • section    — carte principale : pastille icône + titre h3 + child libre
//   • list       — même chrome que section, body = liste d'items avec dividers
//   • action     — ligne cliquable compact : icône + titre + sous-titre + chevron
//   • toggle     — ligne Switch : icône + label + sous-texte + Switch
//   • info       — bannière informative non-cliquable (neutral / accent / warning)
//   • destructive— zone danger : fond teinté, titre, CTA outline destructif
//
// Toutes les variantes partagent [_CardShell] (padding / radius / fond /
// bordure / ombre) et [_CardHeader] (pastille icône + titre + sous-titre +
// trailing).  Un seul style d'icône dans toute la famille : icône outlined
// Material, 20 px, couleur [AppColors.textPrimary], dans une pastille ronde
// 40×40 fond [AppColors.ivoryAlt].
// ---------------------------------------------------------------------------

// ── Enum variant interne ────────────────────────────────────────────────────

enum _AppCardVariant { section, list, action, toggle, info, destructive }

// ── Enum info variant ───────────────────────────────────────────────────────

/// Tonalité visuelle de [AppCard.info].
enum AppCardInfoVariant {
  /// Fond sable neutre — information secondaire sans urgence.
  neutral,

  /// Fond bourgogne très clair — met en valeur un contexte lié à l'action
  /// principale de l'écran.
  accent,

  /// Fond or clair — alerte ou avertissement doux.
  warning,
}

// ---------------------------------------------------------------------------
// Widget principal
// ---------------------------------------------------------------------------

/// Bloc de carte normé Termini Im.
///
/// Utilise l'un des six constructeurs nommés selon le cas d'usage.
///
/// ```dart
/// // Carte principale avec contenu libre
/// AppCard.section(
///   title: 'Services & catégories',
///   icon: Icons.content_cut_rounded,
///   trailing: IconButton(icon: Icon(Icons.add_rounded), onPressed: onAdd),
///   child: MyServicesWidget(),
/// )
///
/// // Toggle
/// AppCard.toggle(
///   title: 'Validation automatique',
///   icon: Icons.check_circle_outline_rounded,
///   subtitle: 'Approuve chaque réservation sans intervention.',
///   value: isEnabled,
///   onChanged: (v) => toggle(v),
/// )
/// ```
class AppCard extends StatelessWidget {
  // ── Champs internes ───────────────────────────────────────────────────────

  final _AppCardVariant _variant;

  // section / list
  final String? _title;
  final String? _subtitle;
  final IconData? _icon;
  final Widget? _trailing;
  final Widget? _child;
  final List<Widget>? _items;

  // action
  final VoidCallback? _onTap;
  final bool _showChevron;

  // toggle
  final bool _value;
  final ValueChanged<bool>? _onChanged;

  // info
  final AppCardInfoVariant _infoVariant;

  // destructive
  final String? _ctaLabel;
  final VoidCallback? _onCtaTap;

  // ── Constructeurs nommés ──────────────────────────────────────────────────

  /// Carte principale : pastille icône optionnelle + titre h3 + child libre.
  ///
  /// Cas typiques : Services & catégories, Horaires d'ouverture,
  /// Capacité & pauses, Informations du salon.
  const AppCard.section({
    super.key,
    required String title,
    IconData? icon,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  })  : _variant = _AppCardVariant.section,
        _title = title,
        _subtitle = subtitle,
        _icon = icon,
        _trailing = trailing,
        _child = child,
        _items = null,
        _onTap = null,
        _showChevron = false,
        _value = false,
        _onChanged = null,
        _infoVariant = AppCardInfoVariant.neutral,
        _ctaLabel = null,
        _onCtaTap = null;

  /// Carte liste : même chrome que [AppCard.section], body = colonne d'items
  /// automatiquement séparés par un divider [AppColors.divider] 0.5 px.
  ///
  /// Cas typiques : liste de pauses, liste de jours fériés.
  const AppCard.list({
    super.key,
    required String title,
    IconData? icon,
    String? subtitle,
    Widget? trailing,
    required List<Widget> items,
  })  : _variant = _AppCardVariant.list,
        _title = title,
        _subtitle = subtitle,
        _icon = icon,
        _trailing = trailing,
        _child = null,
        _items = items,
        _onTap = null,
        _showChevron = false,
        _value = false,
        _onChanged = null,
        _infoVariant = AppCardInfoVariant.neutral,
        _ctaLabel = null,
        _onCtaTap = null;

  /// Ligne cliquable compacte : pastille icône + titre + sous-titre + chevron.
  ///
  /// Cas typiques : entrées de navigation vers un sous-écran depuis Réglages
  /// ou Mon profil (Mes horaires, Mes pauses, etc.).
  const AppCard.action({
    super.key,
    required String title,
    required IconData icon,
    String? subtitle,
    bool showChevron = true,
    VoidCallback? onTap,
  })  : _variant = _AppCardVariant.action,
        _title = title,
        _subtitle = subtitle,
        _icon = icon,
        _trailing = null,
        _child = null,
        _items = null,
        _onTap = onTap,
        _showChevron = showChevron,
        _value = false,
        _onChanged = null,
        _infoVariant = AppCardInfoVariant.neutral,
        _ctaLabel = null,
        _onCtaTap = null;

  /// Ligne avec Switch : pastille icône + label + sous-texte + Switch.
  ///
  /// Cas typiques : Validation automatique, préférences de notifications.
  const AppCard.toggle({
    super.key,
    required String title,
    required IconData icon,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  })  : _variant = _AppCardVariant.toggle,
        _title = title,
        _subtitle = subtitle,
        _icon = icon,
        _trailing = null,
        _child = null,
        _items = null,
        _onTap = null,
        _showChevron = false,
        _value = value,
        _onChanged = onChanged,
        _infoVariant = AppCardInfoVariant.neutral,
        _ctaLabel = null,
        _onCtaTap = null;

  /// Bannière informative (non cliquable) : icône + texte.
  ///
  /// [variant] contrôle la tonalité : neutral / accent / warning.
  const AppCard.info({
    super.key,
    required String title,
    required IconData icon,
    String? subtitle,
    AppCardInfoVariant variant = AppCardInfoVariant.neutral,
  })  : _variant = _AppCardVariant.info,
        _title = title,
        _subtitle = subtitle,
        _icon = icon,
        _trailing = null,
        _child = null,
        _items = null,
        _onTap = null,
        _showChevron = false,
        _value = false,
        _onChanged = null,
        _infoVariant = variant,
        _ctaLabel = null,
        _onCtaTap = null;

  /// Zone danger : fond légèrement teinté bourgogne, titre, CTA outline.
  ///
  /// Cas typiques : suppression de compte, déconnexion confirmée.
  const AppCard.destructive({
    super.key,
    required String title,
    String? subtitle,
    String? ctaLabel,
    VoidCallback? onCtaTap,
  })  : _variant = _AppCardVariant.destructive,
        _title = title,
        _subtitle = subtitle,
        _icon = null,
        _trailing = null,
        _child = null,
        _items = null,
        _onTap = null,
        _showChevron = false,
        _value = false,
        _onChanged = null,
        _infoVariant = AppCardInfoVariant.neutral,
        _ctaLabel = ctaLabel,
        _onCtaTap = onCtaTap;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _AppCardVariant.section => _buildSection(),
      _AppCardVariant.list => _buildList(),
      _AppCardVariant.action => _buildAction(),
      _AppCardVariant.toggle => _buildToggle(),
      _AppCardVariant.info => _buildInfo(),
      _AppCardVariant.destructive => _buildDestructive(),
    };
  }

  // ── Section ───────────────────────────────────────────────────────────────

  Widget _buildSection() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _title ?? '',
            subtitle: _subtitle,
            icon: _icon,
            trailing: _trailing,
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
          _child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList() {
    final items = _items ?? [];
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _title ?? '',
            subtitle: _subtitle,
            icon: _icon,
            trailing: _trailing,
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
          if (items.isEmpty)
            const SizedBox.shrink()
          else
            Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.divider,
                      indent: AppSpacing.md,
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ── Action ────────────────────────────────────────────────────────────────

  Widget _buildAction() {
    final icon = _icon;
    final subtitle = _subtitle;
    return _CardShell(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (icon != null) _IconPill(icon: icon),
                if (icon != null) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title ?? '',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (_showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textHint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Toggle ────────────────────────────────────────────────────────────────

  Widget _buildToggle() {
    final icon = _icon;
    final subtitle = _subtitle;
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) _IconPill(icon: icon),
                if (icon != null) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _title ?? '',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _value,
                  onChanged: _onChanged,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.85),
                  inactiveThumbColor: AppColors.surface,
                  inactiveTrackColor: AppColors.border,
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: EdgeInsets.only(
                  left: icon != null ? 40.0 + AppSpacing.md : 0.0,
                ),
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Info ──────────────────────────────────────────────────────────────────

  Widget _buildInfo() {
    final (bg, iconColor, borderColor) = switch (_infoVariant) {
      AppCardInfoVariant.neutral => (
          AppColors.ivoryAlt,
          AppColors.textHint,
          AppColors.divider,
        ),
      AppCardInfoVariant.accent => (
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.20),
        ),
      AppCardInfoVariant.warning => (
          AppColors.warning.withValues(alpha: 0.10),
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.30),
        ),
    };

    final icon = _icon;
    final subtitle = _subtitle;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 20, color: iconColor),
          if (icon != null) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title ?? '',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w500, color: iconColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Destructive ───────────────────────────────────────────────────────────

  Widget _buildDestructive() {
    final title = _title;
    final subtitle = _subtitle;
    final ctaLabel = _ctaLabel;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
          ],
          if (ctaLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: _onCtaTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(ctaLabel, style: AppTextStyles.button),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CardShell — conteneur commun : fond ivory, radius 16, border divider 1 px,
// ombre très douce.
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// _CardHeader — pastille icône ronde 40×40 + titre h3 + sous-titre + trailing.
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const _CardHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = icon;
    final resolvedSubtitle = subtitle;
    final resolvedTrailing = trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (resolvedIcon != null) ...[
            _IconPill(icon: resolvedIcon),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.h3),
                if (resolvedSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(resolvedSubtitle, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          ?resolvedTrailing,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _IconPill — pastille ronde 40×40 fond ivoryAlt, icône 20 px textPrimary.
//
// Style unique pour toute la famille AppCard — ne jamais dériver inline.
// ---------------------------------------------------------------------------

class _IconPill extends StatelessWidget {
  final IconData icon;

  const _IconPill({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.ivoryAlt,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: AppColors.textPrimary,
      ),
    );
  }
}
