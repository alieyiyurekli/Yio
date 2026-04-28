import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/follow_constants.dart';
import '../models/follow_models.dart';
import '../services/follow_service.dart';
import '../services/user_search_service.dart';

/// Follow Provider
/// Manages follow relationships and user lists
class FollowProvider extends ChangeNotifier {
  final FollowService _followService;
  final UserSearchService _userSearchService;
  final FirebaseAuth _auth;

  // Current user state
  String? _currentUserId;
  final Set<String> _followingIds = {};
  final Set<String> _followerIds = {};
  final Map<String, FollowStatus> _followStatusMap = {};

  // Lists
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  List<FollowRequest> _pendingRequests = [];

  // Loading states
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isFollowing = false;
  bool _isUnfollowing = false;
  bool _isLoadingRequests = false;

  // Error state
  String? _errorMessage;

  FollowProvider({
    required FollowService followService,
    required UserSearchService userSearchService,
    FirebaseAuth? auth,
  })  : _followService = followService,
        _userSearchService = userSearchService,
        _auth = auth ?? FirebaseAuth.instance;

  // Getters
  String? get currentUserId => _currentUserId;
  Set<String> get followingIds => Set.unmodifiable(_followingIds);
  Set<String> get followerIds => Set.unmodifiable(_followerIds);
  Map<String, FollowStatus> get followStatusMap => Map.unmodifiable(_followStatusMap);
  
  List<Map<String, dynamic>> get followers => List.unmodifiable(_followers);
  List<Map<String, dynamic>> get following => List.unmodifiable(_following);
  List<FollowRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  
  bool get isLoadingFollowers => _isLoadingFollowers;
  bool get isLoadingFollowing => _isLoadingFollowing;
  bool get isFollowing => _isFollowing;
  bool get isUnfollowing => _isUnfollowing;
  bool get isLoadingRequests => _isLoadingRequests;
  String? get errorMessage => _errorMessage;

  /// Initialize provider
  Future<void> init() async {
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId != null) {
      await _loadFollowingIds();
    }
  }

  /// Load following IDs
  Future<void> _loadFollowingIds() async {
    if (_currentUserId == null) return;

    try {
      final following = await _followService.getFollowing(_currentUserId!);
      _followingIds.clear();
      for (final user in following) {
        _followingIds.add(user[FieldNames.userId] as String);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Takip edilenler yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Follow a user
  Future<bool> followUser(String targetUserId) async {
    if (_currentUserId == null) return false;

    _isFollowing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _followService.followUser(targetUserId);
      
      if (result) {
        _followingIds.add(targetUserId);
        _followStatusMap[targetUserId] = FollowStatus.following;
      }
      
      _isFollowing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isFollowing = false;
      _errorMessage = 'Takip işlemi başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    if (_currentUserId == null) return false;

    _isUnfollowing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _followService.unfollowUser(targetUserId);
      
      if (result) {
        _followingIds.remove(targetUserId);
        _followStatusMap.remove(targetUserId);
      }
      
      _isUnfollowing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isUnfollowing = false;
      _errorMessage = 'Takipten çıkma işlemi başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cancel a follow request
  Future<bool> cancelFollowRequest(String targetUserId) async {
    if (_currentUserId == null) return false;

    try {
      final result = await _followService.cancelFollowRequest(targetUserId);
      
      if (result) {
        _followingIds.remove(targetUserId);
        _followStatusMap.remove(targetUserId);
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'İstek iptal işlemi başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get follow status for a specific user
  Future<FollowStatus> getFollowStatus(String targetUserId) async {
    if (_followStatusMap.containsKey(targetUserId)) {
      return _followStatusMap[targetUserId]!;
    }

    try {
      final status = await _followService.getFollowStatus(targetUserId);
      _followStatusMap[targetUserId] = status;
      return status;
    } catch (e) {
      return FollowStatus.notFollowing;
    }
  }

  /// Stream follow status for a specific user
  Stream<FollowStatus> followStatusStream(String targetUserId) {
    return _followService.followStatusStream(targetUserId).map((status) {
      _followStatusMap[targetUserId] = status;
      notifyListeners();
      return status;
    });
  }

  /// Check if current user is following a specific user
  bool isFollowingUser(String userId) {
    return _followingIds.contains(userId);
  }

  /// Load followers list
  Future<void> loadFollowers(String userId, {int limit = 20}) async {
    _isLoadingFollowers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final followers = await _followService.getFollowers(userId, limit: limit);
      _followers = followers;
      _isLoadingFollowers = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFollowers = false;
      _errorMessage = 'Takipçiler yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Load following list
  Future<void> loadFollowing(String userId, {int limit = 20}) async {
    _isLoadingFollowing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final following = await _followService.getFollowing(userId, limit: limit);
      _following = following;
      _isLoadingFollowing = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFollowing = false;
      _errorMessage = 'Takip edilenler yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Stream followers list
  Stream<List<Map<String, dynamic>>> followersStream(String userId) {
    return _followService.followersStream(userId).map((followers) {
      _followers = followers;
      notifyListeners();
      return followers;
    });
  }

  /// Stream following list
  Stream<List<Map<String, dynamic>>> followingStream(String userId) {
    return _followService.followingStream(userId).map((following) {
      _following = following;
      notifyListeners();
      return following;
    });
  }

  /// Load pending follow requests
  Future<void> loadPendingRequests() async {
    if (_currentUserId == null) return;

    _isLoadingRequests = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requests = await _followService.getPendingFollowRequests();
      _pendingRequests = requests;
      _isLoadingRequests = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRequests = false;
      _errorMessage = 'Takip istekleri yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Stream pending follow requests
  Stream<List<FollowRequest>> pendingRequestsStream() {
    return _followService.pendingFollowRequestsStream().map((requests) {
      _pendingRequests = requests;
      notifyListeners();
      return requests;
    });
  }

  /// Accept a follow request
  Future<bool> acceptFollowRequest(String requestId) async {
    try {
      final result = await _followService.acceptFollowRequest(requestId);
      
      if (result) {
        // Remove from pending
        _pendingRequests.removeWhere((r) => r.requesterId == requestId);
        // Add to following
        _followingIds.add(requestId);
        _followStatusMap[requestId] = FollowStatus.following;
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'İstek kabul işlemi başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reject a follow request
  Future<bool> rejectFollowRequest(String requestId) async {
    try {
      final result = await _followService.rejectFollowRequest(requestId);
      
      if (result) {
        // Remove from pending
        _pendingRequests.removeWhere((r) => r.requesterId == requestId);
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'İstek reddetme işlemi başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get followers count stream
  Stream<int> followersCountStream(String userId) {
    return _followService.followersCountStream(userId);
  }

  /// Get following count stream
  Stream<int> followingCountStream(String userId) {
    return _followService.followingCountStream(userId);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _currentUserId = null;
    _followingIds.clear();
    _followerIds.clear();
    _followStatusMap.clear();
    _followers.clear();
    _following.clear();
    _pendingRequests.clear();
    _isLoadingFollowers = false;
    _isLoadingFollowing = false;
    _isFollowing = false;
    _isUnfollowing = false;
    _isLoadingRequests = false;
    _errorMessage = null;
    notifyListeners();
  }
}
