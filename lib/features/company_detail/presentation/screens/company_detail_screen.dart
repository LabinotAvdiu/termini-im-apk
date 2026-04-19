import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
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

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(companyDetailProvider.notifier)
          .loadCompany(widget.companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
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

    // Company is loaded — hand off to the correct presentation layer
    return ResponsiveLayout(
      mobile: CompanyDetailScreenMobile(companyId: widget.companyId),
      desktop: CompanyDetailScreenDesktop(companyId: widget.companyId),
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
