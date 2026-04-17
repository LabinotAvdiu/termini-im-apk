import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/company_detail_model.dart';
import '../providers/company_detail_provider.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/service_category_section.dart';

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
    // Load company on first frame so provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(companyDetailProvider.notifier)
          .loadCompany(widget.companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading
          ? const _LoadingView()
          : state.error != null
              ? _ErrorView(message: state.error!)
              : state.company == null
                  ? const _LoadingView()
                  : _CompanyBody(
                      companyId: widget.companyId,
                      state: state,
                      ref: ref,
                    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------

class _CompanyBody extends StatelessWidget {
  final String companyId;
  final CompanyDetailState state;
  final WidgetRef ref;

  const _CompanyBody({
    required this.companyId,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final company = state.company!;

    return CustomScrollView(
      slivers: [
        // Collapsible app bar with photo gallery
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.surface,
          leading: _BackButton(),
          actions: [
            _ShareButton(),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: PhotoGallery(
              photoUrls: company.photos,
              height: 300,
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company info card (floats above the list)
              _CompanyInfoCard(company: company),

              // Services header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  context.l10n.ourServices,
                  style: AppTextStyles.h2,
                ),
              ),

              // Service categories
              ...company.categories.map(
                (cat) => ServiceCategorySection(
                  category: cat,
                  onServiceChosen: (service) {
                    context.goNamed(
                      RouteNames.booking,
                      pathParameters: {'id': companyId},
                      queryParameters: {'serviceId': service.id},
                    );
                  },
                ),
              ),

              // Bottom spacing for safe area
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Company info card
// ---------------------------------------------------------------------------

class _CompanyInfoCard extends StatelessWidget {
  final CompanyDetailModel company;

  const _CompanyInfoCard({required this.company});

  Future<void> _dialPhone(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = company.phone != null && company.phone!.isNotEmpty;
    final hasPhoneSecondary =
        company.phoneSecondary != null && company.phoneSecondary!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + price level row
          Text(
            company.name,
            style: AppTextStyles.h2,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Address
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  company.address,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Primary phone
          if (hasPhone) ...[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () => _dialPhone(context, company.phone!),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    company.phone!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Secondary phone
          if (hasPhoneSecondary) ...[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () => _dialPhone(context, company.phoneSecondary!),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    company.phoneSecondary!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Rating row
          Row(
            children: [
              _StarRating(rating: company.rating),
              const SizedBox(width: AppSpacing.sm),
              Text(
                company.rating.toStringAsFixed(1),
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.reviews(company.reviewCount),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 1
              ? Icons.star_rounded
              : fill >= 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 18,
          color: AppColors.starRating,
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Back and share buttons (semi-transparent for sliver overlap)
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error states
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
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
