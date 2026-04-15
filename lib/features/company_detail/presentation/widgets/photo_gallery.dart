import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class PhotoGallery extends StatefulWidget {
  final List<String> photoUrls;
  final double height;

  const PhotoGallery({
    super.key,
    required this.photoUrls,
    this.height = 300,
  });

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return _PlaceholderPhoto(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Photo pages
          PageView.builder(
            controller: _controller,
            itemCount: widget.photoUrls.length,
            itemBuilder: (context, index) {
              return _GalleryPhoto(url: widget.photoUrls[index]);
            },
          ),

          // Gradient overlay at bottom for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),

          // Page dots indicator
          if (widget.photoUrls.length > 1)
            Positioned(
              bottom: AppSpacing.md,
              child: SmoothPageIndicator(
                controller: _controller,
                count: widget.photoUrls.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 7,
                  dotWidth: 7,
                  expansionFactor: 3,
                  spacing: 5,
                  dotColor: Colors.white.withValues(alpha: 0.55),
                  activeDotColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryPhoto extends StatelessWidget {
  final String url;

  const _GalleryPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) => const _PhotoErrorWidget(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _PhotoShimmer();
      },
    );
  }
}

class _PhotoShimmer extends StatelessWidget {
  const _PhotoShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.divider);
  }
}

class _PhotoErrorWidget extends StatelessWidget {
  const _PhotoErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.divider,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textHint,
          size: 48,
        ),
      ),
    );
  }
}

class _PlaceholderPhoto extends StatelessWidget {
  final double height;

  const _PlaceholderPhoto({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.store_rounded, size: 72, color: Colors.white54),
      ),
    );
  }
}
