import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../core/constants/colors.dart';

/// A video player widget with play/pause controls
/// Supports both local files and network URLs
/// Auto-pauses when not visible
class VideoMediaPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final Widget? placeholder;

  const VideoMediaPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.placeholder,
  });

  @override
  State<VideoMediaPlayer> createState() => _VideoMediaPlayerState();
}

class _VideoMediaPlayerState extends State<VideoMediaPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final isLocalFile = widget.videoUrl.startsWith('/') || 
                         widget.videoUrl.startsWith('file://');

      if (isLocalFile) {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      }

      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        if (widget.autoPlay) {
          _controller.play();
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _isInitialized = false;
      _hasError = false;
      _initializeVideo();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-detector-${widget.videoUrl}'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.5;
        
        if (_isVisible != isVisible) {
          setState(() {
            _isVisible = isVisible;
          });
          
          // Auto-pause when not visible
          if (!isVisible && _controller.value.isPlaying) {
            _controller.pause();
            setState(() {
              _isPlaying = false;
            });
          }
        }
      },
      child: _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildThumbnail();
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          _buildPlayPauseOverlay(),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.thumbnailUrl != null)
          _buildThumbnailImage()
        else
          _buildDefaultPlaceholder(),
        Center(
          child: GestureDetector(
            onTap: () {
              if (_isInitialized) {
                _togglePlayPause();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailImage() {
    final isLocalFile = widget.thumbnailUrl!.startsWith('/') || 
                        widget.thumbnailUrl!.startsWith('file://');

    if (isLocalFile) {
      return Image.file(
        File(widget.thumbnailUrl!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPlaceholder();
        },
      );
    } else {
      return Image.network(
        widget.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPlaceholder();
        },
      );
    }
  }

  Widget _buildDefaultPlaceholder() {
    return widget.placeholder ?? 
           Container(
             color: Colors.black,
             child: const Center(
               child: CircularProgressIndicator(
                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
               ),
             ),
           );
  }

  Widget _buildPlayPauseOverlay() {
    if (!_isPlaying) {
      return Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 64,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'Video yüklenemedi',
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
