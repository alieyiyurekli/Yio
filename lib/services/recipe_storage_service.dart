import 'package:flutter/foundation.dart';
import '../models/user_recipe_model.dart';
import '../repositories/local_recipe_repository.dart';

/// @deprecated Use [LocalRecipeRepository] directly via dependency injection.
/// This class is kept for backward compatibility only.
/// All new code should use [RecipeRepository] interface injected via Provider.
class RecipeStorageService {
  final LocalRecipeRepository _repository = LocalRecipeRepository();

  /// Save a new recipe
  Future<bool> saveRecipe(UserRecipeModel recipe) async {
    try {
      return await _repository.saveRecipe(recipe);
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      return false;
    }
  }

  /// Get all saved recipes
  Future<List<UserRecipeModel>> getAllRecipes() async {
    try {
      return await _repository.getAllRecipes();
    } catch (e) {
      debugPrint('Error getting recipes: $e');
      return [];
    }
  }

  /// Delete a recipe by ID
  Future<bool> deleteRecipe(String recipeId) async {
    try {
      return await _repository.deleteRecipe(recipeId);
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      return false;
    }
  }

  /// Update an existing recipe
  Future<bool> updateRecipe(UserRecipeModel updatedRecipe) async {
    try {
      return await _repository.updateRecipe(updatedRecipe);
    } catch (e) {
      debugPrint('Error updating recipe: $e');
      return false;
    }
  }

  /// Clear all recipes
  Future<bool> clearAllRecipes() async {
    try {
      return await _repository.clearAll();
    } catch (e) {
      debugPrint('Error clearing recipes: $e');
      return false;
    }
  }

  /// Get recipe count
  Future<int> getRecipeCount() async {
    return await _repository.getRecipeCount();
  }
}
