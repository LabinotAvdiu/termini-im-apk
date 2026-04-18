import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/avatar_provider.dart';

// ---------------------------------------------------------------------------
// AvatarEditor
// ---------------------------------------------------------------------------

/// Reusable circular avatar widget with inline pick/crop/upload flow.
///
/// - 120×120 on mobile, 140×140 on desktop (controlled by [size]).
/// - Displays [CachedNetworkImage] when a URL is present, else Fraunces initials.
/// - Camera button overlay triggers the picker bottom-sheet.
/// - Long-press (mobile) or secondary-tap (desktop) opens delete confirmation.
/// - During upload a gold [CircularProgressIndicator] overlays the circle.
class AvatarEditor extends ConsumerWidget {
  /// Explicit size override (defaults to 120).
  final double size;

  /// Initials computed by the parent (e.g. "LA" for "Labinot Avdiu").
  final String initials;

  const AvatarEditor({
    super.key,
    this.size = 120,
    required this.initials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final avatarState = ref.watch(avatarProvider);
    final notifier = ref.read(avatarProvider.notifier);

    // Show any upload/delete error as a SnackBar — one-shot.
    ref.listen<AvatarState>(avatarProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        if (context.mounted) {
          context.showErrorSnackBar(next.error!);
        }
      }
    });

    final photoUrl = user?.thumbnailUrl ?? user?.profileImageUrl;
    final isBusy = avatarState.uploading || avatarState.deleting;

    return GestureDetector(
      onLongPress: photoUrl != null && !isBusy
          ? () => _confirmDelete(context, notifier)
          : null,
      onSecondaryTap: photoUrl != null && !isBusy
          ? () => _confirmDelete(context, notifier)
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Main circle ────────────────────────────────────────────
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary,
                  width: 2,
                ),
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: ClipOval(
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        placeholder: (context2, url) =>
                            _InitialsCircle(initials: initials, size: size),
                        errorWidget: (context2, url, err) =>
                            _InitialsCircle(initials: initials, size: size),
                      )
                    : _InitialsCircle(initials: initials, size: size),
              ),
            ),

            // ── Upload/delete progress overlay ─────────────────────────
            if (isBusy)
              Positioned.fill(
                child: ClipOval(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Center(
                      child: SizedBox(
                        width: size * 0.38,
                        height: size * 0.38,
                        child: CircularProgressIndicator(
                          value: avatarState.uploading
                              ? avatarState.uploadProgress
                              : null,
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Camera button ──────────────────────────────────────────
            Positioned(
              bottom: 0,
              right: 0,
              child: _CameraButton(
                enabled: !isBusy,
                onTap: () => _onCameraButtonTap(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pick + crop flow
  // ---------------------------------------------------------------------------

  Future<void> _onCameraButtonTap(BuildContext context, WidgetRef ref) async {
    if (kIsWeb) {
      // Web: pick directly from gallery (camera not reliably supported).
      await _pickFromGallery(context, ref);
    } else {
      await _showPickerSheet(context, ref);
    }
  }

  Future<void> _showPickerSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AvatarPickerSheet(
        onCamera: () async {
          Navigator.of(ctx).pop();
          await _pickAndCrop(context, ref, ImageSource.camera);
        },
        onGallery: () async {
          Navigator.of(ctx).pop();
          await _pickAndCrop(context, ref, ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    await _pickAndCrop(context, ref, ImageSource.gallery);
  }

  Future<void> _pickAndCrop(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    // Capture context-dependent values BEFORE any async gap.
    final cropTitle = context.l10n.cropPhotoTitle;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    late Uint8List bytes;
    String filename = picked.name.isNotEmpty ? picked.name : 'avatar.jpg';

    if (kIsWeb) {
      // Web: image_cropper v9 web dialog — fallback to raw bytes if it fails.
      // Note: Web crop is best-effort; if the user's browser blocks the dialog
      // or the plugin fails, we upload the raw (uncropped) image directly.
      if (!context.mounted) return;
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            WebUiSettings(
              // ignore: use_build_context_synchronously
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: const CropperSize(width: 520, height: 520),
            ),
          ],
        );
        if (cropped != null) {
          bytes = await cropped.readAsBytes();
        } else {
          // User cancelled
          return;
        }
      } catch (_) {
        // Web crop failed — use raw image bytes directly (documented limitation).
        bytes = await picked.readAsBytes();
      }
    } else {
      // Mobile / desktop: native crop UI.
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: cropTitle, // captured before async gap
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppColors.secondary,
              statusBarLight: false,
              backgroundColor: AppColors.background,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: cropTitle, // captured before async gap
              aspectRatioLockEnabled: true,
              minimumAspectRatio: 1.0,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
        if (cropped != null) {
          bytes = await cropped.readAsBytes();
        } else {
          return; // User cancelled crop
        }
      } catch (_) {
        // Crop failed — fallback to raw
        bytes = await picked.readAsBytes();
      }
    }

    if (bytes.isEmpty) return;
    if (!context.mounted) return;

    await ref.read(avatarProvider.notifier).upload(bytes, filename);
  }

  // ---------------------------------------------------------------------------
  // Delete confirmation
  // ---------------------------------------------------------------------------

  void _confirmDelete(BuildContext context, AvatarNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.l10n.removePhoto,
          style: GoogleFonts.fraunces(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          context.l10n.removePhotoConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.delete();
            },
            child: Text(context.l10n.removePhoto),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Initials circle
// ---------------------------------------------------------------------------

class _InitialsCircle extends StatelessWidget {
  final String initials;
  final double size;

  const _InitialsCircle({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: GoogleFonts.fraunces(
          fontSize: size * 0.30,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
          height: 1.0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera button overlay
// ---------------------------------------------------------------------------

class _CameraButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _CameraButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.textHint,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 2),
        ),
        child: const Icon(
          Icons.photo_camera_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker bottom sheet (mobile)
// ---------------------------------------------------------------------------

class _AvatarPickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _AvatarPickerSheet({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary, size: 20),
              ),
              title: Text(
                context.l10n.takePhoto,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              onTap: onCamera,
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary, size: 20),
              ),
              title: Text(
                context.l10n.chooseFromGallery,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              onTap: onGallery,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small avatar read-only (used in dashboard greeting, employee cards)
// ---------------------------------------------------------------------------

/// Read-only circular avatar. No edit button. Optimised for small sizes
/// (40–80 dp).
class AvatarDisplay extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  /// When true, draws a 1.5px [AppColors.secondary] ring (selected state).
  final bool selected;

  const AvatarDisplay({
    super.key,
    this.photoUrl,
    required this.initials,
    this.size = 40,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.secondary : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (ctx, url) =>
                    _InitialsCircle(initials: initials, size: size),
                errorWidget: (ctx, url, err) =>
                    _InitialsCircle(initials: initials, size: size),
              )
            : _InitialsCircle(initials: initials, size: size),
      ),
    );
  }
}
