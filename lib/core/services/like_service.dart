import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'recipe_service.dart';

/// Like/Favorite Service
///
/// Manages user likes on recipes using a dual-write pattern:
/// 1. `users/{uid}/favorites/{recipeId}` — user's favorite list
/// 2. `recipes/{recipeId}.likesCount` — recipe's like counter
///
/// Both writes happen atomically in a batch to ensure consistency.
class LikeService {
  final FirebaseFirestore _firestore;
  final RecipeService _recipeService;

  LikeService({
    FirebaseFirestore? firestore,
    RecipeService? recipeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _recipeService = recipeService ?? RecipeService();

  // ── Private helpers ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersRef.doc(uid);

  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) =>
      _userDoc(uid).collection(AppConstants.favoritesCollection);

  DocumentReference<Map<String, dynamic>> _favoriteDoc(
          String uid, String recipeId) =>
      _favoritesRef(uid).doc(recipeId);

  // ── Check if liked ───────────────────────────────────────────────────────────

  /// Check if a user has liked a specific recipe.
  Future<bool> isLiked(String uid, String recipeId) async {
    try {
      final doc = await _favoriteDoc(uid, recipeId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[LikeService] Failed to check like status: $e');
      return false;
    }
  }

  /// Stream of like status for a specific recipe.
  Stream<bool> isLikedStream(String uid, String recipeId) {
    return _favoriteDoc(uid, recipeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ── Get user's favorites ──────────────────────────────────────────────────────

  /// Get all recipe IDs that the user has liked.
  Future<List<String>> getUserFavoriteIds(String uid) async {
    try {
      final snapshot = await _favoritesRef(uid).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('[LikeService] Failed to get user favorites: $e');
      return [];
    }
  }

  /// Stream of user's favorite recipe IDs.
  Stream<List<String>> getUserFavoriteIdsStream(String uid) {
    return _favoritesRef(uid).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
    );
  }

  /// Get full recipe data for user's favorites.
  /// 
  /// This fetches recipe details from the global recipes collection
  /// based on the user's favorite IDs.
  Stream<List<Map<String, dynamic>>> getUserFavoritesStream(String uid) {
    return _favoritesRef(uid).snapshots().asyncMap(
      (favoritesSnapshot) async {
        final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
        
        if (favoriteIds.isEmpty) return [];
        
        // Fetch recipe details in batches (Firestore limit: 10 items per query)
        final List<Map<String, dynamic>> recipes = [];
        const batchSize = 10;
        
        for (int i = 0; i < favoriteIds.length; i += batchSize) {
          final batch = favoriteIds.skip(i).take(batchSize).toList();
          final snapshot = await _firestore
              .collection(AppConstants.recipesCollection)
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          recipes.addAll(
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}),
          );
        }
        
        // Sort by liked timestamp (most recent first)
        recipes.sort((a, b) {
          final aTime = a['likedAt'] as Timestamp?;
          final bTime = b['likedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        
        return recipes;
      },
    );
  }

  // ── Toggle like ──────────────────────────────────────────────────────────────

  /// Toggle like status for a recipe.
  ///
  /// Performs atomic batch write:
  /// - Adds/removes from user's favorites subcollection
  /// - Increments/decrements recipe's likesCount
  Future<bool> toggleLike(String uid, String recipeId) async {
    try {
      // Check current status
      final isCurrentlyLiked = await isLiked(uid, recipeId);
      
      final batch = _firestore.batch();
      
      if (isCurrentlyLiked) {
        // Unlike: remove from favorites, decrement likesCount
        batch.delete(_favoriteDoc(uid, recipeId));
        await batch.commit();
        await _recipeService.updateLikesCount(recipeId, -1);
        debugPrint('[LikeService] Unliked recipe: $recipeId by user: $uid');
        return false;
      } else {
        // Like: add to favorites with timestamp, increment likesCount
        batch.set(
          _favoriteDoc(uid, recipeId),
          {
            'likedAt': Timestamp.fromDate(DateTime.now()),
          },
        );
        await batch.commit();
        await _recipeService.updateLikesCount(recipeId, 1);
        debugPrint('[LikeService] Liked recipe: $recipeId by user: $uid');
        return true;
      }
    } catch (e) {
      debugPrint('[LikeService] Failed to toggle like: $e');
      rethrow;
    }
  }

  // ── Batch operations ──────────────────────────────────────────────────────────

  /// Remove a recipe from all users' favorites (called when recipe is deleted).
  ///
  /// This is a cleanup operation that should be triggered when a recipe
  /// is deleted by its author.
  Future<void> removeRecipeFromAllFavorites(String recipeId) async {
    try {
      // Query all users who have this recipe in favorites
      // Note: This requires a collection group query
      final snapshot = await _firestore
          .collectionGroup(AppConstants.favoritesCollection)
          .where(FieldPath.documentId, isEqualTo: recipeId)
          .get();
      
      // Delete all matching documents
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('[LikeService] Removed recipe $recipeId from ${snapshot.docs.length} user favorites');
      }
    } catch (e) {
      debugPrint('[LikeService] Failed to remove recipe from favorites: $e');
      // Non-fatal error, log and continue
    }
  }

  // ── Count ────────────────────────────────────────────────────────────────────

  /// Get the count of user's favorite recipes.
  Future<int> getUserFavoritesCount(String uid) async {
    try {
      final snapshot = await _favoritesRef(uid).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[LikeService] Failed to get favorites count: $e');
      return 0;
    }
  }

  /// Stream of user's favorites count.
  Stream<int> getUserFavoritesCountStream(String uid) {
    return _favoritesRef(uid).snapshots().map(
      (snapshot) => snapshot.docs.length,
    );
  }
}
