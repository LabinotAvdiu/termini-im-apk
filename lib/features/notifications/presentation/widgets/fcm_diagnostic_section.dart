import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/repositories/notification_repository.dart';

/// Section diagnostic FCM — montre l'état de la chaîne de notifications
/// pour que l'utilisateur (ou le support) voie immédiatement où ça casse :
/// Firebase → permission → token → enregistrement backend.
class FcmDiagnosticSection extends ConsumerStatefulWidget {
  const FcmDiagnosticSection({super.key});

  @override
  ConsumerState<FcmDiagnosticSection> createState() =>
      _FcmDiagnosticSectionState();
}

class _FcmDiagnosticSectionState extends ConsumerState<FcmDiagnosticSection> {
  FcmDiagnostic? _result;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);

    final repo = ref.read(notificationRepositoryProvider);
    final result = await NotificationService.runDiagnostic(
      registerCallback: (token, platform) =>
          repo.registerDevice(token: token, platform: platform),
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Web : pas de notifs push mobiles à diagnostiquer. On cache la section.
    if (kIsWeb) return const SizedBox.shrink();

    final result = _result;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Diagnostic des notifications',
                  style: GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.primary),
                onPressed: _running ? null : _run,
                tooltip: 'Relancer',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Si tu ne reçois pas les notifications, cette liste te montre où la chaîne casse.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (result == null && !_running)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('—', style: TextStyle(color: AppColors.textHint)),
            )
          else if (result != null) ...[
            _DiagRow(
              label: 'Firebase initialisé',
              ok: result.firebaseReady,
            ),
            _DiagRow(
              label: 'Permission système',
              ok: result.permissionGranted,
              detail: result.permissionStatus,
            ),
            _DiagRow(
              label: 'Token FCM obtenu',
              ok: result.tokenPresent,
              detail: result.token != null
                  ? '${result.token!.substring(0, result.token!.length.clamp(0, 24))}…'
                  : null,
              onCopy: result.token != null
                  ? () {
                      Clipboard.setData(ClipboardData(text: result.token!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Token copié'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
            ),
            _DiagRow(
              label: 'Enregistré côté serveur',
              ok: result.backendOk == true,
              detail: result.backendOk == null
                  ? 'non tenté'
                  : result.backendOk == true
                      ? 'POST /me/devices OK'
                      : (result.backendError ?? 'erreur'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (result.fullyOperational)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4EA),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Tout est OK — tu devrais recevoir les notifications.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2E7D32),
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  _hint(result),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _hint(FcmDiagnostic r) {
    if (!r.firebaseReady) {
      return 'Firebase ne s\'est pas initialisé. Rare — signale-le au support.';
    }
    if (!r.permissionGranted) {
      return 'La permission système est refusée. Ouvre Paramètres système → Termini im → Notifications et active-les.';
    }
    if (!r.tokenPresent) {
      return 'Firebase n\'a pas réussi à émettre un token. Vérifie la connexion internet et relance.';
    }
    if (r.backendOk == false) {
      return 'Le token n\'a pas pu être envoyé au serveur. Détail : ${r.backendError ?? "erreur inconnue"}.';
    }
    return 'État partiel — relance le diagnostic.';
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final bool ok;
  final String? detail;
  final VoidCallback? onCopy;

  const _DiagRow({
    required this.label,
    required this.ok,
    this.detail,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: ok ? const Color(0xFF2E7D32) : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  size: 16, color: AppColors.textHint),
              onPressed: onCopy,
              tooltip: 'Copier',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
