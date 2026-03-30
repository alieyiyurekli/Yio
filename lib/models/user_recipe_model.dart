import 'ingredient_model.dart';
import 'recipe_model.dart';

/// Model for user-created recipes
class UserRecipeModel {
  final String id;
  final String title;
  final String instructions;
  final int cookingTime;
  final Difficulty difficulty;
  final String? imagePath; // Deprecated - use imagePaths
  final String? videoPath;
  final List<String> imagePaths; // Multiple images support
  final List<IngredientModel> ingredients;
  final double totalCalories;
  final DateTime createdAt;
  final String category;
  final String cuisine;
  final List<String> tags;

  UserRecipeModel({
    required this.id,
    required this.title,
    required this.instructions,
    required this.cookingTime,
    required this.difficulty,
    this.imagePath,
    this.videoPath,
    List<String>? imagePaths,
    required this.ingredients,
    required this.totalCalories,
    DateTime? createdAt,
    this.category = 'Ana Yemek',
    this.cuisine = 'Türk',
    this.tags = const [],
  }) : imagePaths = imagePaths ?? [],
       createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructions': instructions,
      'cookingTime': cookingTime,
      'difficulty': difficulty.name,
      'imagePath': imagePath,
      'videoPath': videoPath,
      'imagePaths': imagePaths,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'totalCalories': totalCalories,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'cuisine': cuisine,
      'tags': tags,
    };
  }

  /// Create from JSON
  factory UserRecipeModel.fromJson(Map<String, dynamic> json) {
    return UserRecipeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      cookingTime: json['cookingTime'] as int,
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      imagePath: json['imagePath'] as String?,
      videoPath: json['videoPath'] as String?,
      imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? [],
      ingredients: (json['ingredients'] as List)
          .map((i) => IngredientModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String? ?? 'Ana Yemek',
      cuisine: json['cuisine'] as String? ?? 'Türk',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Parse difficulty from JSON string — handles both legacy string values and enum names
  static Difficulty _parseDifficulty(String? value) {
    switch (value?.toLowerCase()) {
      case 'easy':
      case 'kolay':
        return Difficulty.easy;
      case 'hard':
      case 'zor':
        return Difficulty.hard;
      case 'medium':
      case 'orta':
      default:
        return Difficulty.medium;
    }
  }

  /// Copy with method
  UserRecipeModel copyWith({
    String? id,
    String? title,
    String? instructions,
    int? cookingTime,
    Difficulty? difficulty,
    String? imagePath,
    String? videoPath,
    List<String>? imagePaths,
    List<IngredientModel>? ingredients,
    double? totalCalories,
    DateTime? createdAt,
    String? category,
    String? cuisine,
    List<String>? tags,
  }) {
    return UserRecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      cookingTime: cookingTime ?? this.cookingTime,
      difficulty: difficulty ?? this.difficulty,
      imagePath: imagePath ?? this.imagePath,
      videoPath: videoPath ?? this.videoPath,
      imagePaths: imagePaths ?? this.imagePaths,
      ingredients: ingredients ?? this.ingredients,
      totalCalories: totalCalories ?? this.totalCalories,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      tags: tags ?? this.tags,
    );
  }

  /// Convert to Recipe model for use with RecipeCard widget
  Recipe toRecipe() {
    // Create a default chef for user recipes
    final chef = Chef(
      name: 'Sen',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      role: 'Home Cook',
    );

    // Convert ingredients to string list
    final ingredientStrings = ingredients.map((i) {
      return '${i.amount} ${i.unit} ${i.name}';
    }).toList();

    // Prefer first image from imagePaths, fallback to imagePath, then placeholder
    final imageUrl = imagePaths.isNotEmpty
        ? imagePaths[0]
        : (imagePath ?? 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800');

    return Recipe(
      id: id,
      title: title,
      image: imageUrl,
      category: category,
      description: instructions.length > 100
          ? '${instructions.substring(0, 100)}...'
          : instructions,
      calories: totalCalories.toInt(),
      time: cookingTime,
      difficulty: difficulty,
      chef: chef,
      ingredients: ingredientStrings,
      steps: [instructions],
      likes: 0,
      comments: 0,
      isFavorite: false,
    );
  }
}
