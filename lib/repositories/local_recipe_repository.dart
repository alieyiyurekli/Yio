import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_recipe_model.dart';
import 'recipe_repository.dart';

/// Local implementation of RecipeRepository using SharedPreferences
/// This stores recipes locally on the device
class LocalRecipeRepository implements RecipeRepository {
  static const String _recipesKey = 'user_recipes';
  
  /// Singleton instance of SharedPreferences
  /// Cached to avoid repeated getInstance() calls
  static SharedPreferences? _prefsInstance;
  
  /// Get SharedPreferences instance (cached singleton)
  Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }
  
  @override
  Future<bool> saveRecipe(UserRecipeModel recipe) async {
    try {
      final prefs = await _prefs;
      final recipes = await getAllRecipes();
      
      // Add new recipe
      recipes.add(recipe);
      
      // Convert to JSON
      final recipesJson = recipes.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(recipesJson);
      
      // Save to SharedPreferences
      return await prefs.setString(_recipesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      return false;
    }
  }
  
  @override
  Future<List<UserRecipeModel>> getAllRecipes() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(_recipesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => UserRecipeModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting recipes: $e');
      return [];
    }
  }
  
  @override
  Future<UserRecipeModel?> getRecipeById(String id) async {
    try {
      final recipes = await getAllRecipes();
      return recipes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<bool> updateRecipe(UserRecipeModel updatedRecipe) async {
    try {
      final prefs = await _prefs;
      final recipes = await getAllRecipes();
      
      // Find and update recipe
      final index = recipes.indexWhere((r) => r.id == updatedRecipe.id);
      if (index != -1) {
        recipes[index] = updatedRecipe;
        
        // Save updated list
        final recipesJson = recipes.map((r) => r.toJson()).toList();
        final jsonString = jsonEncode(recipesJson);
        
        return await prefs.setString(_recipesKey, jsonString);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating recipe: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteRecipe(String id) async {
    try {
      final prefs = await _prefs;
      final recipes = await getAllRecipes();
      
      // Remove recipe with matching ID
      recipes.removeWhere((r) => r.id == id);
      
      // Save updated list
      final recipesJson = recipes.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(recipesJson);
      
      return await prefs.setString(_recipesKey, jsonString);
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      return false;
    }
  }
  
  @override
  Future<bool> clearAll() async {
    try {
      final prefs = await _prefs;
      return await prefs.remove(_recipesKey);
    } catch (e) {
      debugPrint('Error clearing recipes: $e');
      return false;
    }
  }
  
  @override
  Future<int> getRecipeCount() async {
    final recipes = await getAllRecipes();
    return recipes.length;
  }
}
