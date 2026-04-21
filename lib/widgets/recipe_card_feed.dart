import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import 'recipe_card.dart';

/// Example parent widget demonstrating Firestore + Auth integration with RecipeCard
/// 
/// This widget shows how to:
/// - Stream recipes from Firestore
/// - Read current user from FirebaseAuth
/// - Determine isLiked / isSaved from user document
/// - Pass callbacks that update Firestore safely
class RecipeCardFeed extends StatelessWidget {
  const RecipeCardFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login to view recipes'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recipes found'));
        }

        final recipeDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: recipeDocs.length,
          padding: const EdgeInsets.only(bottom: 100),
          itemBuilder: (context, index) {
            final recipeDoc = recipeDocs[index];
            final recipeData = recipeDoc.data() as Map<String, dynamic>;
            final recipeId = recipeDoc.id;

            return _RecipeCardWrapper(
              recipeId: recipeId,
              recipeData: recipeData,
              currentUserId: currentUser.uid,
            );
          },
        );
      },
    );
  }
}

/// Wrapper widget that handles user-specific state for each recipe card
class _RecipeCardWrapper extends StatelessWidget {
  final String recipeId;
  final Map<String, dynamic> recipeData;
  final String currentUserId;

  const _RecipeCardWrapper({
    required this.recipeId,
    required this.recipeData,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Stream user document to get real-time like/save state
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

        // Determine if recipe is liked/saved by current user
        final likedRecipes = userData?['likedRecipes'] as List<dynamic>? ?? [];
        final savedRecipes = userData?['savedRecipes'] as List<dynamic>? ?? [];

        final isLiked = likedRecipes.contains(recipeId);
        final isSaved = savedRecipes.contains(recipeId);

        // Get like/save counts from recipe document
        final likesCount = recipeData['likesCount'] as int? ?? 0;
        final savesCount = recipeData['savesCount'] as int? ?? 0;

        // Map Firestore data to Recipe model
        final recipe = _mapToRecipe(recipeId, recipeData, likesCount, savesCount);

        return RecipeCard(
          recipe: recipe,
          isLiked: isLiked,
          isSaved: isSaved,
          onTap: () {
            // Navigate to recipe detail
            Navigator.of(context).pushNamed(
              '/recipe-detail',
              arguments: {'recipeId': recipeId},
            );
          },
          onLike: () => _handleLike(currentUserId, recipeId, isLiked),
          onSave: () => _handleSave(currentUserId, recipeId, isSaved),
          onShare: () => _handleShare(context, recipe),
        );
      },
    );
  }

  /// Handle like/unlike with safe Firestore updates
  Future<void> _handleLike(String userId, String recipeId, bool isCurrentlyLiked) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    final batch = FirebaseFirestore.instance.batch();

    if (isCurrentlyLiked) {
      // Unlike: Remove from user's likedRecipes, decrement recipe likesCount
      batch.update(userRef, {
        'likedRecipes': FieldValue.arrayRemove([recipeId]),
      });
      batch.update(recipeRef, {
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      // Like: Add to user's likedRecipes, increment recipe likesCount
      batch.update(userRef, {
        'likedRecipes': FieldValue.arrayUnion([recipeId]),
      });
      batch.update(recipeRef, {
        'likesCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  /// Handle save/unsave with safe Firestore updates
  Future<void> _handleSave(String userId, String recipeId, bool isCurrentlySaved) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    final batch = FirebaseFirestore.instance.batch();

    if (isCurrentlySaved) {
      // Unsave: Remove from user's savedRecipes, decrement recipe savesCount
      batch.update(userRef, {
        'savedRecipes': FieldValue.arrayRemove([recipeId]),
      });
      batch.update(recipeRef, {
        'savesCount': FieldValue.increment(-1),
      });
    } else {
      // Save: Add to user's savedRecipes, increment recipe savesCount
      batch.update(userRef, {
        'savedRecipes': FieldValue.arrayUnion([recipeId]),
      });
      batch.update(recipeRef, {
        'savesCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  /// Handle share action
  void _handleShare(BuildContext context, Recipe recipe) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share: ${recipe.title}')),
    );
  }

  /// Map Firestore recipe data to Recipe model
  Recipe _mapToRecipe(
    String recipeId,
    Map<String, dynamic> data,
    int likesCount,
    int savesCount,
  ) {
    // Map author data
    final authorData = data['author'] as Map<String, dynamic>? ?? {};
    final chef = Chef(
      id: authorData['uid'] as String? ?? '',
      name: authorData['displayName'] as String? ?? 'Anonymous',
      avatar: authorData['photoUrl'] as String? ?? '',
      role: authorData['role'] as String? ?? 'Home Cook',
    );

    // Map ingredients
    final ingredientsList = data['ingredients'] as List? ?? [];
    final ingredients = ingredientsList.map((ing) {
      if (ing is Map<String, dynamic>) {
        return Ingredient(
          name: ing['name'] as String? ?? '',
          amount: ing['amount']?.toString(),
          unit: ing['unit'] as String?,
        );
      }
      return Ingredient(name: ing.toString());
    }).toList();

    // Map steps
    final stepsList = data['steps'] as List? ?? [];
    final steps = stepsList.asMap().entries.map((entry) {
      return RecipeStep(
        stepNumber: entry.key + 1,
        description: entry.value is Map<String, dynamic>
            ? (entry.value as Map<String, dynamic>)['description'] as String? ?? ''
            : entry.value.toString(),
      );
    }).toList();

    // Map difficulty
    final difficultyStr = data['difficulty'] as String? ?? 'medium';
    Difficulty difficulty;
    switch (difficultyStr.toLowerCase()) {
      case 'easy':
      case 'kolay':
        difficulty = Difficulty.easy;
        break;
      case 'hard':
      case 'zor':
        difficulty = Difficulty.hard;
        break;
      default:
        difficulty = Difficulty.medium;
    }

    // Get image URL
    final imagePaths = data['imagePaths'] as List? ?? [];
    final imageUrl = imagePaths.isNotEmpty
        ? imagePaths[0] as String
        : (data['image'] as String? ?? '');

    return Recipe(
      id: recipeId,
      title: data['title'] as String? ?? '',
      image: imageUrl,
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      cookingTime: (data['cookingTime'] as num?)?.toInt() ?? 30,
      difficulty: difficulty,
      chef: chef,
      ingredients: ingredients,
      steps: steps,
      likes: likesCount,
      saves: savesCount,
      comments: (data['commentsCount'] as num?)?.toInt() ?? 0,
      isFavorite: false,
      isSaved: false,
      cuisine: data['cuisine'] as String?,
      tags: (data['tags'] as List?)?.cast<String>(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      imagePaths: (data['imagePaths'] as List?)?.cast<String>(),
    );
  }
}
