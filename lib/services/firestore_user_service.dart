import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Firestore User Service
///
/// Handles all user-related Firestore operations:
/// - Create user document on registration
/// - Get user data
/// - Update user profile
/// - Follow/unfollow users
/// - User statistics
class FirestoreUserService {
  final FirebaseFirestore _firestore;
  final String userId;

  // Collection reference
  static const String _usersCollection = 'users';
  late final DocumentReference<Map<String, dynamic>> _userDoc;

  FirestoreUserService({
    FirebaseFirestore? firestore,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _userDoc = _firestore.collection(_usersCollection).doc(userId);
  }

  /// Create user document in Firestore
  Future<bool> createUser(UserModel user) async {
    try {
      await _userDoc.set(user.toJson());
      debugPrint('User created in Firestore: ${user.id}');
      return true;
    } catch (e) {
      debugPrint('Error creating user in Firestore: $e');
      return false;
    }
  }

  /// Get user data by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Get current user data
  Future<UserModel?> getCurrentUser() async {
    return await getUser(userId);
  }

  /// Stream of current user data (real-time updates)
  Stream<UserModel?> get currentUserStream {
    return _userDoc.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  /// Stream of user data by ID
  Stream<UserModel?> userStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  /// Update user profile
  Future<bool> updateUser(UserModel user) async {
    try {
      await _userDoc.update(user.toJson());
      debugPrint('User updated in Firestore: ${user.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating user in Firestore: $e');
      return false;
    }
  }

  /// Update user display name
  Future<bool> updateDisplayName(String displayName) async {
    try {
      await _userDoc.update({'displayName': displayName});
      return true;
    } catch (e) {
      debugPrint('Error updating display name: $e');
      return false;
    }
  }

  /// Update user bio
  Future<bool> updateBio(String bio) async {
    try {
      await _userDoc.update({'bio': bio});
      return true;
    } catch (e) {
      debugPrint('Error updating bio: $e');
      return false;
    }
  }

  /// Update user photo URL
  Future<bool> updatePhotoUrl(String photoUrl) async {
    try {
      await _userDoc.update({'photoUrl': photoUrl});
      return true;
    } catch (e) {
      debugPrint('Error updating photo URL: $e');
      return false;
    }
  }

  /// Update last active timestamp
  Future<bool> updateLastActive() async {
    try {
      await _userDoc.update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating last active: $e');
      return false;
    }
  }

  /// Increment recipe count
  Future<bool> incrementRecipeCount() async {
    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(_userDoc);
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final currentCount = data['recipeCount'] as int? ?? 0;
          final newCount = currentCount + 1;

          // Calculate new level
          int newLevel = 1;
          if (newCount >= 50) {
            newLevel = 5;
          } else if (newCount >= 25) newLevel = 4;
          else if (newCount >= 10) newLevel = 3;
          else if (newCount >= 5) newLevel = 2;

          transaction.update(_userDoc, {
            'recipeCount': newCount,
            'level': newLevel,
          });
        }
      });
      return true;
    } catch (e) {
      debugPrint('Error incrementing recipe count: $e');
      return false;
    }
  }

  /// Decrement recipe count
  Future<bool> decrementRecipeCount() async {
    try {
      await _userDoc.update({
        'recipeCount': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      debugPrint('Error decrementing recipe count: $e');
      return false;
    }
  }

  /// Add achievement to user
  Future<bool> addAchievement(String achievement) async {
    try {
      await _userDoc.update({
        'achievements': FieldValue.arrayUnion([achievement]),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding achievement: $e');
      return false;
    }
  }

  /// Remove achievement from user
  Future<bool> removeAchievement(String achievement) async {
    try {
      await _userDoc.update({
        'achievements': FieldValue.arrayRemove([achievement]),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing achievement: $e');
      return false;
    }
  }

  /// Follow a user
  Future<bool> followUser(String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Add to current user's following list
      final currentUserFollowingRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('following')
          .doc(targetUserId);

      batch.set(currentUserFollowingRef, {
        'userId': targetUserId,
        'followedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Add to target user's followers list
      final targetUserFollowersRef = _firestore
          .collection(_usersCollection)
          .doc(targetUserId)
          .collection('followers')
          .doc(userId);

      batch.set(targetUserFollowersRef, {
        'userId': userId,
        'followedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update counts
      batch.update(_userDoc, {'followingCount': FieldValue.increment(1)});
      batch.update(
        _firestore.collection(_usersCollection).doc(targetUserId),
        {'followersCount': FieldValue.increment(1)},
      );

      await batch.commit();
      debugPrint('User followed: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Remove from current user's following list
      final currentUserFollowingRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('following')
          .doc(targetUserId);

      batch.delete(currentUserFollowingRef);

      // Remove from target user's followers list
      final targetUserFollowersRef = _firestore
          .collection(_usersCollection)
          .doc(targetUserId)
          .collection('followers')
          .doc(userId);

      batch.delete(targetUserFollowersRef);

      // Update counts
      batch.update(_userDoc, {'followingCount': FieldValue.increment(-1)});
      batch.update(
        _firestore.collection(_usersCollection).doc(targetUserId),
        {'followersCount': FieldValue.increment(-1)},
      );

      await batch.commit();
      debugPrint('User unfollowed: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  /// Check if current user follows target user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('following')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Stream of following status
  Stream<bool> isFollowingStream(String targetUserId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get user's followers
  Stream<List<UserModel>> getFollowers() {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('followers')
        .snapshots()
        .asyncMap((snapshot) async {
      final userIds =
          snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
      final users = await Future.wait(
        userIds.map((id) => getUser(id)),
      );
      return users.whereType<UserModel>().toList();
    });
  }

  /// Get user's following
  Stream<List<UserModel>> getFollowing() {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('following')
        .snapshots()
        .asyncMap((snapshot) async {
      final userIds =
          snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
      final users = await Future.wait(
        userIds.map((id) => getUser(id)),
      );
      return users.whereType<UserModel>().toList();
    });
  }

  /// Delete user account and all subcollections
  Future<bool> deleteUser() async {
    try {
      // Delete following subcollection
      final followingSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('following')
          .get();
      for (final doc in followingSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete followers subcollection
      final followersSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('followers')
          .get();
      for (final doc in followersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete recipes subcollection
      final recipesSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('recipes')
          .get();
      for (final doc in recipesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _userDoc.delete();

      debugPrint('User deleted from Firestore: $userId');
      return true;
    } catch (e) {
      debugPrint('Error deleting user from Firestore: $e');
      return false;
    }
  }

  /// Search users by display name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Search by display name (case-insensitive prefix search)
      final nameSnapshot = await _firestore
          .collection(_usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      // Search by email (exact match)
      final emailSnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: query)
          .limit(10)
          .get();

      // Combine results (removing duplicates)
      final Map<String, UserModel> usersMap = {};

      for (final doc in nameSnapshot.docs) {
        final user = UserModel.fromJson(doc.data());
        if (user.id != userId) {
          usersMap[user.id] = user;
        }
            }

      for (final doc in emailSnapshot.docs) {
        final user = UserModel.fromJson(doc.data());
        if (user.id != userId) {
          usersMap[user.id] = user;
        }
            }

      return usersMap.values.toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }
}
