import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_recipe_model.dart';
import 'recipe_repository.dart';

/// Firestore implementation of RecipeRepository
///
/// This repository stores recipes in Firebase Firestore cloud database
/// enabling real-time sync across devices and backup.
class FirestoreRecipeRepository implements RecipeRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  // Typed collection reference
  late final CollectionReference<Map<String, dynamic>> _recipesCollection;

  FirestoreRecipeRepository({
    FirebaseFirestore? firestore,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty for Firestore repository');
    }
    _recipesCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('recipes');
  }

  /// Get all recipes as stream (real-time updates)
  Stream<List<UserRecipeModel>> recipesStream() {
    return _recipesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRecipeModel.fromJson(doc.data()))
            .toList());
  }

  /// Get recipes by category
  Stream<List<UserRecipeModel>> recipesByCategoryStream(String category) {
    return _recipesCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRecipeModel.fromJson(doc.data()))
            .toList());
  }

  /// Get recipes by difficulty
  Stream<List<UserRecipeModel>> recipesByDifficultyStream(String difficulty) {
    return _recipesCollection
        .where('difficulty', isEqualTo: difficulty)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRecipeModel.fromJson(doc.data()))
            .toList());
  }

  /// Search recipes by title (prefix search)
  Stream<List<UserRecipeModel>> searchRecipesStream(String query) {
    return _recipesCollection
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRecipeModel.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<bool> saveRecipe(UserRecipeModel recipe) async {
    try {
      await _recipesCollection.doc(recipe.id).set(recipe.toJson());
      debugPrint('Recipe saved to Firestore: ${recipe.id}');
      return true;
    } catch (e) {
      debugPrint('Error saving recipe to Firestore: $e');
      return false;
    }
  }

  @override
  Future<List<UserRecipeModel>> getAllRecipes() async {
    try {
      final snapshot = await _recipesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserRecipeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting recipes from Firestore: $e');
      return [];
    }
  }

  @override
  Future<UserRecipeModel?> getRecipeById(String id) async {
    try {
      final doc = await _recipesCollection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return UserRecipeModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recipe by id: $e');
      return null;
    }
  }

  @override
  Future<bool> updateRecipe(UserRecipeModel updatedRecipe) async {
    try {
      await _recipesCollection
          .doc(updatedRecipe.id)
          .update(updatedRecipe.toJson());
      debugPrint('Recipe updated in Firestore: ${updatedRecipe.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating recipe in Firestore: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteRecipe(String id) async {
    try {
      await _recipesCollection.doc(id).delete();
      debugPrint('Recipe deleted from Firestore: $id');
      return true;
    } catch (e) {
      debugPrint('Error deleting recipe from Firestore: $e');
      return false;
    }
  }

  @override
  Future<bool> clearAll() async {
    try {
      final snapshot = await _recipesCollection.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All recipes cleared from Firestore');
      return true;
    } catch (e) {
      debugPrint('Error clearing recipes from Firestore: $e');
      return false;
    }
  }

  @override
  Future<int> getRecipeCount() async {
    try {
      final snapshot = await _recipesCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting recipe count: $e');
      return 0;
    }
  }

  /// Batch save multiple recipes
  Future<bool> saveBatch(List<UserRecipeModel> recipes) async {
    try {
      final batch = _firestore.batch();

      for (final recipe in recipes) {
        final docRef = _recipesCollection.doc(recipe.id);
        batch.set(docRef, recipe.toJson());
      }

      await batch.commit();
      debugPrint('Batch saved ${recipes.length} recipes to Firestore');
      return true;
    } catch (e) {
      debugPrint('Error batch saving recipes: $e');
      return false;
    }
  }

  /// Get recipes with pagination
  Future<List<UserRecipeModel>> getRecipesPaginated({
    int limit = 20,
    UserRecipeModel? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _recipesCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([startAfter.createdAt.toIso8601String()]);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserRecipeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting paginated recipes: $e');
      return [];
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String recipeId) async {
    try {
      final docRef = _recipesCollection.doc(recipeId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        final currentFavorite = doc.data()!['isFavorite'] as bool? ?? false;
        await docRef.update({'isFavorite': !currentFavorite});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }
}
