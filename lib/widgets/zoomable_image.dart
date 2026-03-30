import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/colors.dart';

/// A zoomable image widget using PhotoView with cached network images
/// Supports both local files and network URLs
class ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final VoidCallback? onTap;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.onTap,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  bool _isLocalFile = false;

  @override
  void initState() {
    super.initState();
    _isLocalFile = widget.imageUrl.startsWith('/') || 
                   widget.imageUrl.startsWith('file://');
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: _getImageProvider(),
      heroAttributes: widget.heroTag != null 
          ? PhotoViewHeroAttributes(tag: widget.heroTag!)
          : null,
      onTapDown: widget.onTap != null
          ? (context, details, controllerValue) => widget.onTap!()
          : null,
      loadingBuilder: (context, event) => _buildLoadingIndicator(),
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      backgroundDecoration: const BoxDecoration(
        color: Colors.black,
      ),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2.5,
      initialScale: PhotoViewComputedScale.contained,
      basePosition: Alignment.center,
    );
  }

  /// Get the appropriate image provider based on URL type
  ImageProvider _getImageProvider() {
    if (_isLocalFile) {
      return FileImage(File(widget.imageUrl));
    } else {
      return CachedNetworkImageProvider(
        widget.imageUrl,
        cacheKey: widget.imageUrl,
      );
    }
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget when image fails to load
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'Görsel yüklenemedi',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simplified zoomable image widget for use in galleries
/// Without full-screen capability
class ZoomableImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ZoomableImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalFile = imageUrl.startsWith('/') || 
                        imageUrl.startsWith('file://');

    if (isLocalFile) {
      return Image.file(
        File(imageUrl),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) => 
            placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) => 
            errorWidget ?? _buildDefaultErrorWidget(),
      );
    }
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
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
  }
}
