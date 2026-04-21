import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage Service for Profile Images
///
/// Handles uploading profile images to Firebase Storage.
/// Images are stored in the 'profile_images' folder with user-specific paths.
class FirebaseProfileImageService {
  final FirebaseStorage _storage;

  FirebaseProfileImageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload profile image for a user
  ///
  /// Parameters:
  /// - [file] Image file to upload
  /// - [userId] User ID for folder structure
  ///
  /// Returns download URL of the uploaded image
  Future<String> uploadProfileImage(File file, {required String userId}) async {
    try {
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';
      final ref = _storage.ref().child('profile_images').child(userId).child(fileName);

      debugPrint('[FirebaseProfileImageService] Starting upload: ${file.path}');

      // Upload file
      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('[FirebaseProfileImageService] Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[FirebaseProfileImageService] Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[FirebaseProfileImageService] Upload error: $e');
      rethrow;
    }
  }

  /// Delete old profile image
  ///
  /// Parameters:
  /// - [downloadUrl] Full download URL of the image to delete
  Future<bool> deleteProfileImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('[FirebaseProfileImageService] Deleted: $downloadUrl');
      return true;
    } catch (e) {
      debugPrint('[FirebaseProfileImageService] Delete error: $e');
      return false;
    }
  }

  /// Delete all profile images for a user
  ///
  /// Useful when deleting account or cleaning up old images
  Future<void> deleteAllUserImages(String userId) async {
    try {
      final listResult = await _storage.ref('profile_images').child(userId).listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      debugPrint('[FirebaseProfileImageService] Deleted ${listResult.items.length} images for user $userId');
    } catch (e) {
      debugPrint('[FirebaseProfileImageService] Delete all error: $e');
    }
  }
}
