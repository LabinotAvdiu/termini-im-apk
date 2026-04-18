import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Scroll behaviour that accepts every pointer device type so that mouse drag
/// works in PageView on Flutter Web (Chrome excludes mouse by default).
class _AllPointerDragBehavior extends MaterialScrollBehavior {
  const _AllPointerDragBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.invertedStylus,
      };
}

/// Opens a fullscreen editorial lightbox over the current route.
///
/// [photos]       — full list of photo URLs.
/// [initialIndex] — which photo to show first.
/// [salonName]    — optional salon name shown as subtitle in the counter area.
void showGalleryLightbox(
  BuildContext context,
  List<String> photos, {
  int initialIndex = 0,
  String? salonName,
}) {
  if (photos.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _GalleryLightbox(
          photos: photos,
          initialIndex: initialIndex,
          salonName: salonName,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fadeAnim,
          child: ScaleTransition(scale: scaleAnim, child: child),
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Private lightbox widget
// ---------------------------------------------------------------------------

class _GalleryLightbox extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String? salonName;

  const _GalleryLightbox({
    required this.photos,
    required this.initialIndex,
    this.salonName,
  });

  @override
  State<_GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<_GalleryLightbox>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;

  // Used to disable swipe while InteractiveViewer is zoomed in.
  bool _isZoomed = false;

  // Thumbnail scroll controller — keeps active thumb visible.
  late final ScrollController _thumbScrollController;

  // Keyboard focus node.
  late final FocusNode _focusNode;

  static const double _thumbWidth = 80.0;
  static const double _thumbHeight = 60.0;
  static const double _thumbSpacing = 8.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbScrollController = ScrollController();
    _focusNode = FocusNode();

    // Request keyboard focus once the widget is in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scrollThumbToIndex(_currentIndex, animated: false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.photos.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _scrollThumbToIndex(index, animated: true);
  }

  void _scrollThumbToIndex(int index, {required bool animated}) {
    if (!_thumbScrollController.hasClients) return;
    final cellWidth = _thumbWidth + _thumbSpacing;
    final targetOffset = (index * cellWidth) -
        (_thumbScrollController.position.viewportDimension / 2) +
        (_thumbWidth / 2);
    final clamped = targetOffset.clamp(
      0.0,
      _thumbScrollController.position.maxScrollExtent,
    );
    if (animated) {
      _thumbScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      _thumbScrollController.jumpTo(clamped.clamp(
        0.0,
        // maxScrollExtent is available only after first frame; guard it.
        _thumbScrollController.position.hasContentDimensions
            ? _thumbScrollController.position.maxScrollExtent
            : 0.0,
      ));
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_currentIndex + 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_currentIndex - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    final currentLabel =
        (_currentIndex + 1).toString().padLeft(2, '0');
    final totalLabel = total.toString().padLeft(2, '0');
    final counterText = '$currentLabel — $totalLabel';

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Backdrop ────────────────────────────────────────────────
              _Backdrop(),

              // ── Photo PageView ───────────────────────────────────────────
              _buildPhotoView(total),

              // ── Top bar (counter + close) ────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(counterText),
              ),

              // ── Navigation arrows ────────────────────────────────────────
              if (total > 1) ...[
                _NavArrow(
                  direction: _ArrowDirection.left,
                  onTap: () => _goTo(_currentIndex - 1),
                  enabled: _currentIndex > 0,
                ),
                _NavArrow(
                  direction: _ArrowDirection.right,
                  onTap: () => _goTo(_currentIndex + 1),
                  enabled: _currentIndex < total - 1,
                ),
              ],

              // ── Thumbnail strip ──────────────────────────────────────────
              if (total > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildThumbStrip(total),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoView(int total) {
    return Positioned(
      top: 0,
      bottom: total > 1 ? 96 : 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        // Absorb taps on the photo area to prevent closing the lightbox.
        onTap: () {},
        child: ScrollConfiguration(
          behavior: const _AllPointerDragBehavior(),
          child: PageView.builder(
            controller: _pageController,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: total,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _PhotoPage(
                url: widget.photos[index],
                onScaleChanged: (scale) {
                  final zoomed = scale > 1.01;
                  if (zoomed != _isZoomed) {
                    setState(() => _isZoomed = zoomed);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String counterText) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Counter + optional salon name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  counterText,
                  style: GoogleFonts.fraunces(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                if (widget.salonName != null && widget.salonName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.salonName!,
                      style: GoogleFonts.fraunces(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // Close button
            _CloseButton(onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbStrip(int total) {
    // Horizontal padding dynamically centers the strip when the total content
    // width fits inside the viewport. When it doesn't, the padding collapses
    // to a comfortable 20 px edge and the ListView scrolls naturally.
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 96,
        color: Colors.black.withValues(alpha: 0.60),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                total * _thumbWidth + (total - 1) * _thumbSpacing;
            final sidePad = contentWidth < constraints.maxWidth
                ? (constraints.maxWidth - contentWidth) / 2
                : 20.0;
            return ScrollConfiguration(
              behavior: const _AllPointerDragBehavior(),
              child: ListView.separated(
                controller: _thumbScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: sidePad,
                ),
                itemCount: total,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: _thumbSpacing),
                itemBuilder: (context, index) {
              final isActive = index == _currentIndex;
              return GestureDetector(
                onTap: () => _goTo(index),
                child: AnimatedScale(
                  scale: isActive ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: _thumbWidth,
                    height: _thumbHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? AppColors.secondary
                            : Colors.white.withValues(alpha: 0.15),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CachedNetworkImage(
                        imageUrl: widget.photos[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white.withValues(alpha: 0.06),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo page — InteractiveViewer + CachedNetworkImage shimmer
// ---------------------------------------------------------------------------

class _PhotoPage extends StatelessWidget {
  final String url;
  final void Function(double scale)? onScaleChanged;

  const _PhotoPage({required this.url, this.onScaleChanged});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 3.5,
      minScale: 1.0,
      onInteractionUpdate: (details) {
        onScaleChanged?.call(details.scale);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (context, url) => _ShimmerPlaceholder(),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white.withValues(alpha: 0.30),
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ivory shimmer placeholder (matches editorial background tone)
// ---------------------------------------------------------------------------

class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Color.lerp(
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.10),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dark editorial backdrop with a subtle vignette
// ---------------------------------------------------------------------------

class _Backdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // #171311 at 0.96 — éditorial, pas noir pur
        color: const Color(0xFF171311).withValues(alpha: 0.96),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFF171311).withValues(alpha: 0.92),
            const Color(0xFF0A0807).withValues(alpha: 0.98),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation arrows (left / right)
// ---------------------------------------------------------------------------

enum _ArrowDirection { left, right }

class _NavArrow extends StatefulWidget {
  final _ArrowDirection direction;
  final VoidCallback onTap;
  final bool enabled;

  const _NavArrow({
    required this.direction,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.direction == _ArrowDirection.left;

    return Positioned(
      left: isLeft ? 24 : null,
      right: isLeft ? null : 24,
      top: 0,
      bottom: 96, // above thumb strip
      child: Center(
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(
                  alpha: _hovered && widget.enabled ? 0.50 : 0.30,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                isLeft
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.white.withValues(
                  alpha: widget.enabled ? (_hovered ? 1.0 : 0.75) : 0.25,
                ),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Close button — top-right circular ivory-tinted
// ---------------------------------------------------------------------------

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: _hovered ? 0.18 : 0.10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
