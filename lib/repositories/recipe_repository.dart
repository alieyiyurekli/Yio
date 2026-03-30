import '../models/user_recipe_model.dart';

/// Abstract repository interface for recipe data operations
/// This allows easy switching between different data sources (local, Firebase, etc.)
abstract class RecipeRepository {
  /// Save a new recipe
  Future<bool> saveRecipe(UserRecipeModel recipe);
  
  /// Get all saved recipes
  Future<List<UserRecipeModel>> getAllRecipes();
  
  /// Get a recipe by ID
  Future<UserRecipeModel?> getRecipeById(String id);
  
  /// Update an existing recipe
  Future<bool> updateRecipe(UserRecipeModel recipe);
  
  /// Delete a recipe
  Future<bool> deleteRecipe(String id);
  
  /// Clear all recipes
  Future<bool> clearAll();
  
  /// Get recipe count
  Future<int> getRecipeCount();
}
