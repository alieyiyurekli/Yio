import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/follow_constants.dart';
import '../models/follow_models.dart';

/// Follow Request Service
/// Manages follow requests for private accounts
class FollowRequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FollowRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Send a follow request
  Future<bool> sendFollowRequest(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    // Validate: Cannot request yourself
    if (currentUserId == targetUserId) {
      throw Exception('Kendinize istek gönderemezsiniz');
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

      if (!isPrivate) {
        throw Exception('Bu hesap özel değil, doğrudan takip edebilirsiniz');
      }

      // Check if request already exists
      final existingRequest = await _firestore
          .collection(CollectionPaths.userFollowRequests(targetUserId))
          .doc(currentUserId)
          .get();

      if (existingRequest.exists) {
        throw Exception('Zaten bir istek gönderdiniz');
      }

      // Get current user info
      final currentUserDoc = await _firestore
          .collection(FollowConstants.usersCollection)
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists) {
        throw Exception('Kullanıcı bilgileri bulunamadı');
      }

      final currentUserData = currentUserDoc.data()!;

      // Create follow request
      await _firestore
          .collection(CollectionPaths.userFollowRequests(targetUserId))
          .doc(currentUserId)
          .set({
        FieldNames.requesterId: currentUserId,
        FieldNames.requesterName: currentUserData[FieldNames.name] ?? 'Kullanıcı',
        FieldNames.requesterPhotoUrl: currentUserData[FieldNames.photoUrl],
        FieldNames.requestedAt: Timestamp.now(),
        FieldNames.status: 'pending',
      });

      // Add to following with pending status
      await _firestore
          .collection(CollectionPaths.userFollowing(currentUserId))
          .doc(targetUserId)
          .set({
        FieldNames.userId: targetUserId,
        FieldNames.followedAt: Timestamp.now(),
        FieldNames.status: 'pending',
      });

      return true;
    } catch (e) {
      throw Exception('İstek gönderme başarısız: $e');
    }
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

  /// Get pending follow requests for current user
  Future<List<FollowRequest>> getPendingRequests() async {
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
  Stream<List<FollowRequest>> pendingRequestsStream() {
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

  /// Get pending follow request count
  Stream<int> pendingCountStream() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(CollectionPaths.userFollowRequests(currentUserId))
        .where(FieldNames.status, isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get follow request status for a specific user
  Future<FollowRequestStatus?> getRequestStatus(String requesterId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection(CollectionPaths.userFollowRequests(currentUserId))
          .doc(requesterId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final status = data[FieldNames.status] as String? ?? 'pending';

      switch (status) {
        case 'pending':
          return FollowRequestStatus.pending;
        case 'accepted':
          return FollowRequestStatus.accepted;
        case 'rejected':
          return FollowRequestStatus.rejected;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get all follow requests (including accepted/rejected)
  Future<List<FollowRequest>> getAllRequests() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(CollectionPaths.userFollowRequests(currentUserId))
          .orderBy(FieldNames.requestedAt, descending: true)
          .get();

      return snapshot.docs.map((doc) => FollowRequest.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Takip istekleri yüklenemedi: $e');
    }
  }

  /// Stream all follow requests
  Stream<List<FollowRequest>> allRequestsStream() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(CollectionPaths.userFollowRequests(currentUserId))
        .orderBy(FieldNames.requestedAt, descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FollowRequest.fromDocument(doc)).toList());
  }

  /// Accept all pending follow requests
  Future<bool> acceptAllRequests() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    try {
      final pendingRequests = await getPendingRequests();
      
      for (final request in pendingRequests) {
        await acceptFollowRequest(request.requesterId);
      }

      return true;
    } catch (e) {
      throw Exception('Tüm istekleri kabul etme başarısız: $e');
    }
  }

  /// Reject all pending follow requests
  Future<bool> rejectAllRequests() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    try {
      final pendingRequests = await getPendingRequests();
      
      for (final request in pendingRequests) {
        await rejectFollowRequest(request.requesterId);
      }

      return true;
    } catch (e) {
      throw Exception('Tüm istekleri reddetme başarısız: $e');
    }
  }
}
