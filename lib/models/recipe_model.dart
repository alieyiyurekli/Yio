import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Difficulty {
  easy,
  medium,
  hard,
}

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  Color get color {
    switch (this) {
      case Difficulty.easy:
        return const Color(0xFF4CAF50);
      case Difficulty.medium:
        return const Color(0xFFFFA726);
      case Difficulty.hard:
        return const Color(0xFFEF5350);
    }
  }
}

/// Chef/Author information
class Chef {
  final String id;
  final String name;
  final String avatar;
  final String role;

  const Chef({
    required this.id,
    required this.name,
    required this.avatar,
    required this.role,
  });

  /// Create Chef from Firestore user document
  factory Chef.fromFirestore(Map<String, dynamic> data) {
    return Chef(
      id: data['uid'] as String? ?? '',
      name: data['displayName'] as String? ?? 'Anonymous',
      avatar: data['photoUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'Home Cook',
    );
  }

  Chef copyWith({
    String? id,
    String? name,
    String? avatar,
    String? role,
  }) {
    return Chef(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
    );
  }
}

/// Single ingredient for recipe
class Ingredient {
  final String name;
  final String? amount;
  final String? unit;
  bool isChecked;

  Ingredient({
    required this.name,
    this.amount,
    this.unit,
    this.isChecked = false,
  });

  /// Create from Firestore ingredient map
  factory Ingredient.fromFirestore(Map<String, dynamic> data) {
    return Ingredient(
      name: data['name'] as String? ?? '',
      amount: data['amount']?.toString(),
      unit: data['unit'] as String?,
      isChecked: data['isChecked'] as bool? ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'isChecked': isChecked,
    };
  }

  String get displayText {
    final parts = <String>[];
    if (amount != null && amount!.isNotEmpty) parts.add(amount!);
    if (unit != null && unit!.isNotEmpty) parts.add(unit!);
    parts.add(name);
    return parts.join(' ');
  }

  Ingredient copyWith({
    String? name,
    String? amount,
    String? unit,
    bool? isChecked,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

/// Single cooking step
class RecipeStep {
  final int stepNumber;
  final String description;
  final String? image;
  final int? timeMinutes;

  const RecipeStep({
    required this.stepNumber,
    required this.description,
    this.image,
    this.timeMinutes,
  });

  /// Create from Firestore step map
  factory RecipeStep.fromFirestore(Map<String, dynamic> data) {
    return RecipeStep(
      stepNumber: data['stepNumber'] as int? ?? 0,
      description: data['description'] as String? ?? '',
      image: data['image'] as String?,
      timeMinutes: data['timeMinutes'] as int?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'stepNumber': stepNumber,
      'description': description,
      'image': image,
      'timeMinutes': timeMinutes,
    };
  }

  RecipeStep copyWith({
    int? stepNumber,
    String? description,
    String? image,
    int? timeMinutes,
  }) {
    return RecipeStep(
      stepNumber: stepNumber ?? this.stepNumber,
      description: description ?? this.description,
      image: image ?? this.image,
      timeMinutes: timeMinutes ?? this.timeMinutes,
    );
  }
}

/// Complete recipe model
class Recipe {
  final String id;
  final String title;
  final String image;
  final String category;
  final String description;
  final int calories;
  final int cookingTime; // in minutes
  final Difficulty difficulty;
  final Chef chef;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final int likes;
  final int saves;
  final int comments;
  final bool isFavorite;
  final bool isSaved;
  final String? cuisine;
  final List<String>? tags;
  final DateTime? createdAt;
  final List<String>? imagePaths; // Additional images

  /// Backward compatibility: alias for cookingTime
  int get time => cookingTime;

  const Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.description,
    required this.calories,
    required this.cookingTime,
    required this.difficulty,
    required this.chef,
    required this.ingredients,
    required this.steps,
    this.likes = 0,
    this.saves = 0,
    this.comments = 0,
    this.isFavorite = false,
    this.isSaved = false,
    this.cuisine,
    this.tags,
    this.createdAt,
    this.imagePaths,
  });

  /// Create Recipe from Firestore document
  factory Recipe.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final List<Ingredient> ingredients = [];
    if (data['ingredients'] is List) {
      for (var ing in data['ingredients'] as List) {
        if (ing is Map<String, dynamic>) {
          ingredients.add(Ingredient.fromFirestore(ing));
        }
      }
    }

    final List<RecipeStep> steps = [];
    if (data['steps'] is List) {
      for (var step in data['steps'] as List) {
        if (step is Map<String, dynamic>) {
          steps.add(RecipeStep.fromFirestore(step));
        }
      }
    }

    return Recipe(
      id: docId,
      title: data['title'] as String? ?? '',
      image: data['image'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      cookingTime: (data['cookingTime'] as num?)?.toInt() ?? 30,
      difficulty: _parseDifficulty(data['difficulty'] as String?),
      chef: Chef.fromFirestore(data['author'] as Map<String, dynamic>? ?? {}),
      ingredients: ingredients,
      steps: steps,
      likes: (data['likesCount'] as num?)?.toInt() ?? 0,
      saves: (data['savesCount'] as num?)?.toInt() ?? 0,
      comments: (data['commentsCount'] as num?)?.toInt() ?? 0,
      isFavorite: false,
      isSaved: false,
      cuisine: data['cuisine'] as String?,
      tags: (data['tags'] as List?)?.cast<String>(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as dynamic).toDate()
          : null,
      imagePaths: (data['imagePaths'] as List?)?.cast<String>(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'image': image,
      'category': category,
      'description': description,
      'calories': calories,
      'cookingTime': cookingTime,
      'difficulty': difficulty.displayName.toLowerCase(),
      'author': {
        'uid': chef.id,
        'displayName': chef.name,
        'photoUrl': chef.avatar,
        'role': chef.role,
      },
      'ingredients': ingredients.map((i) => i.toFirestore()).toList(),
      'steps': steps.map((s) => s.toFirestore()).toList(),
      'cuisine': cuisine,
      'tags': tags,
      'createdAt': createdAt,
      'imagePaths': imagePaths,
    };
  }

  /// Copy with modifications
  Recipe copyWith({
    String? id,
    String? title,
    String? image,
    String? category,
    String? description,
    int? calories,
    int? cookingTime,
    Difficulty? difficulty,
    Chef? chef,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    int? likes,
    int? saves,
    int? comments,
    bool? isFavorite,
    bool? isSaved,
    String? cuisine,
    List<String>? tags,
    DateTime? createdAt,
    List<String>? imagePaths,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      category: category ?? this.category,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      cookingTime: cookingTime ?? this.cookingTime,
      difficulty: difficulty ?? this.difficulty,
      chef: chef ?? this.chef,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      likes: likes ?? this.likes,
      saves: saves ?? this.saves,
      comments: comments ?? this.comments,
      isFavorite: isFavorite ?? this.isFavorite,
      isSaved: isSaved ?? this.isSaved,
      cuisine: cuisine ?? this.cuisine,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, category: $category)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

/// Helper to parse difficulty from string
Difficulty _parseDifficulty(String? value) {
  if (value == null) return Difficulty.medium;
  
  switch (value.toLowerCase()) {
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
