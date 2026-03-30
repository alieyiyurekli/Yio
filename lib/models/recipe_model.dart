import 'package:flutter/material.dart';

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

class Chef {
  final String name;
  final String avatar;
  final String role;

  Chef({
    required this.name,
    required this.avatar,
    required this.role,
  });
}

class Ingredient {
  final String name;
  final String? amount;
  bool isChecked;

  Ingredient({
    required this.name,
    this.amount,
    this.isChecked = false,
  });
}

class RecipeStep {
  final int stepNumber;
  final String description;
  final String? image;

  RecipeStep({
    required this.stepNumber,
    required this.description,
    this.image,
  });
}

class Recipe {
  final String id;
  final String title;
  final String image;
  final String category;
  final String description;
  final int calories;
  final int time; // in minutes
  final Difficulty difficulty;
  final Chef chef;
  final List<String> ingredients;
  final List<String> steps;
  int likes;
  int comments;
  bool isFavorite;
  final String? cuisine;
  final List<String>? tags;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.description,
    required this.calories,
    required this.time,
    required this.difficulty,
    required this.chef,
    required this.ingredients,
    required this.steps,
    this.likes = 0,
    this.comments = 0,
    this.isFavorite = false,
    this.cuisine,
    this.tags,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? image,
    String? category,
    String? description,
    int? calories,
    int? time,
    Difficulty? difficulty,
    Chef? chef,
    List<String>? ingredients,
    List<String>? steps,
    int? likes,
    int? comments,
    bool? isFavorite,
    String? cuisine,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      category: category ?? this.category,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      time: time ?? this.time,
      difficulty: difficulty ?? this.difficulty,
      chef: chef ?? this.chef,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isFavorite: isFavorite ?? this.isFavorite,
      cuisine: cuisine ?? this.cuisine,
      tags: tags ?? this.tags,
    );
  }
}

