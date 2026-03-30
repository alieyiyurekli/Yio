import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// Core user model for authentication and onboarding.
///
/// This model represents the user document in Firestore at `users/{uid}`.
/// It contains all fields needed for auth, onboarding, and role-based access.
///
/// Note: The existing [UserModel] in lib/models/user_model.dart is preserved
/// for recipe-related features (level, recipeCount, achievements, etc.).
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? username;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final String role;
  final bool onboardingCompleted;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.username,
    this.photoUrl,
    this.bio,
    this.interests = const [],
    this.role = AppConstants.roleUser,
    this.onboardingCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for Firestore.
  Map<String, dynamic> toMap() {
    return {
      AppConstants.fieldUid: uid,
      AppConstants.fieldEmail: email,
      AppConstants.fieldName: name,
      AppConstants.fieldUsername: username,
      AppConstants.fieldPhotoUrl: photoUrl,
      AppConstants.fieldBio: bio,
      AppConstants.fieldInterests: interests,
      AppConstants.fieldRole: role,
      AppConstants.fieldOnboardingCompleted: onboardingCompleted,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document.
  ///
  /// Uses safe boolean parsing: `raw == true` instead of `as bool? ?? false`
  /// to handle cases where Firestore might return non-bool values (e.g., int 0/1).
  factory AppUser.fromMap(Map<String, dynamic> map) {
    // Safe boolean parsing for onboardingCompleted
    final onboardingRaw = map[AppConstants.fieldOnboardingCompleted];
    final onboardingCompleted = onboardingRaw == true;

    // Debug log to verify parsing
    // ignore: avoid_print
    print('[AppUser.fromMap] onboardingRaw: $onboardingRaw (${onboardingRaw.runtimeType}), parsed: $onboardingCompleted');

    return AppUser(
      uid: map[AppConstants.fieldUid] as String,
      email: map[AppConstants.fieldEmail] as String,
      name: map[AppConstants.fieldName] as String,
      username: map[AppConstants.fieldUsername] as String?,
      photoUrl: map[AppConstants.fieldPhotoUrl] as String?,
      bio: map[AppConstants.fieldBio] as String?,
      interests: (map[AppConstants.fieldInterests] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      role: map[AppConstants.fieldRole] as String? ?? AppConstants.roleUser,
      onboardingCompleted: onboardingCompleted,
      createdAt: map[AppConstants.fieldCreatedAt] is Timestamp
          ? (map[AppConstants.fieldCreatedAt] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create from Firestore DocumentSnapshot.
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(data);
  }

  /// Copy with method for immutable updates.
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    String? role,
    bool? onboardingCompleted,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if user is admin.
  bool get isAdmin => role == AppConstants.roleAdmin;

  /// Get display name or email prefix.
  String get displayNameOrEmail => name.isNotEmpty ? name : email.split('@')[0];

  /// Check if user has specific interest.
  bool hasInterest(String interest) => interests.contains(interest);

  /// Validate username format.
  static bool isValidUsername(String username) {
    if (username.length < AppConstants.usernameMinLength ||
        username.length > AppConstants.usernameMaxLength) {
      return false;
    }
    // Only alphanumeric and underscore allowed
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, name: $name, username: $username, role: $role, onboardingCompleted: $onboardingCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
