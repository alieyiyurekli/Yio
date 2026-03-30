import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for Firebase Authentication and Firestore
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final int level;
  final int recipeCount;
  final int followersCount;
  final int followingCount;
  final List<String> achievements;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isEmailVerified;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.level = 1,
    this.recipeCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.achievements = const [],
    DateTime? createdAt,
    DateTime? lastActiveAt,
    this.isEmailVerified = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'level': level,
      'recipeCount': recipeCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'achievements': achievements,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'isEmailVerified': isEmailVerified,
    };
  }

  /// Create from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      level: json['level'] as int? ?? 1,
      recipeCount: json['recipeCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] is Timestamp
          ? (json['lastActiveAt'] as Timestamp).toDate()
          : DateTime.now(),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    int? level,
    int? recipeCount,
    int? followersCount,
    int? followingCount,
    List<String>? achievements,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      recipeCount: recipeCount ?? this.recipeCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  /// Get initials from display name or email
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Get display name or email prefix
  String get displayNameOrEmail => displayName ?? email.split('@')[0];

  /// Check if user has specific achievement
  bool hasAchievement(String achievement) => achievements.contains(achievement);

  /// Add achievement
  UserModel addAchievement(String achievement) {
    if (achievements.contains(achievement)) return this;
    return copyWith(achievements: [...achievements, achievement]);
  }

  /// Increment recipe count
  UserModel incrementRecipeCount() {
    return copyWith(recipeCount: recipeCount + 1);
  }

  /// Calculate level based on recipe count
  int calculateLevel() {
    if (recipeCount >= 50) return 5;
    if (recipeCount >= 25) return 4;
    if (recipeCount >= 10) return 3;
    if (recipeCount >= 5) return 2;
    return 1;
  }

  /// Update level based on recipe count
  UserModel updateLevel() {
    return copyWith(level: calculateLevel());
  }
}
