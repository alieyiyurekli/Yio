import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Image Compression Utility
///
/// Wraps flutter_image_compress for easy-to-use profile image compression.
class ImageCompressionUtil {
  /// Compress and resize an image file
  ///
  /// Parameters:
  /// - [file] Source image file
  /// - [quality] JPEG quality (1-100), default 85
  /// - [maxWidth] Minimum width in pixels (flutter_image_compress uses min), default 512
  /// - [maxHeight] Minimum height in pixels, default 512
  ///
  /// Returns compressed [File] ready for upload
  static Future<File> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 512,
    int maxHeight = 512,
  }) async {
    try {
      final targetPath =
          '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        rotate: 0,
      );

      if (result == null) {
        debugPrint('[ImageCompressionUtil] Compression failed, using original');
        return file;
      }

      final originalSize = await file.length();
      final compressedSize = await result.length();
      debugPrint(
        '[ImageCompressionUtil] Compressed: ${_formatSize(originalSize)} → ${_formatSize(compressedSize)} '
        '(${(compressedSize / originalSize * 100).toStringAsFixed(1)}%)',
      );

      return File(result.path);
    } catch (e) {
      debugPrint('[ImageCompressionUtil] Error: $e — using original file');
      return file;
    }
  }

  /// Get file size in human-readable format
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get human-readable file size for a file
  static Future<String> getFormattedFileSize(File file) async {
    try {
      final size = await file.length();
      return _formatSize(size);
    } catch (_) {
      return 'Bilinmiyor';
    }
  }
}
