import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/follow_constants.dart';

/// User Search Service
/// Manages user search operations with caching
class UserSearchService {
  final FirebaseFirestore _firestore;

  UserSearchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Search users by display name
  Future<List<Map<String, dynamic>>> searchByDisplayName(
    String query, {
    int limit = 20,
  }) async {
    try {
      final sanitizedQuery = _sanitizeQuery(query);
      
      final snapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: sanitizedQuery)
          .where('displayName', isLessThan: '$sanitizedQuery\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('İsim araması başarısız: $e');
    }
  }

  /// Search user by username (exact match)
  Future<Map<String, dynamic>?> searchByUsername(String username) async {
    try {
      final sanitizedUsername = _sanitizeUsername(username);
      
      final snapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .where('username', isEqualTo: sanitizedUsername)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.data();
    } catch (e) {
      throw Exception('Kullanıcı adı araması başarısız: $e');
    }
  }

  /// Search user by email
  Future<Map<String, dynamic>?> searchByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.data();
    } catch (e) {
      throw Exception('E-posta araması başarısız: $e');
    }
  }

  /// General search (displayName + username)
  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    try {
      final sanitizedQuery = _sanitizeQuery(query);
      final results = <Map<String, dynamic>>[];

      // Search by display name
      final nameSnapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: sanitizedQuery)
          .where('displayName', isLessThan: '$sanitizedQuery\uf8ff')
          .limit(limit)
          .get();

      for (var doc in nameSnapshot.docs) {
        final data = doc.data();
        if (!results.any((r) => r['id'] == data['id'])) {
          results.add(data);
        }
      }

      // Search by username (starts with)
      final usernameSnapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .where('username', isGreaterThanOrEqualTo: sanitizedQuery.toLowerCase())
          .where('username', isLessThan: '${sanitizedQuery.toLowerCase()}\uf8ff')
          .limit(limit)
          .get();

      for (var doc in usernameSnapshot.docs) {
        final data = doc.data();
        if (!results.any((r) => r['id'] == data['id'])) {
          results.add(data);
        }
      }

      return results.take(limit).toList();
    } catch (e) {
      throw Exception('Kullanıcı araması başarısız: $e');
    }
  }

  /// Get suggested users
  Future<List<Map<String, dynamic>>> getSuggestedUsers({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Önerilen kullanıcılar yüklenemedi: $e');
    }
  }

  /// Get trending users (most followers)
  Future<List<Map<String, dynamic>>> getTrendingUsers({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FollowConstants.usersCollection)
          .orderBy('followersCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Trend kullanıcılar yüklenemedi: $e');
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FollowConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınamadı: $e');
    }
  }

  /// Batch get users by IDs
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final chunks = _chunkList(userIds, 10);
      final results = <Map<String, dynamic>>[];

      for (final chunk in chunks) {
        final snapshots = await Future.wait(
          chunk.map((id) => _firestore
              .collection(FollowConstants.usersCollection)
              .doc(id)
              .get()),
        );

        for (final doc in snapshots) {
          if (doc.exists) {
            results.add(doc.data() as Map<String, dynamic>);
          }
        }
      }

      return results;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınamadı: $e');
    }
  }

  /// Sanitize search query
  String _sanitizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'[<>"%]'), '');
  }

  /// Sanitize username
  String _sanitizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Chunk list into smaller lists
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, min(i + chunkSize, list.length)));
    }
    return chunks;
  }
}
