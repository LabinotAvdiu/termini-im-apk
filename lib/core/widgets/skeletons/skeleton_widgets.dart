/// Editorial skeleton pack — Prishtina palette.
///
/// All shimmer uses [AppColors.divider] as base and [AppColors.background]
/// as highlight so skeletons feel native to the ivoire theme.
/// Period 1400ms for a subtle, unhurried rhythm.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// Base shimmer wrapper — all skeletons use this.
// ---------------------------------------------------------------------------

class _EditorialShimmer extends StatelessWidget {
  final Widget child;

  const _EditorialShimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonBox — generic shimmer rectangle.
// ---------------------------------------------------------------------------

class SkeletonBox extends StatelessWidget {
  final double? w;
  final double? h;
  final BorderRadius? radius;

  const SkeletonBox({super.key, this.w, this.h, this.radius});

  @override
  Widget build(BuildContext context) {
    return _EditorialShimmer(
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: radius ?? BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonText — single text line skeleton.
// ---------------------------------------------------------------------------

class SkeletonText extends StatelessWidget {
  final double? width;

  const SkeletonText({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return _EditorialShimmer(
      child: Container(
        width: width,
        height: 13,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonAvatar — circular avatar placeholder.
// ---------------------------------------------------------------------------

class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar(this.size, {super.key});

  @override
  Widget build(BuildContext context) {
    return _EditorialShimmer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.divider,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonCompanyCard — mobile list card skeleton.
//
// Mirrors the real CompanyCard layout:
//   photo (left, ~35% w) | name + address + rating + 2 slot rows (right)
//   + bottom action row
// ---------------------------------------------------------------------------

class SkeletonCompanyCard extends StatelessWidget {
  const SkeletonCompanyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final photoWidth =
        (MediaQuery.sizeOf(context).width * 0.35).clamp(100.0, 130.0);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo + content row
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo block
                  SkeletonBox(
                    w: photoWidth,
                    radius: BorderRadius.zero,
                  ),

                  // Text block
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          SkeletonText(
                            width: double.infinity,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Address
                          SkeletonText(width: 110),
                          const SizedBox(height: AppSpacing.xs),
                          SkeletonText(width: 80),
                          const SizedBox(height: AppSpacing.sm),

                          // Rating row
                          Row(
                            children: [
                              SkeletonBox(w: 14, h: 14, radius: BorderRadius.circular(2)),
                              const SizedBox(width: 4),
                              SkeletonText(width: 60),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Morning slots row
                          _SkeletonSlotRow(),
                          const SizedBox(height: AppSpacing.xs),

                          // Afternoon slots row
                          _SkeletonSlotRow(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider + bottom action
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SkeletonBox(
                    w: 80,
                    h: 32,
                    radius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSlotRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        SkeletonText(width: 52),
        const SizedBox(width: 4),
        // 4 slot chips
        for (int i = 0; i < 4; i++) ...[
          SkeletonBox(
            w: 36,
            h: 20,
            radius: BorderRadius.circular(6),
          ),
          if (i < 3) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonDesktopSalonCard — 16:10 large card for desktop grid.
//
// Mirrors _DesktopSalonCard: tall photo + title + address + rating + CTA.
// ---------------------------------------------------------------------------

class SkeletonDesktopSalonCard extends StatelessWidget {
  const SkeletonDesktopSalonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo — aspect 16:10
          AspectRatio(
            aspectRatio: 16 / 10,
            child: SkeletonBox(radius: BorderRadius.zero),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: double.infinity),
                const SizedBox(height: AppSpacing.xs),
                SkeletonText(width: 140),
                const SizedBox(height: AppSpacing.sm),

                // Rating
                Row(
                  children: [
                    SkeletonBox(
                      w: 12,
                      h: 12,
                      radius: BorderRadius.circular(2),
                    ),
                    const SizedBox(width: 4),
                    SkeletonText(width: 70),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // CTA button
                SkeletonBox(
                  w: double.infinity,
                  h: 36,
                  radius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonAppointmentCard — for My appointments / Pending approvals.
//
// Mirrors _AppointmentCard: photo banner + company name + date/time box +
// service row.
// ---------------------------------------------------------------------------

class SkeletonAppointmentCard extends StatelessWidget {
  const SkeletonAppointmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo banner
          SkeletonBox(
            w: double.infinity,
            h: 120,
            radius: BorderRadius.zero,
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company name + status badge
                Row(
                  children: [
                    Expanded(child: SkeletonText()),
                    const SizedBox(width: AppSpacing.sm),
                    SkeletonBox(
                      w: 72,
                      h: 22,
                      radius: BorderRadius.circular(20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SkeletonText(width: 120),
                const SizedBox(height: AppSpacing.md),

                // Date/time box
                SkeletonBox(
                  w: double.infinity,
                  h: 44,
                  radius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                const SizedBox(height: AppSpacing.md),

                // Service row
                Row(
                  children: [
                    Expanded(child: SkeletonText()),
                    SkeletonText(width: 40),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SkeletonText(width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonServiceRow — for service list in company detail.
// ---------------------------------------------------------------------------

class SkeletonServiceRow extends StatelessWidget {
  const SkeletonServiceRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Icon square
          SkeletonBox(
            w: 40,
            h: 40,
            radius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(),
                const SizedBox(height: AppSpacing.xs),
                SkeletonText(width: 80),
              ],
            ),
          ),

          // Price
          SkeletonText(width: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonCompanyDetailMobile — full-screen skeleton for company detail.
//
// Mirrors CompanyDetailScreenMobile layout: hero photo → info sheet →
// service list rows.
// ---------------------------------------------------------------------------

class SkeletonCompanyDetailMobile extends StatelessWidget {
  const SkeletonCompanyDetailMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero photo
        SkeletonBox(
          w: double.infinity,
          h: 280,
          radius: BorderRadius.zero,
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overline
              SkeletonText(width: 80),
              const SizedBox(height: AppSpacing.sm),

              // Name
              SkeletonBox(
                w: 220,
                h: 28,
                radius: BorderRadius.circular(6),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Address
              Row(
                children: [
                  SkeletonBox(w: 14, h: 14, radius: BorderRadius.circular(2)),
                  const SizedBox(width: 4),
                  SkeletonText(width: 160),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Rating
              Row(
                children: [
                  SkeletonBox(w: 14, h: 14, radius: BorderRadius.circular(2)),
                  const SizedBox(width: 4),
                  SkeletonText(width: 80),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Book button
              SkeletonBox(
                w: double.infinity,
                h: 44,
                radius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section divider
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),

              // Service rows
              for (int i = 0; i < 5; i++) ...[
                const SkeletonServiceRow(),
                if (i < 4) const Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonBookingEmployees — employees step skeleton.
// ---------------------------------------------------------------------------

class SkeletonBookingEmployees extends StatelessWidget {
  const SkeletonBookingEmployees({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 4; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SkeletonAvatar(48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(),
                      const SizedBox(height: AppSpacing.xs),
                      SkeletonText(width: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (i < 3)
            const Divider(
              height: 1,
              color: AppColors.divider,
              indent: AppSpacing.md,
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonTimeSlots — time slot grid skeleton.
// ---------------------------------------------------------------------------

class SkeletonTimeSlots extends StatelessWidget {
  const SkeletonTimeSlots({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chips row
          Row(
            children: [
              for (int i = 0; i < 5; i++) ...[
                SkeletonBox(
                  w: 52,
                  h: 52,
                  radius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                if (i < 4) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Time slot grid — 4 columns × 4 rows
          for (int row = 0; row < 4; row++) ...[
            Row(
              children: [
                for (int col = 0; col < 4; col++) ...[
                  Expanded(
                    child: SkeletonBox(
                      h: 40,
                      radius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  if (col < 3) const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
            if (row < 3) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonDashboard — owner/employee dashboard skeleton.
//
// Covers the banner + stats row + upcoming appointments section.
// ---------------------------------------------------------------------------

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const SkeletonAvatar(56),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonText(),
                      SizedBox(height: AppSpacing.xs),
                      SkeletonText(width: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats row — 3 cards
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SkeletonText(width: 32),
                        SizedBox(height: AppSpacing.xs),
                        SkeletonText(width: 60),
                      ],
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section header
          const SkeletonText(width: 120),
          const SizedBox(height: AppSpacing.sm),

          // Appointment cards
          for (int i = 0; i < 3; i++) ...[
            const SkeletonAppointmentCard(),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonPlanningDay — skeleton for day-view planning.
// ---------------------------------------------------------------------------

class SkeletonPlanningDay extends StatelessWidget {
  const SkeletonPlanningDay({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(
                w: 36,
                h: 36,
                radius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              const SkeletonText(width: 140),
              SkeletonBox(
                w: 36,
                h: 36,
                radius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Time blocks
          for (int i = 0; i < 6; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SkeletonBox(
                    h: i % 2 == 0 ? 60 : 40,
                    radius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonPendingApprovals — skeleton for the pending approvals list.
// ---------------------------------------------------------------------------

class SkeletonPendingApprovals extends StatelessWidget {
  const SkeletonPendingApprovals({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SkeletonBox(
          w: 200,
          h: 26,
          radius: BorderRadius.all(Radius.circular(6)),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (int i = 0; i < 4; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SkeletonAvatar(40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonText(),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonText(width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SkeletonBox(
                        h: 36,
                        radius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SkeletonBox(
                        h: 36,
                        radius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
