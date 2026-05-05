import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/follow_constants.dart';
import '../models/follow_models.dart';
import 'mutual_follow_service.dart';

/// Follow Service
/// Manages follow/unfollow operations and follow relationships
class FollowService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MutualFollowService _mutualFollowService;

  FollowService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MutualFollowService? mutualFollowService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _mutualFollowService = mutualFollowService ?? MutualFollowService();

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Follow a user
  /// Returns true if successful, false if failed
  Future<bool> followUser(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    // Validate: Cannot follow yourself
    if (currentUserId == targetUserId) {
      throw Exception('Kendinizi takip edemezsiniz');
    }

    try {
      // Check if target user is private
      final targetUserDoc = await _firestore
          .collection(FollowConstants.usersCollection)
          .doc(targetUserId)
          .get();

      if (!targetUserDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final targetUserData = targetUserDoc.data()!;
      final isPrivate = targetUserData[FieldNames.isPrivate] as bool? ?? false;

      final now = Timestamp.now();

      if (isPrivate) {
        // Private account: Create follow request
        await _firestore
            .collection(CollectionPaths.userFollowRequests(targetUserId))
            .doc(currentUserId)
            .set({
          FieldNames.requesterId: currentUserId,
          FieldNames.requesterName: targetUserData[FieldNames.name] ?? 'Kullanıcı',
          FieldNames.requesterPhotoUrl: targetUserData[FieldNames.photoUrl],
          FieldNames.requestedAt: now,
          FieldNames.status: 'pending',
        });

        // Update following subcollection with pending status
        await _firestore
            .collection(CollectionPaths.userFollowing(currentUserId))
            .doc(targetUserId)
            .set({
          FieldNames.userId: targetUserId,
          FieldNames.followedAt: now,
          FieldNames.status: 'pending',
        });

        return true;
      } else {
        // Public account: Direct follow
        final batch = _firestore.batch();

        // Add to following
        batch.set(
          _firestore
              .collection(CollectionPaths.userFollowing(currentUserId))
              .doc(targetUserId),
          {
            FieldNames.userId: targetUserId,
            FieldNames.followedAt: now,
            FieldNames.status: 'accepted',
          },
        );

        // Add to followers
        batch.set(
          _firestore
              .collection(CollectionPaths.userFollowers(targetUserId))
              .doc(currentUserId),
          {
            FieldNames.userId: currentUserId,
            FieldNames.followedAt: now,
            FieldNames.status: 'accepted',
          },
        );

        // Update counts
        batch.update(
          _firestore.collection(FollowConstants.usersCollection).doc(currentUserId),
          {FieldNames.followingCount: FieldValue.increment(1)},
        );

        batch.update(
          _firestore.collection(FollowConstants.usersCollection).doc(targetUserId),
          {FieldNames.followersCount: FieldValue.increment(1)},
        );

        await batch.commit();

        // Check if mutual follow (target user already follows current user)
        await _checkAndCreateMutualFollow(currentUserId, targetUserId);

        return true;
      }
    } catch (e) {
      throw Exception('Takip işlemi başarısız: $e');
    }
  }

  /// Unfollow a user
  /// Returns true if successful, false if failed
  Future<bool> unfollowUser(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    try {
      final batch = _firestore.batch();

      // Remove from following
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowing(currentUserId))
            .doc(targetUserId),
      );

      // Remove from followers
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowers(targetUserId))
            .doc(currentUserId),
      );

      // Update counts
      batch.update(
        _firestore.collection(FollowConstants.usersCollection).doc(currentUserId),
        {FieldNames.followingCount: FieldValue.increment(-1)},
      );

      batch.update(
        _firestore.collection(FollowConstants.usersCollection).doc(targetUserId),
        {FieldNames.followersCount: FieldValue.increment(-1)},
      );

      await batch.commit();

      // Check and remove mutual follow if exists
      await _checkAndRemoveMutualFollow(currentUserId, targetUserId);

      return true;
    } catch (e) {
      throw Exception('Takipten çıkma işlemi başarısız: $e');
    }
  }

  /// Cancel a follow request
  /// Returns true if successful, false if failed
  Future<bool> cancelFollowRequest(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    try {
      final batch = _firestore.batch();

      // Remove from following
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowing(currentUserId))
            .doc(targetUserId),
      );

      // Remove follow request
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowRequests(targetUserId))
            .doc(currentUserId),
      );

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('İstek iptal işlemi başarısız: $e');
    }
  }

  /// Get follow status for a specific user
  Future<FollowStatus> getFollowStatus(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return FollowStatus.notFollowing;

    try {
      final doc = await _firestore
          .collection(CollectionPaths.userFollowing(currentUserId))
          .doc(targetUserId)
          .get();

      if (!doc.exists) {
        return FollowStatus.notFollowing;
      }

      final data = doc.data()!;
      final status = data[FieldNames.status] as String? ?? 'accepted';

      switch (status) {
        case 'accepted':
          return FollowStatus.following;
        case 'pending':
          return FollowStatus.pending;
        default:
          return FollowStatus.notFollowing;
      }
    } catch (e) {
      return FollowStatus.notFollowing;
    }
  }

  /// Stream follow status for a specific user
  Stream<FollowStatus> followStatusStream(String targetUserId) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value(FollowStatus.notFollowing);
    }

    return _firestore
        .collection(CollectionPaths.userFollowing(currentUserId))
        .doc(targetUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return FollowStatus.notFollowing;
      }

      final data = doc.data()!;
      final status = data[FieldNames.status] as String? ?? 'accepted';

      switch (status) {
        case 'accepted':
          return FollowStatus.following;
        case 'pending':
          return FollowStatus.pending;
        default:
          return FollowStatus.notFollowing;
      }
    });
  }

  /// Check if current user is following a specific user
  bool isFollowingUser(String userId) {
    // This would be cached in provider
    return false;
  }

  /// Get followers list for a user
  Future<List<Map<String, dynamic>>> getFollowers(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(CollectionPaths.userFollowers(userId))
          .orderBy(FieldNames.followedAt, descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Takipçiler yüklenemedi: $e');
    }
  }

  /// Stream followers list for a user
  Stream<List<Map<String, dynamic>>> followersStream(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(CollectionPaths.userFollowers(userId))
        .orderBy(FieldNames.followedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get following list for a user
  Future<List<Map<String, dynamic>>> getFollowing(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(CollectionPaths.userFollowing(userId))
          .where(FieldNames.status, isEqualTo: 'accepted')
          .orderBy(FieldNames.followedAt, descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Takip edilenler yüklenemedi: $e');
    }
  }

  /// Stream following list for a user
  Stream<List<Map<String, dynamic>>> followingStream(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(CollectionPaths.userFollowing(userId))
        .where(FieldNames.status, isEqualTo: 'accepted')
        .orderBy(FieldNames.followedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get followers count stream
  Stream<int> followersCountStream(String userId) {
    return _firestore
        .collection(FollowConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return 0;
      return (data[FieldNames.followersCount] as int?) ?? 0;
    });
  }

  /// Get following count stream
  Stream<int> followingCountStream(String userId) {
    return _firestore
        .collection(FollowConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return 0;
      return (data[FieldNames.followingCount] as int?) ?? 0;
    });
  }

  /// Get pending follow requests for current user
  Future<List<FollowRequest>> getPendingFollowRequests() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(CollectionPaths.userFollowRequests(currentUserId))
          .where(FieldNames.status, isEqualTo: 'pending')
          .orderBy(FieldNames.requestedAt, descending: true)
          .get();

      return snapshot.docs.map((doc) => FollowRequest.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Takip istekleri yüklenemedi: $e');
    }
  }

  /// Stream pending follow requests for current user
  Stream<List<FollowRequest>> pendingFollowRequestsStream() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(CollectionPaths.userFollowRequests(currentUserId))
        .where(FieldNames.status, isEqualTo: 'pending')
        .orderBy(FieldNames.requestedAt, descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FollowRequest.fromDocument(doc)).toList());
  }

  /// Accept a follow request
  Future<bool> acceptFollowRequest(String requesterId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    try {
      final batch = _firestore.batch();
      final now = Timestamp.now();

      // Get follow request
      final requestDoc = await _firestore
          .collection(CollectionPaths.userFollowRequests(currentUserId))
          .doc(requesterId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Takip isteği bulunamadı');
      }

      final requestData = requestDoc.data()!;

      // Move to following (accepted status)
      batch.set(
        _firestore
            .collection(CollectionPaths.userFollowing(currentUserId))
            .doc(requesterId),
        {
          FieldNames.userId: requesterId,
          FieldNames.followedAt: now,
          FieldNames.status: 'accepted',
        },
      );

      // Add to requester's followers
      batch.set(
        _firestore
            .collection(CollectionPaths.userFollowers(requesterId))
            .doc(currentUserId),
        {
          FieldNames.userId: currentUserId,
          FieldNames.followedAt: now,
          FieldNames.status: 'accepted',
        },
      );

      // Update counts
      batch.update(
        _firestore.collection(FollowConstants.usersCollection).doc(currentUserId),
        {FieldNames.followingCount: FieldValue.increment(1)},
      );

      batch.update(
        _firestore.collection(FollowConstants.usersCollection).doc(requesterId),
        {FieldNames.followersCount: FieldValue.increment(1)},
      );

      // Delete follow request
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowRequests(currentUserId))
            .doc(requesterId),
      );

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('İstek kabul işlemi başarısız: $e');
    }
  }

  /// Reject a follow request
  Future<bool> rejectFollowRequest(String requesterId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    try {
      final batch = _firestore.batch();

      // Delete from following
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowing(currentUserId))
            .doc(requesterId),
      );

      // Delete follow request
      batch.delete(
        _firestore
            .collection(CollectionPaths.userFollowRequests(currentUserId))
            .doc(requesterId),
      );

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('İstek reddetme işlemi başarısız: $e');
    }
  }

  /// Check if two users are mutually following and create mutual follow if true
  Future<void> _checkAndCreateMutualFollow(String userId1, String userId2) async {
    try {
      // Check if userId2 follows userId1
      final followDoc = await _firestore
          .collection(CollectionPaths.userFollowing(userId2))
          .doc(userId1)
          .get();

      if (followDoc.exists) {
        final data = followDoc.data()!;
        final status = data[FieldNames.status] as String? ?? 'accepted';
        
        if (status == 'accepted') {
          // Both users follow each other - create mutual follow
          await _mutualFollowService.createMutualFollow(userId1, userId2);
        }
      }
    } catch (e) {
      // Silently fail - mutual follow is optional
      debugPrint('Mutual follow check failed: $e');
    }
  }

  /// Check and remove mutual follow when unfollowing
  Future<void> _checkAndRemoveMutualFollow(String userId1, String userId2) async {
    try {
      // Check if mutual follow exists
      final isMutual = await _mutualFollowService.isMutualFollow(userId1, userId2);
      
      if (isMutual) {
        // Remove mutual follow since one user unfollowed
        await _mutualFollowService.removeMutualFollow(userId1, userId2);
      }
    } catch (e) {
      // Silently fail
      debugPrint('Mutual follow removal failed: $e');
    }
  }
}
