import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mutual_follow_model.dart';
import '../services/mutual_follow_service.dart';

/// Mutual Follow Provider (Takipleşme Provider)
/// İki kullanıcının birbirini takip ettiği durumları yönetir
class MutualFollowProvider extends ChangeNotifier {
  final MutualFollowService _mutualFollowService;
  final FirebaseAuth _auth;

  // Current user state
  String? _currentUserId;
  final Set<String> _mutualFollowIds = {};
  final Map<String, bool> _mutualFollowStatusMap = {};

  // Lists
  List<MutualFollow> _mutualFollows = [];
  List<String> _mutualFollowUserIds = [];

  // Loading states
  bool _isLoadingMutualFollows = false;
  bool _isCheckingMutualFollow = false;

  // Error state
  String? _errorMessage;

  MutualFollowProvider({
    required MutualFollowService mutualFollowService,
    FirebaseAuth? auth,
  })  : _mutualFollowService = mutualFollowService,
        _auth = auth ?? FirebaseAuth.instance;

  // Getters
  String? get currentUserId => _currentUserId;
  Set<String> get mutualFollowIds => Set.unmodifiable(_mutualFollowIds);
  Map<String, bool> get mutualFollowStatusMap => Map.unmodifiable(_mutualFollowStatusMap);
  List<MutualFollow> get mutualFollows => List.unmodifiable(_mutualFollows);
  List<String> get mutualFollowUserIds => List.unmodifiable(_mutualFollowUserIds);
  bool get isLoadingMutualFollows => _isLoadingMutualFollows;
  bool get isCheckingMutualFollow => _isCheckingMutualFollow;
  String? get errorMessage => _errorMessage;
  int get mutualFollowCount => _mutualFollows.length;

  /// Initialize provider
  Future<void> init() async {
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId != null) {
      await loadMutualFollows();
    }
  }

  /// İki kullanıcının birbirini takip edip etmediğini kontrol et
  Future<bool> isMutualFollow(String userId1, String userId2) async {
    try {
      final isMutual = await _mutualFollowService.isMutualFollow(userId1, userId2);
      
      // Cache'e ekle
      final docId = _getDocId(userId1, userId2);
      _mutualFollowStatusMap[docId] = isMutual;
      
      notifyListeners();
      return isMutual;
    } catch (e) {
      _errorMessage = 'Takipleşme kontrolü başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mevcut kullanıcının bir kullanıcının mutual follow olup olmadığını kontrol et
  Future<bool> isCurrentUserMutualFollowWith(String targetUserId) async {
    if (_currentUserId == null) return false;

    _isCheckingMutualFollow = true;
    notifyListeners();

    try {
      final isMutual = await _mutualFollowService.isCurrentUserMutualFollowWith(targetUserId);
      
      if (isMutual) {
        _mutualFollowIds.add(targetUserId);
      } else {
        _mutualFollowIds.remove(targetUserId);
      }
      
      _isCheckingMutualFollow = false;
      notifyListeners();
      return isMutual;
    } catch (e) {
      _isCheckingMutualFollow = false;
      _errorMessage = 'Takipleşme kontrolü başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// İki kullanıcının birbirini takip edip etmediğini stream olarak al
  Stream<bool> isMutualFollowStream(String userId1, String userId2) {
    return _mutualFollowService.isMutualFollowStream(userId1, userId2).map((isMutual) {
      final docId = _getDocId(userId1, userId2);
      _mutualFollowStatusMap[docId] = isMutual;
      notifyListeners();
      return isMutual;
    });
  }

  /// Mevcut kullanıcının bir kullanıcının mutual follow olup olmadığını stream olarak al
  Stream<bool> isCurrentUserMutualFollowWithStream(String targetUserId) {
    return _mutualFollowService.isCurrentUserMutualFollowWithStream(targetUserId).map((isMutual) {
      if (isMutual) {
        _mutualFollowIds.add(targetUserId);
      } else {
        _mutualFollowIds.remove(targetUserId);
      }
      notifyListeners();
      return isMutual;
    });
  }

  /// Mutual follow ilişkisi oluştur
  Future<bool> createMutualFollow(String userId1, String userId2) async {
    try {
      final result = await _mutualFollowService.createMutualFollow(userId1, userId2);
      
      if (result) {
        // Cache'i güncelle
        final docId = _getDocId(userId1, userId2);
        _mutualFollowStatusMap[docId] = true;
        
        // Mevcut kullanıcı ilgiliyse ID'yi ekle
        if (_currentUserId != null) {
          if (userId1 == _currentUserId) {
            _mutualFollowIds.add(userId2);
          } else if (userId2 == _currentUserId) {
            _mutualFollowIds.add(userId1);
          }
        }
        
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Takipleşme oluşturma başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mutual follow ilişkisini kaldır
  Future<bool> removeMutualFollow(String userId1, String userId2) async {
    try {
      final result = await _mutualFollowService.removeMutualFollow(userId1, userId2);
      
      if (result) {
        // Cache'i güncelle
        final docId = _getDocId(userId1, userId2);
        _mutualFollowStatusMap[docId] = false;
        
        // Mevcut kullanıcı ilgiliyse ID'yi kaldır
        if (_currentUserId != null) {
          if (userId1 == _currentUserId) {
            _mutualFollowIds.remove(userId2);
          } else if (userId2 == _currentUserId) {
            _mutualFollowIds.remove(userId1);
          }
        }
        
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Takipleşme kaldırma başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mevcut kullanıcının mutual follow listesini yükle
  Future<void> loadMutualFollows() async {
    if (_currentUserId == null) return;

    _isLoadingMutualFollows = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final mutualFollows = await _mutualFollowService.getMutualFollows(_currentUserId!);
      final userIds = await _mutualFollowService.getMutualFollowUserIds(_currentUserId!);
      
      _mutualFollows = mutualFollows;
      _mutualFollowUserIds = userIds;
      _mutualFollowIds.clear();
      _mutualFollowIds.addAll(userIds);
      
      _isLoadingMutualFollows = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMutualFollows = false;
      _errorMessage = 'Takipleşmeler yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Mevcut kullanıcının mutual follow listesini stream olarak al
  Stream<List<MutualFollow>> mutualFollowsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _mutualFollowService.mutualFollowsStream(_currentUserId!).map((mutualFollows) {
      _mutualFollows = mutualFollows;
      
      // User ID'leri güncelle
      _mutualFollowUserIds.clear();
      _mutualFollowIds.clear();
      
      for (final mutualFollow in mutualFollows) {
        if (mutualFollow.userId1 == _currentUserId) {
          _mutualFollowUserIds.add(mutualFollow.userId2);
          _mutualFollowIds.add(mutualFollow.userId2);
        } else {
          _mutualFollowUserIds.add(mutualFollow.userId1);
          _mutualFollowIds.add(mutualFollow.userId1);
        }
      }
      
      notifyListeners();
      return mutualFollows;
    });
  }

  /// Mutual follow sayısını al
  Future<int> getMutualFollowCount(String userId) async {
    try {
      return await _mutualFollowService.getMutualFollowCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// Mevcut kullanıcının mutual follow sayısını stream olarak al
  Stream<int> mutualFollowCountStream() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    return _mutualFollowService.mutualFollowCountStream(_currentUserId!);
  }

  /// Bir kullanıcının mevcut kullanıcı ile mutual follow olup olmadığını kontrol et
  bool isUserMutualFollow(String userId) {
    return _mutualFollowIds.contains(userId);
  }

  /// Cache'den mutual follow durumunu al
  bool? getCachedMutualFollowStatus(String userId1, String userId2) {
    final docId = _getDocId(userId1, userId2);
    return _mutualFollowStatusMap[docId];
  }

  /// Cache'e mutual follow durumunu ekle
  void cacheMutualFollowStatus(String userId1, String userId2, bool isMutual) {
    final docId = _getDocId(userId1, userId2);
    _mutualFollowStatusMap[docId] = isMutual;
    notifyListeners();
  }

  /// İki kullanıcı ID'sinden doküman ID'si oluştur
  String _getDocId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Tüm verileri temizle
  void clear() {
    _currentUserId = null;
    _mutualFollowIds.clear();
    _mutualFollowStatusMap.clear();
    _mutualFollows.clear();
    _mutualFollowUserIds.clear();
    _isLoadingMutualFollows = false;
    _isCheckingMutualFollow = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
