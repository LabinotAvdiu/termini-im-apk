import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorite_provider.dart';
import '../providers/company_detail_provider.dart';
import 'company_detail_screen_mobile.dart';
import 'company_detail_screen_desktop.dart';

/// Thin wrapper — owns loading/error/content state management.
///
/// Triggers the [companyDetailProvider] fetch, then hands off to:
/// - [CompanyDetailScreenMobile] for mobile/tablet (< 1100px)
/// - [CompanyDetailScreenDesktop] for desktop (≥ 1100px)
///
/// The public class name and constructor signature are unchanged so the router
/// does not need to be updated.
class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String companyId;
  /// Set by the router when a shared link carries `?employee=<userId>`.
  /// Filters services to what the employee can do and forwards the id to
  /// the booking flow on "Choisir".
  final String? preselectedEmployeeId;
  /// Set by the router when the URL carries `?fav=1` (QR scan from
  /// Settings → Partage QR). Triggers a one-shot auto-favorite on landing
  /// for authenticated users — the QR caption literally says "Ajoute-moi
  /// en favori et prends RDV", we honour the intent.
  final bool autoFavorite;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
    this.preselectedEmployeeId,
    this.autoFavorite = false,
  });

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  // Guard against the auto-fav firing twice (e.g. on hot reload or
  // back-navigation re-running initState).
  bool _autoFavoriteHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(companyDetailProvider.notifier)
          .loadCompany(widget.companyId);
      // E25 — salon_viewed
      ref.read(analyticsProvider).logSalonViewed(salonId: widget.companyId);
    });
  }

  /// Auto-favorite trigger: runs once after the company has loaded.
  ///
  /// - Authenticated user: calls addFavorite (idempotent server-side
  ///   upsert) and shows a snackbar.
  /// - Guest: stays in pending mode — the fav=1 + employee params live
  ///   in the URL. As soon as the user logs in / signs up while still
  ///   on this screen, the ref.listen(authStateProvider) handler in
  ///   build() retriggers this method.
  Future<void> _maybeAutoFavorite() async {
    if (_autoFavoriteHandled) return;
    if (!widget.autoFavorite) return;

    final auth = ref.read(authStateProvider);
    final detail = ref.read(companyDetailProvider);
    if (detail.company == null) return;
    if (auth.user == null) return; // Guest — wait for auth via listener.
    if (detail.company!.isFavorite && widget.preselectedEmployeeId == null) {
      // Already favorited and no employee preference to upsert → no-op.
      _autoFavoriteHandled = true;
      return;
    }

    _autoFavoriteHandled = true;
    final ok = await ref.read(favoriteProvider.notifier).add(
          widget.companyId,
          employeeId: widget.preselectedEmployeeId,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.favoriteAddedFromQr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pending QR-fav recovery: a guest who landed via QR (?fav=1) can log
    // in or sign up via the auth modal triggered by "Prendre RDV". When
    // the auth state flips to authenticated WHILE this screen is still
    // mounted, retrigger the auto-favorite — the URL still carries the
    // params, no need to persist anything across navigations.
    ref.listen(authStateProvider, (prev, next) {
      final wasGuest = prev?.user == null;
      final isNowAuthed = next.user != null;
      if (wasGuest && isNowAuthed && widget.autoFavorite && !_autoFavoriteHandled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeAutoFavorite();
        });
      }
    });

    final state = ref.watch(companyDetailProvider);

    if (state.isLoading || state.company == null && state.error == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _LoadingView(),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _ErrorView(message: state.error!),
      );
    }

    // Schedule the auto-fav check after this build finishes — the
    // company is now loaded, so it's safe to read its current isFavorite
    // state and decide whether to call the API.
    if (widget.autoFavorite && !_autoFavoriteHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoFavorite());
    }

    // Company is loaded — hand off to the correct presentation layer
    return ResponsiveLayout(
      mobile: CompanyDetailScreenMobile(
        companyId: widget.companyId,
        preselectedEmployeeId: widget.preselectedEmployeeId,
      ),
      desktop: CompanyDetailScreenDesktop(
        companyId: widget.companyId,
        preselectedEmployeeId: widget.preselectedEmployeeId,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error states — used only by the wrapper, not the presentations
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      child: const SingleChildScrollView(
        key: ValueKey('detail-skeleton'),
        child: SkeletonCompanyDetailMobile(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
