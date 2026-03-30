import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Firebase Cloud Storage Service
///
/// Handles all file upload/download operations:
/// - Recipe images
/// - Recipe videos
/// - User profile photos
/// - Batch uploads
class FirebaseStorageService {
  final FirebaseStorage _storage;
  final String userId;

  FirebaseStorageService({
    FirebaseStorage? storage,
    required this.userId,
  }) : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a single image file
  /// Returns the download URL
  Future<String?> uploadImage({
    required File imageFile,
    required String recipeId,
    int imageIndex = 0,
  }) async {
    try {
      final fileName = '${recipeId}_$imageIndex${path.extension(imageFile.path)}';
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('recipes')
          .child(recipeId)
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('Image uploaded: $downloadUrl');
        return downloadUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images for a recipe
  /// Returns list of download URLs
  Future<List<String>> uploadImages({
    required List<File> imageFiles,
    required String recipeId,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(
        imageFile: imageFiles[i],
        recipeId: recipeId,
        imageIndex: i,
      );
      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }

  /// Upload a video file
  /// Returns the download URL
  Future<String?> uploadVideo({
    required File videoFile,
    required String recipeId,
  }) async {
    try {
      final fileName = '${recipeId}_video${path.extension(videoFile.path)}';
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('recipes')
          .child(recipeId)
          .child(fileName);

      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('Video uploaded: $downloadUrl');
        return downloadUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return null;
    }
  }

  /// Upload user profile photo
  /// Returns the download URL
  Future<String?> uploadProfilePhoto(File photoFile) async {
    try {
      final fileName = 'profile_photo${path.extension(photoFile.path)}';
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child(fileName);

      final uploadTask = ref.putFile(photoFile);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('Profile photo uploaded: $downloadUrl');
        return downloadUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Delete a file from storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('File deleted: $fileUrl');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Delete all files for a recipe
  Future<bool> deleteRecipeFiles(String recipeId) async {
    try {
      final recipeRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('recipes')
          .child(recipeId);

      final listResult = await recipeRef.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      for (final prefix in listResult.prefixes) {
        final subList = await prefix.listAll();
        for (final item in subList.items) {
          await item.delete();
        }
      }

      debugPrint('Recipe files deleted: $recipeId');
      return true;
    } catch (e) {
      debugPrint('Error deleting recipe files: $e');
      return false;
    }
  }

  /// Get upload progress stream
  Stream<TaskSnapshot> getUploadProgress(String uploadTaskId) {
    // This would require tracking upload tasks
    // For now, return an empty stream
    return const Stream.empty();
  }

  /// Upload with progress callback
  Future<String?> uploadWithProgress({
    required File file,
    required String recipeId,
    required Function(double progress) onProgress,
  }) async {
    try {
      final fileName = '${recipeId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('recipes')
          .child(recipeId)
          .child(fileName);

      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading with progress: $e');
      return null;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Get total storage used by user
  Future<int> getUserStorageSize() async {
    try {
      final userRef = _storage.ref().child('users').child(userId);
      int totalSize = 0;

      await _calculateFolderSize(userRef, totalSize);
      return totalSize;
    } catch (e) {
      debugPrint('Error getting user storage size: $e');
      return 0;
    }
  }

  Future<void> _calculateFolderSize(Reference ref, int totalSize) async {
    try {
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      for (final prefix in listResult.prefixes) {
        await _calculateFolderSize(prefix, totalSize);
      }
    } catch (e) {
      debugPrint('Error calculating folder size: $e');
    }
  }
}
