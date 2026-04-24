import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Session-dismiss state — local flag, not persisté entre sessions.
// ---------------------------------------------------------------------------

final _diasporaBannerDismissedProvider = StateProvider<bool>((ref) => false);

/// Banner éditorial bordeaux affiché sur le home client quand le flag Remote
/// Config [RCKeys.diasporaBanner] est true ET que la locale de l'utilisateur
/// est `fr` ou `en`.
///
/// Dismissible pour la session (non persisté — réapparaît au prochain cold start
/// si le flag est encore actif).
class DiasporaBanner extends ConsumerWidget {
  const DiasporaBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate Remote Config.
    final rc = ref.watch(remoteConfigProvider);
    if (!rc.diasporaBanner) return const SizedBox.shrink();

    // Gate locale : uniquement fr / en (pas sq).
    final locale = ref.watch(localeProvider).languageCode;
    if (locale == 'sq') return const SizedBox.shrink();

    // Gate dismiss session.
    final dismissed = ref.watch(_diasporaBannerDismissedProvider);
    if (dismissed) return const SizedBox.shrink();

    final message = switch (locale) {
      'fr' => 'Tu rentres cet été ? Réserve maintenant.',
      _   => 'You\'re coming back this summer? Book now.',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Bouton dismiss — touch target 48x48 pour accessibilité.
            GestureDetector(
              onTap: () => ref
                  .read(_diasporaBannerDismissedProvider.notifier)
                  .state = true,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
