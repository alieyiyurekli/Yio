import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/follow_constants.dart';
import '../services/user_search_service.dart';

/// Search Provider
/// Manages user search operations with caching
class SearchProvider extends ChangeNotifier {
  final UserSearchService _userSearchService;
  final FirebaseAuth _auth;

  // Search state
  String _currentQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasResults = false;

  // Recent searches
  List<Map<String, dynamic>> _recentSearches = [];
  List<String> _recentQueries = [];

  // Suggestions
  List<Map<String, dynamic>> _suggestedUsers = [];

  // Cache
  final Map<String, List<Map<String, dynamic>>> _searchCache = {};
  DateTime? _lastCacheClear;

  // Error
  String? _errorMessage;

  SearchProvider({
    required UserSearchService userSearchService,
    FirebaseAuth? auth,
  })  : _userSearchService = userSearchService,
        _auth = auth ?? FirebaseAuth.instance {
    // Clear cache periodically
    _clearExpiredCache();
  }

  // Getters
  String get currentQuery => _currentQuery;
  List<Map<String, dynamic>> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  bool get hasResults => _hasResults;
  List<Map<String, dynamic>> get recentSearches => List.unmodifiable(_recentSearches);
  List<String> get recentQueries => List.unmodifiable(_recentQueries);
  List<Map<String, dynamic>> get suggestedUsers => List.unmodifiable(_suggestedUsers);
  String? get errorMessage => _errorMessage;

  /// Search users
  Future<void> searchUsers(String query) async {
    if (query.trim().length < FollowConstants.minSearchLength) {
      _searchResults = [];
      _hasResults = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _currentQuery = query;
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check cache first
      final cached = getFromCache(query);
      if (cached != null) {
        _searchResults = cached;
        _hasResults = cached.isNotEmpty;
        _isSearching = false;
        notifyListeners();
        return;
      }

      // Perform search
      final results = await _userSearchService.searchUsers(
        query,
        limit: FollowConstants.maxSearchResults,
      );

      _searchResults = results;
      _hasResults = results.isNotEmpty;

      // Save to cache
      saveToCache(query, results);

      // Add to recent queries
      addToRecentQueries(query);

      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _errorMessage = 'Arama başarısız: $e';
      notifyListeners();
    }
  }

  /// Search by username
  Future<Map<String, dynamic>?> searchByUsername(String username) async {
    try {
      return await _userSearchService.searchByUsername(username);
    } catch (e) {
      _errorMessage = 'Kullanıcı adı araması başarısız: $e';
      notifyListeners();
      return null;
    }
  }

  /// Clear search cache
  void clearSearchCache() {
    _searchCache.clear();
    _lastCacheClear = DateTime.now();
    notifyListeners();
  }

  /// Save to cache
  void saveToCache(String query, List<Map<String, dynamic>> results) {
    _searchCache[query.toLowerCase()] = results;
  }

  /// Get from cache
  List<Map<String, dynamic>>? getFromCache(String query) {
    final cached = _searchCache[query.toLowerCase()];
    if (cached != null) {
      return cached;
    }
    return null;
  }

  /// Add to recent searches
  void addToRecentSearches(Map<String, dynamic> user) {
    // Remove if already exists
    _recentSearches.removeWhere((u) => u['uid'] == user['uid']);
    // Add to beginning
    _recentSearches.insert(0, user);
    // Keep only last 20
    if (_recentSearches.length > 20) {
      _recentSearches = _recentSearches.sublist(0, 20);
    }
    notifyListeners();
  }

  /// Add to recent queries
  void addToRecentQueries(String query) {
    // Remove if already exists
    _recentQueries.remove(query);
    // Add to beginning
    _recentQueries.insert(0, query);
    // Keep only last 20
    if (_recentQueries.length > 20) {
      _recentQueries = _recentQueries.sublist(0, 20);
    }
    notifyListeners();
  }

  /// Clear recent searches
  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  /// Clear recent queries
  void clearRecentQueries() {
    _recentQueries.clear();
    notifyListeners();
  }

  /// Load suggested users
  Future<void> loadSuggestedUsers() async {
    try {
      final suggested = await _userSearchService.getSuggestedUsers(
        limit: FollowConstants.suggestedUsersCount,
      );
      _suggestedUsers = suggested;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Önerilen kullanıcılar yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Load trending users
  Future<void> loadTrendingUsers() async {
    try {
      final trending = await _userSearchService.getTrendingUsers(
        limit: FollowConstants.suggestedUsersCount,
      );
      _suggestedUsers = trending;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Trend kullanıcılar yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear expired cache entries
  void _clearExpiredCache() {
    final now = DateTime.now();
    if (_lastCacheClear != null) {
      final difference = now.difference(_lastCacheClear!);
      if (difference.inMinutes >= 30) {
        clearSearchCache();
      }
    }
  }

  /// Clear all data
  void clear() {
    _currentQuery = '';
    _searchResults = [];
    _isSearching = false;
    _hasResults = false;
    _recentSearches = [];
    _recentQueries = [];
    _suggestedUsers = [];
    _searchCache.clear();
    _lastCacheClear = null;
    _errorMessage = null;
    notifyListeners();
  }
}
