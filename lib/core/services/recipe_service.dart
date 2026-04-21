import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_recipe_model.dart';
import '../constants/app_constants.dart';
import '../../services/firebase_storage_service.dart';

/// Global Recipe Service
///
/// Manages the global `recipes/` collection that contains ALL recipes
/// from all users. This is used for:
/// - Home feed (all recipes, latest first)
/// - Search functionality
/// - Like/favorite system
///
/// User's own recipes are still stored in `users/{uid}/recipes/` for
/// ownership management. When a user creates a recipe, it's written to
/// BOTH collections (denormalization pattern).
class RecipeService {
  final FirebaseFirestore _firestore;

  RecipeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Collection references ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection(AppConstants.recipesCollection);

  DocumentReference<Map<String, dynamic>> _recipeDoc(String id) =>
      _recipesRef.doc(id);

  // ── Create ────────────────────────────────────────────────────────────────────

  /// Create a new recipe with image upload and Firestore save.
  ///
  /// This is the main method for creating recipes. It:
  /// 1. Uploads image to Firebase Storage
  /// 2. Saves to global `recipes/` collection
  /// 3. Returns the recipe ID
  ///
  /// All fields are required except imageFile (can be null).
  Future<String?> createRecipe({
    required String userId,
    required String username,
    required String name,
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> steps,
    required int cookingTime,
    required int calories,
    required String category,
    required String difficulty,
    File? imageFile,
    FirebaseStorageService? storageService,
  }) async {
    try {
      // Generate recipe ID
      final recipeId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null && storageService != null) {
        imageUrl = await storageService.uploadImage(
          imageFile: imageFile,
          recipeId: recipeId,
        );
        debugPrint('[RecipeService] Image uploaded: $imageUrl');
      }

      // Create recipe data
      final recipeData = {
        'id': recipeId,
        'userId': userId,
        'username': username,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'steps': steps,
        'cookingTime': cookingTime,
        'calories': calories,
        'category': category,
        'difficulty': difficulty,
        'imageUrl': imageUrl,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        // Author info
        'authorId': userId,
        'authorName': name,
        'authorUsername': username,
      };

      // Save to Firestore
      await _recipeDoc(recipeId).set(recipeData);
      debugPrint('[RecipeService] Recipe created: $recipeId');
      
      return recipeId;
    } catch (e) {
      debugPrint('[RecipeService] Failed to create recipe: $e');
      rethrow;
    }
  }

  /// Publish a recipe to the global recipes collection.
  ///
  /// This should be called AFTER saving to `users/{uid}/recipes/{id}`.
  /// The recipe data is copied to the global collection with author info.
  Future<void> publishRecipe({
    required String recipeId,
    required UserRecipeModel recipe,
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    String? authorUsername,
  }) async {
    try {
      final recipeData = {
        'id': recipeId,
        'title': recipe.title,
        'instructions': recipe.instructions,
        'cookingTime': recipe.cookingTime,
        'difficulty': recipe.difficulty.name,
        'imagePath': recipe.imagePath,
        'videoPath': recipe.videoPath,
        'imagePaths': recipe.imagePaths,
        'ingredients': recipe.ingredients.map((i) => i.toJson()).toList(),
        'totalCalories': recipe.totalCalories,
        'category': recipe.category,
        'cuisine': recipe.cuisine,
        'tags': recipe.tags,
        'createdAt': Timestamp.fromDate(recipe.createdAt),
        'likesCount': 0,
        // Author info
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'authorUsername': authorUsername,
      };

      await _recipeDoc(recipeId).set(recipeData);
      debugPrint('[RecipeService] Recipe published to global collection: $recipeId');
    } catch (e) {
      debugPrint('[RecipeService] Failed to publish recipe: $e');
      rethrow;
    }
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  /// Stream of all recipes ordered by createdAt (latest first).
  /// Used for the home feed.
  Stream<List<Map<String, dynamic>>> feedStream({int limit = 50}) {
    return _recipesRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Stream of recipes by a specific author.
  Stream<List<Map<String, dynamic>>> recipesByAuthorStream(String authorId) {
    return _recipesRef
        .where('authorId', isEqualTo: authorId)
        // Note: orderBy('createdAt') removed to avoid Firestore index requirement
        // Recipes will be returned in arbitrary order
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Search recipes by title (case-insensitive prefix search).
  Stream<List<Map<String, dynamic>>> searchRecipesStream(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    final normalizedQuery = query.toLowerCase();
    return _recipesRef
        .where('titleLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('titleLower', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
        .orderBy('titleLower')
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Get a single recipe by ID.
  Future<Map<String, dynamic>?> getRecipeById(String id) async {
    try {
      final doc = await _recipeDoc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return {...doc.data()!, 'id': doc.id};
    } catch (e) {
      debugPrint('[RecipeService] Failed to get recipe $id: $e');
      return null;
    }
  }

  /// Stream of a single recipe by ID.
  Stream<Map<String, dynamic>?> getRecipeStream(String id) {
    return _recipeDoc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return {...doc.data()!, 'id': doc.id};
    });
  }

  // ── Update ───────────────────────────────────────────────────────────────────

  /// Increment/decrement the likes count atomically.
  Future<void> updateLikesCount(String recipeId, int delta) async {
    try {
      await _recipeDoc(recipeId).update({
        'likesCount': FieldValue.increment(delta),
      });
      debugPrint('[RecipeService] Updated likesCount for $recipeId by $delta');
    } catch (e) {
      debugPrint('[RecipeService] Failed to update likesCount: $e');
      rethrow;
    }
  }

  /// Update recipe details (e.g., after user edits their own recipe).
  Future<void> updateRecipe(String recipeId, Map<String, dynamic> updates) async {
    try {
      await _recipeDoc(recipeId).update(updates);
      debugPrint('[RecipeService] Recipe updated: $recipeId');
    } catch (e) {
      debugPrint('[RecipeService] Failed to update recipe: $e');
      rethrow;
    }
  
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  /// Delete a recipe from the global collection.
  ///
  /// This should be called AFTER deleting from `users/{uid}/recipes/{id}`.
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _recipeDoc(recipeId).delete();
      debugPrint('[RecipeService] Recipe deleted from global collection: $recipeId');
    } catch (e) {
      debugPrint('[RecipeService] Failed to delete recipe: $e');
      rethrow;
    }
  }
}
