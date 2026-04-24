import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Ecran bloquant affiché quand [RemoteConfigService.forceUpdateRequired] est
/// true. Non-dismissible : aucun bouton retour, aucun barrier tap.
///
/// Affiche un bouton vers l'App Store / Play Store selon la plateforme.
/// En dev le lien peut être un placeholder — pas critique car forceUpdate sera
/// false par défaut dans Remote Config.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  // TODO: remplacer par les vrais liens stores une fois l'app publiée.
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.termini.im';
  static const _appStoreUrl =
      'https://apps.apple.com/app/termini-im/idPLACEHOLDER';

  Future<void> _openStore() async {
    // Sur Android ouvre Play Store, sur iOS App Store, sur web Play Store par défaut.
    const url = String.fromEnvironment('FLUTTER_PLATFORM') == 'ios'
        ? _appStoreUrl
        : _playStoreUrl;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Locale-aware fallback — les strings seront ajoutées à l'ARB lors du
    // prochain sprint i18n. Pour l'instant on utilise du hardcode FR/EN selon
    // la locale détectée.
    final locale = Localizations.localeOf(context).languageCode;

    final title = switch (locale) {
      'sq' => 'Përditëso aplikacionin',
      'fr' => 'Mise à jour requise',
      _   => 'Update required',
    };
    final body = switch (locale) {
      'sq' => 'Një version i ri i Termini im është i disponueshëm. Ju lutemi '
          'përditësoni për të vazhduar.',
      'fr' => 'Une nouvelle version de Termini im est disponible. Mets à jour '
          'pour continuer.',
      _   => 'A new version of Termini im is available. Please update to '
          'continue.',
    };
    final buttonLabel = switch (locale) {
      'sq' => 'Përditëso tani',
      'fr' => 'Mettre à jour',
      _   => 'Update now',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                body,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _openStore,
                  // Bouton primaire sur fond sable : encre (#171311), texte sable
                  child: Text(
                    buttonLabel.toUpperCase(),
                    style: AppTextStyles.button
                        .copyWith(color: AppColors.background),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
