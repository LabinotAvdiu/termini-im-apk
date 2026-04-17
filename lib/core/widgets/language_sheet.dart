import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/extensions.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Shows the language selection bottom-sheet.
///
/// When [repository] is provided (i.e. the user is authenticated) the locale
/// change is also synced to the backend via PUT /auth/profile.
void showLanguageSheet(
  BuildContext context, {
  AuthRepository? repository,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => Consumer(
      builder: (ctx, sheetRef, _) {
        final currentLocale = sheetRef.watch(localeProvider);

        void changeLocale(String code) {
          Navigator.of(ctx).pop();
          sheetRef
              .read(localeProvider.notifier)
              .setLocale(code, repository: repository);
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                ctx.l10n.language,
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
                title: Text(ctx.l10n.french, style: AppTextStyles.body),
                trailing: currentLocale.languageCode == 'fr'
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22)
                    : null,
                onTap: () => changeLocale('fr'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(ctx.l10n.english, style: AppTextStyles.body),
                trailing: currentLocale.languageCode == 'en'
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22)
                    : null,
                onTap: () => changeLocale('en'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Text('🇦🇱', style: TextStyle(fontSize: 24)),
                title: Text(ctx.l10n.albanian, style: AppTextStyles.body),
                trailing: currentLocale.languageCode == 'sq'
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22)
                    : null,
                onTap: () => changeLocale('sq'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    ),
  );
}
