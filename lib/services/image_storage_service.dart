import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for storing recipe images permanently in app documents directory
class ImageStorageService {
  static const String _recipeImagesFolder = 'recipe_images';

  /// Get the app's documents directory
  static Future<Directory> _getAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recipeImagesDir = Directory('${appDir.path}/$_recipeImagesFolder');
    
    // Create directory if it doesn't exist
    if (!await recipeImagesDir.exists()) {
      await recipeImagesDir.create(recursive: true);
    }
    
    return recipeImagesDir;
  }

  /// Save an image file to app documents directory
  /// Returns the new path of the saved image
  static Future<String?> saveImage(File sourceFile, String recipeId, int imageIndex) async {
    try {
      final recipeImagesDir = await _getAppDirectory();
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(sourceFile.path);
      final fileName = '${recipeId}_${imageIndex}_$timestamp$extension';
      final targetPath = '${recipeImagesDir.path}/$fileName';
      
      // Copy file to app directory
      final targetFile = await sourceFile.copy(targetPath);
      
      return targetFile.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  /// Save multiple images for a recipe
  /// Returns list of saved image paths
  static Future<List<String>> saveImages(List<File> imageFiles, String recipeId) async {
    final List<String> savedPaths = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final savedPath = await saveImage(imageFiles[i], recipeId, i);
      if (savedPath != null) {
        savedPaths.add(savedPath);
      }
    }
    
    return savedPaths;
  }

  /// Delete an image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Delete all images for a recipe
  static Future<void> deleteRecipeImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      await deleteImage(path);
    }
  }

  /// Get file extension from path
  static String _getFileExtension(String filePath) {
    final lastIndex = filePath.lastIndexOf('.');
    if (lastIndex != -1 && lastIndex < filePath.length - 1) {
      return filePath.substring(lastIndex);
    }
    return '.jpg'; // Default extension
  }

  /// Check if an image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all recipe images directory size (in bytes)
  static Future<int> getImagesDirectorySize() async {
    try {
      final recipeImagesDir = await _getAppDirectory();
      int totalSize = 0;
      
      await for (final entity in recipeImagesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all recipe images (use with caution)
  static Future<void> clearAllImages() async {
    try {
      final recipeImagesDir = await _getAppDirectory();
      if (await recipeImagesDir.exists()) {
        await recipeImagesDir.delete(recursive: true);
        await recipeImagesDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing images: $e');
    }
  }
}
