import 'dart:io';
import 'package:flutter/material.dart';
import '../models/gallery_media_model.dart';
import 'video_media_player.dart';
import '../core/constants/colors.dart';

/// Instagram-style media carousel for recipe images and videos
/// Features:
/// - Horizontal swipe between media items
/// - Page indicator dots
/// - Mixed media support (images and videos)
/// - Auto-pause videos when not visible
/// - Smooth animations
/// - Gesture-safe architecture
class RecipeMediaCarousel extends StatefulWidget {
  final List<GalleryMediaModel> mediaItems;
  final double height;
  final bool showIndicator;
  final ValueChanged<int>? onPageChanged;
  final bool autoPlayVideo;

  const RecipeMediaCarousel({
    super.key,
    required this.mediaItems,
    this.height = 300,
    this.showIndicator = true,
    this.onPageChanged,
    this.autoPlayVideo = false,
  });

  @override
  State<RecipeMediaCarousel> createState() => _RecipeMediaCarouselState();
}

class _RecipeMediaCarouselState extends State<RecipeMediaCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Debug log
    debugPrint('=== RECIPE MEDIA CAROUSEL INIT ===');
    debugPrint('Media items count: ${widget.mediaItems.length}');
    for (int i = 0; i < widget.mediaItems.length; i++) {
      debugPrint('Item $i: type=${widget.mediaItems[i].type}, url=${widget.mediaItems[i].url}');
    }
    debugPrint('=====================================');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    widget.onPageChanged?.call(page);
    debugPrint('Page changed to: $page');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return _buildEmptyWidget();
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Media PageView
          _buildMediaPageView(),
          
          // Page indicator dots
          if (widget.showIndicator && widget.mediaItems.length > 1)
            _buildPageIndicator(),
          
          // Media type indicator
          if (widget.mediaItems[_currentPage].type.isVideo)
            _buildVideoIndicator(),
        ],
      ),
    );
  }

  Widget _buildMediaPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.mediaItems.length,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        final mediaItem = widget.mediaItems[index];
        debugPrint('Building item $index: type=${mediaItem.type}, url=${mediaItem.url}');
        return SizedBox.expand(
          child: _buildMediaItem(mediaItem, index),
        );
      },
    );
  }

  Widget _buildMediaItem(GalleryMediaModel mediaItem, int index) {
    if (mediaItem.type.isImage) {
      return _buildImageItem(mediaItem.url, index);
    } else if (mediaItem.type.isVideo) {
      return VideoMediaPlayer(
        videoUrl: mediaItem.url,
        thumbnailUrl: mediaItem.thumbnail,
        autoPlay: widget.autoPlayVideo && index == 0,
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildImageItem(String imageUrl, int index) {
    final isLocalFile = imageUrl.startsWith('/') ||
                        imageUrl.startsWith('file://');

    debugPrint('Building image item $index: isLocalFile=$isLocalFile, url=$imageUrl');

    if (isLocalFile) {
      final cleanPath = imageUrl.replaceFirst('file://', '');
      debugPrint('Loading local file: $cleanPath');
      debugPrint('File exists: ${File(cleanPath).existsSync()}');
      
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Image.file(
          File(cleanPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image: $error');
            return _buildErrorWidget();
          },
        ),
      );
    } else {
      debugPrint('Loading network image: $imageUrl');
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingIndicator();
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildErrorWidget();
          },
        ),
      );
    }
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.mediaItems.length,
          (index) => _buildIndicatorDot(index),
        ),
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildVideoIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'VIDEO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Görsel yok',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simplified version of the media carousel for use in cards
/// Without full-page capability
class RecipeMediaCarouselMini extends StatelessWidget {
  final List<GalleryMediaModel> mediaItems;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;

  const RecipeMediaCarouselMini({
    super.key,
    required this.mediaItems,
    this.height = 200,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaItems.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 48,
            color: AppColors.textLight,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: mediaItems.length,
            itemBuilder: (context, index) {
              final mediaItem = mediaItems[index];
              
              if (mediaItem.type.isImage) {
                return _buildSimpleImage(mediaItem.url);
              } else if (mediaItem.type.isVideo) {
                return _buildVideoThumbnail(mediaItem);
              }
              
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleImage(String imageUrl) {
    final isLocalFile = imageUrl.startsWith('/') || 
                        imageUrl.startsWith('file://');

    if (isLocalFile) {
      return Image.file(
        File(imageUrl.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.background,
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.background,
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildVideoThumbnail(GalleryMediaModel mediaItem) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (mediaItem.thumbnail != null)
          _buildSimpleImage(mediaItem.thumbnail!)
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
