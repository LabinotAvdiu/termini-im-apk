import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';

// ---------------------------------------------------------------------------
// Booking mode constants
// ---------------------------------------------------------------------------
const kEmployeeBased = 'employee_based';
const kCapacityBased = 'capacity_based';

// ---------------------------------------------------------------------------
// BookingModePicker — 2 comparative editorial cards
// Mobile: stacked vertically. Desktop (>= 600 px): side-by-side.
// Used by both CompanyModeScreen (social signup step 2/2)
// and _CompanyStep3BookingMode (normal signup step 3/4).
// ---------------------------------------------------------------------------
class BookingModePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const BookingModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    final individualCard = _ModeCard(
      mode: kEmployeeBased,
      selected: value == kEmployeeBased,
      onTap: () => onChanged(kEmployeeBased),
      title: l.companySetupModeIndividualTitle,
      example: l.companySetupModeIndividualExample,
      bullets: [
        l.companySetupModeIndividualBullet1,
        l.companySetupModeIndividualBullet2,
        l.companySetupModeIndividualBullet3,
        l.companySetupModeIndividualBullet4,
      ],
      illustration: const _IndividualModeIllustration(),
      miniSchema: const _IndividualMiniSchema(),
    );

    final capacityCard = _ModeCard(
      mode: kCapacityBased,
      selected: value == kCapacityBased,
      onTap: () => onChanged(kCapacityBased),
      title: l.companySetupModeCapacityTitle,
      example: l.companySetupModeCapacityExample,
      bullets: [
        l.companySetupModeCapacityBullet1,
        l.companySetupModeCapacityBullet2,
        l.companySetupModeCapacityBullet3,
        l.companySetupModeCapacityBullet4,
      ],
      illustration: const _CapacityModeIllustration(),
      miniSchema: const _CapacityMiniSchema(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.companySetupModeTitle,
          style: GoogleFonts.fraunces(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: individualCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: capacityCard),
              ],
            ),
          )
        else
          Column(
            children: [
              individualCard,
              const SizedBox(height: AppSpacing.md),
              capacityCard,
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.companySetupModeCaption,
          textAlign: TextAlign.center,
          style: GoogleFonts.instrumentSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ModeCard — single selectable card (private to this file)
// ---------------------------------------------------------------------------
class _ModeCard extends StatelessWidget {
  final String mode;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String example;
  final List<String> bullets;
  final Widget illustration;
  final Widget miniSchema;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.example,
    required this.bullets,
    required this.illustration,
    required this.miniSchema,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppSpacing.radiusLg));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2.0 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: spacer + checkmark (no badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 22),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : AppColors.divider,
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Illustration + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.textHint.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: illustration,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          example,
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textHint,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Mini schema
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: miniSchema,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSpacing.sm),
              // Bullets
              ...bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          b,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11.5,
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Mini schemas
// ---------------------------------------------------------------------------

class _IndividualMiniSchema extends StatelessWidget {
  const _IndividualMiniSchema();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SchemaRow(time: '10h', label: 'Ardit — Coupe', booked: true, alt: false),
        const SizedBox(height: 5),
        _SchemaRow(time: '11h', label: 'Mimoza — Balayage', booked: true, alt: true),
        const SizedBox(height: 5),
        _SchemaRow(time: '12h', label: 'Disponible', booked: false, alt: false),
      ],
    );
  }
}

class _SchemaRow extends StatelessWidget {
  final String time;
  final String label;
  final bool booked;
  final bool alt;

  const _SchemaRow({
    required this.time,
    required this.label,
    required this.booked,
    required this.alt,
  });

  @override
  Widget build(BuildContext context) {
    final Color slotColor;
    final Color textColor;
    final bool dashed;

    if (!booked) {
      slotColor = AppColors.textHint.withValues(alpha: 0.08);
      textColor = AppColors.textHint;
      dashed = true;
    } else if (alt) {
      slotColor = AppColors.secondary.withValues(alpha: 0.16);
      textColor = const Color(0xFF7A600E);
      dashed = false;
    } else {
      slotColor = AppColors.primary.withValues(alpha: 0.12);
      textColor = AppColors.primary;
      dashed = false;
    }

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            time,
            style: GoogleFonts.instrumentSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 0.04,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: slotColor,
              borderRadius: BorderRadius.circular(4),
              border: dashed
                  ? Border.all(color: AppColors.border, width: 1)
                  : null,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.04,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CapacityMiniSchema extends StatelessWidget {
  const _CapacityMiniSchema();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CapRow(time: '10h', slots: const ['C.1', 'C.2', 'C.3', '—']),
        const SizedBox(height: 5),
        _CapRow(time: '11h', slots: const ['C.4', 'C.5', '—', '—']),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '3/4',
                style: GoogleFonts.instrumentSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: 0.75,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CapRow extends StatelessWidget {
  final String time;
  final List<String> slots;

  const _CapRow({required this.time, required this.slots});

  static final List<Color> _pillColors = [
    AppColors.primary.withValues(alpha: 0.12),
    AppColors.secondary.withValues(alpha: 0.16),
    const Color(0xFF6F7E55).withValues(alpha: 0.18),
  ];

  static final List<Color> _textColors = [
    AppColors.primary,
    const Color(0xFF7A600E),
    const Color(0xFF6F7E55),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            time,
            style: GoogleFonts.instrumentSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(slots.length, (i) {
          final isFree = slots[i] == '—';
          return Expanded(
            child: Container(
              height: 18,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
              decoration: BoxDecoration(
                color: isFree
                    ? AppColors.textHint.withValues(alpha: 0.07)
                    : _pillColors[i % _pillColors.length],
                borderRadius: BorderRadius.circular(4),
                border: isFree
                    ? Border.all(color: AppColors.border, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  slots[i],
                  style: GoogleFonts.instrumentSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isFree
                        ? AppColors.textHint
                        : _textColors[i % _textColors.length],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Illustrations — CustomPainter-based
// ---------------------------------------------------------------------------

class _IndividualModeIllustration extends StatelessWidget {
  const _IndividualModeIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: _IndividualPainter(),
    );
  }
}

class _IndividualPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final burgundy = AppColors.primary;
    final gold = AppColors.secondary;

    final chairBack = Paint()..color = burgundy.withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.28, size.height * 0.18,
            size.width * 0.30, size.height * 0.24),
        const Radius.circular(3),
      ),
      chairBack,
    );

    final seatRail = Paint()..color = burgundy.withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.31, size.height * 0.44,
            size.width * 0.22, size.height * 0.055),
        const Radius.circular(1),
      ),
      seatRail,
    );

    final legs = Paint()..color = burgundy.withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.31, size.height * 0.50,
            size.width * 0.075, size.height * 0.18),
        const Radius.circular(2),
      ),
      legs,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.455, size.height * 0.50,
            size.width * 0.075, size.height * 0.18),
        const Radius.circular(2),
      ),
      legs,
    );

    final clockStroke = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final clockCenter = Offset(size.width * 0.76, size.height * 0.26);
    const clockR = 5.5;
    canvas.drawCircle(clockCenter, clockR, clockStroke);

    final handPaint = Paint()
      ..color = gold
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      clockCenter,
      Offset(clockCenter.dx, clockCenter.dy - clockR * 0.6),
      handPaint,
    );
    canvas.drawLine(
      clockCenter,
      Offset(clockCenter.dx + clockR * 0.7, clockCenter.dy),
      handPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CapacityModeIllustration extends StatelessWidget {
  const _CapacityModeIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: _CapacityPainter(),
    );
  }
}

class _CapacityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.textHint.withValues(alpha: 0.45),
      AppColors.textHint.withValues(alpha: 0.45),
      AppColors.primary.withValues(alpha: 0.65),
      AppColors.secondary.withValues(alpha: 0.65),
    ];

    const chairW = 7.0;
    const chairH = 6.0;
    const gapX = 3.5;
    final startX = (size.width - (4 * chairW + 3 * gapX)) / 2;
    const startY = 8.0;

    for (int i = 0; i < 4; i++) {
      final x = startX + i * (chairW + gapX);
      final p = Paint()..color = colors[i];

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, startY, chairW, chairH),
          const Radius.circular(1.5),
        ),
        p,
      );

      final railPaint = Paint()
        ..color = colors[i].withValues(alpha: colors[i].a * 0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 0.5, startY + chairH, chairW - 1, 1.2),
          const Radius.circular(0.3),
        ),
        railPaint,
      );

      final legPaint = Paint()
        ..color = colors[i].withValues(alpha: colors[i].a * 0.75);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, startY + chairH + 1.2, 1.5, 4.5),
          const Radius.circular(0.8),
        ),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + chairW - 2.5, startY + chairH + 1.2, 1.5, 4.5),
          const Radius.circular(0.8),
        ),
        legPaint,
      );
    }

    const barY = 36.0;
    const barH = 3.5;
    const barMarginX = 4.0;
    final barW = size.width - 2 * barMarginX;

    final bgBar = Paint()..color = AppColors.border;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barMarginX, barY, barW, barH),
        const Radius.circular(1.75),
      ),
      bgBar,
    );

    final fillBar = Paint()..color = AppColors.primary.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barMarginX, barY, barW * 0.75, barH),
        const Radius.circular(1.75),
      ),
      fillBar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
