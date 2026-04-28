import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/follow_models.dart';
import '../services/follow_request_service.dart';

/// Follow Request Provider
/// Manages follow requests for private accounts
class FollowRequestProvider extends ChangeNotifier {
  final FollowRequestService _followRequestService;
  final FirebaseAuth _auth;

  // Requests
  List<FollowRequest> _pendingRequests = [];
  List<FollowRequest> _acceptedRequests = [];
  List<FollowRequest> _rejectedRequests = [];

  // Counts
  int _pendingCount = 0;
  int get totalCount => _pendingCount + _acceptedRequests.length + _rejectedRequests.length;

  // Loading
  bool _isLoading = false;
  bool _isProcessing = false;

  // Error
  String? _errorMessage;

  FollowRequestProvider({
    required FollowRequestService followRequestService,
    FirebaseAuth? auth,
  })  : _followRequestService = followRequestService,
        _auth = auth ?? FirebaseAuth.instance;

  // Getters
  List<FollowRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  List<FollowRequest> get acceptedRequests => List.unmodifiable(_acceptedRequests);
  List<FollowRequest> get rejectedRequests => List.unmodifiable(_rejectedRequests);
  int get pendingCount => _pendingCount;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  /// Load pending requests
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requests = await _followRequestService.getPendingRequests();
      _pendingRequests = requests;
      _pendingCount = requests.length;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Takip istekleri yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Load all requests
  Future<void> loadAllRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requests = await _followRequestService.getAllRequests();
      
      _pendingRequests = requests.where((r) => r.status == FollowRequestStatus.pending).toList();
      _acceptedRequests = requests.where((r) => r.status == FollowRequestStatus.accepted).toList();
      _rejectedRequests = requests.where((r) => r.status == FollowRequestStatus.rejected).toList();
      _pendingCount = _pendingRequests.length;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Takip istekleri yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Stream pending requests
  Stream<List<FollowRequest>> pendingRequestsStream() {
    return _followRequestService.pendingRequestsStream().map((requests) {
      _pendingRequests = requests;
      _pendingCount = requests.length;
      notifyListeners();
      return requests;
    });
  }

  /// Stream all requests
  Stream<List<FollowRequest>> allRequestsStream() {
    return _followRequestService.allRequestsStream().map((requests) {
      _pendingRequests = requests.where((r) => r.status == FollowRequestStatus.pending).toList();
      _acceptedRequests = requests.where((r) => r.status == FollowRequestStatus.accepted).toList();
      _rejectedRequests = requests.where((r) => r.status == FollowRequestStatus.rejected).toList();
      _pendingCount = _pendingRequests.length;
      notifyListeners();
      return requests;
    });
  }

  /// Accept a request
  Future<bool> acceptRequest(String requestId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _followRequestService.acceptFollowRequest(requestId);
      
      if (result) {
        // Remove from pending
        _pendingRequests.removeWhere((r) => r.requesterId == requestId);
        _pendingCount--;
        
        // Add to accepted
        final request = _pendingRequests.firstWhere(
          (r) => r.requesterId == requestId,
          orElse: () => throw Exception('İstek bulunamadı'),
        );
        _acceptedRequests.add(request.copyWith(status: FollowRequestStatus.accepted));
      }
      
      _isProcessing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'İstek kabul edilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reject a request
  Future<bool> rejectRequest(String requestId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _followRequestService.rejectFollowRequest(requestId);
      
      if (result) {
        // Remove from pending
        final request = _pendingRequests.firstWhere(
          (r) => r.requesterId == requestId,
          orElse: () => throw Exception('İstek bulunamadı'),
        );
        _pendingRequests.remove(request);
        _rejectedRequests.add(request.copyWith(status: FollowRequestStatus.rejected));
        _pendingCount--;
      }
      
      _isProcessing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'İstek reddedilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Accept all pending requests
  Future<bool> acceptAllRequests() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _followRequestService.acceptAllRequests();
      
      if (result) {
        // Move all pending to accepted
        for (final request in _pendingRequests) {
          _acceptedRequests.add(request.copyWith(status: FollowRequestStatus.accepted));
        }
        _pendingRequests.clear();
        _pendingCount = 0;
      }
      
      _isProcessing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Tüm istekler kabul edilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reject all pending requests
  Future<bool> rejectAllRequests() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _followRequestService.rejectAllRequests();
      
      if (result) {
        // Move all pending to rejected
        for (final request in _pendingRequests) {
          _rejectedRequests.add(request.copyWith(status: FollowRequestStatus.rejected));
        }
        _pendingRequests.clear();
        _pendingCount = 0;
      }
      
      _isProcessing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Tüm istekler reddedilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get pending count stream
  Stream<int> pendingCountStream() {
    return _followRequestService.pendingCountStream().map((count) {
      _pendingCount = count;
      notifyListeners();
      return count;
    });
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _pendingRequests = [];
    _acceptedRequests = [];
    _rejectedRequests = [];
    _pendingCount = 0;
    _isLoading = false;
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }
}
