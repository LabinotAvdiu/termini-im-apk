import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Ecran bloquant affiché quand [RemoteConfigService.maintenanceMode] est true.
/// Non-dismissible — l'utilisateur ne peut rien faire d'autre qu'attendre.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    final title = switch (locale) {
      'sq' => 'Mirëmbajtje',
      'fr' => 'Maintenance en cours',
      _   => 'Down for maintenance',
    };
    final body = switch (locale) {
      'sq' => 'Termini im është duke u mirëmbajtur — kthehemi shpejt.',
      'fr' => 'Termini im est en maintenance — on revient très vite.',
      _   => 'Termini im is under maintenance — we\'ll be back soon.',
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
                Icons.construction_rounded,
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
            ],
          ),
        ),
      ),
    );
  }
}
