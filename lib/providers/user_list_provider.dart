import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/follow_constants.dart';
import '../services/user_search_service.dart';

/// User List Provider
/// Manages paginated user lists with filtering and sorting
class UserListProvider extends ChangeNotifier {
  final UserSearchService _userSearchService;

  // List state
  List<Map<String, dynamic>> _users = [];
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  int _currentPage = 0;
  final int _pageSize = FollowConstants.defaultPageSize;

  // Filter state
  String? _filterQuery;
  UserSortOption _sortBy = UserSortOption.newest;
  UserFilterOption _filterBy = UserFilterOption.all;

  // Loading
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Error
  String? _errorMessage;

  UserListProvider({
    required UserSearchService userSearchService,
  }) : _userSearchService = userSearchService;

  // Getters
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String? get filterQuery => _filterQuery;
  UserSortOption get sortBy => _sortBy;
  UserFilterOption get filterBy => _filterBy;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get canLoadMore => _hasMore && !_isLoading && !_isLoadingMore;

  /// Load users
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      resetPagination();
    }

    if (_isLoading || (!_hasMore && !refresh)) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = _buildQuery();

      if (_lastDocument != null && !refresh) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.limit(_pageSize).get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newUsers = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      if (refresh) {
        _users = newUsers;
      } else {
        _users.addAll(newUsers);
      }

      _lastDocument = snapshot.docs.last;
      _hasMore = snapshot.docs.length == _pageSize;
      _currentPage++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Kullanıcılar yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Load more users (infinite scroll)
  Future<void> loadMoreUsers() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final query = _buildQuery().startAfterDocument(_lastDocument!);
      final snapshot = await query.limit(_pageSize).get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final newUsers = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _users.addAll(newUsers);

      _lastDocument = snapshot.docs.last;
      _hasMore = snapshot.docs.length == _pageSize;
      _currentPage++;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = 'Daha fazla kullanıcı yüklenemedi: $e';
      notifyListeners();
    }
  }

  /// Refresh users
  void refreshUsers() {
    loadUsers(refresh: true);
  }

  /// Set filter query
  void setFilterQuery(String query) {
    if (_filterQuery != query) {
      _filterQuery = query.isEmpty ? null : query;
      resetPagination();
      notifyListeners();
    }
  }

  /// Set sort option
  void setSortBy(UserSortOption option) {
    if (_sortBy != option) {
      _sortBy = option;
      resetPagination();
      notifyListeners();
    }
  }

  /// Set filter option
  void setFilterBy(UserFilterOption option) {
    if (_filterBy != option) {
      _filterBy = option;
      resetPagination();
      notifyListeners();
    }
  }

  /// Clear filters
  void clearFilters() {
    _filterQuery = null;
    _sortBy = UserSortOption.newest;
    _filterBy = UserFilterOption.all;
    resetPagination();
    notifyListeners();
  }

  /// Reset pagination
  void resetPagination() {
    _users = [];
    _hasMore = true;
    _lastDocument = null;
    _currentPage = 0;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Build query based on filters
  Query _buildQuery() {
    final firestore = FirebaseFirestore.instance;
    Query query = firestore.collection(FollowConstants.usersCollection);

    // Apply filter by
    switch (_filterBy) {
      case UserFilterOption.private:
        query = query.where(FieldNames.isPrivate, isEqualTo: true);
        break;
      case UserFilterOption.public:
        query = query.where(FieldNames.isPrivate, isEqualTo: false);
        break;
      case UserFilterOption.all:
      default:
        break;
    }

    // Apply search filter
    if (_filterQuery != null && _filterQuery!.isNotEmpty) {
      final sanitizedQuery = _filterQuery!.trim().toLowerCase();
      query = query
          .where(FieldNames.name, isGreaterThanOrEqualTo: sanitizedQuery)
          .where(FieldNames.name, isLessThan: '$sanitizedQuery\uf8ff');
    }

    // Apply sort
    switch (_sortBy) {
      case UserSortOption.newest:
        query = query.orderBy(FieldNames.createdAt, descending: true);
        break;
      case UserSortOption.oldest:
        query = query.orderBy(FieldNames.createdAt, descending: false);
        break;
      case UserSortOption.mostFollowers:
        query = query.orderBy(FieldNames.followersCount, descending: true);
        break;
      case UserSortOption.mostRecipes:
        query = query.orderBy('recipeCount', descending: true);
        break;
      case UserSortOption.nameAsc:
        query = query.orderBy(FieldNames.name, descending: false);
        break;
    }

    return query;
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _users = [];
    _hasMore = true;
    _lastDocument = null;
    _currentPage = 0;
    _filterQuery = null;
    _sortBy = UserSortOption.newest;
    _filterBy = UserFilterOption.all;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
  }
}

/// User sort options
enum UserSortOption {
  newest,
  oldest,
  mostFollowers,
  mostRecipes,
  nameAsc,
}

extension UserSortOptionExtension on UserSortOption {
  String get label {
    switch (this) {
      case UserSortOption.newest:
        return 'En Yeni';
      case UserSortOption.oldest:
        return 'En Eski';
      case UserSortOption.mostFollowers:
        return 'En Çok Takipçi';
      case UserSortOption.mostRecipes:
        return 'En Çok Tarif';
      case UserSortOption.nameAsc:
        return 'İsme Göre (A-Z)';
    }
  }
}

/// User filter options
enum UserFilterOption {
  all,
  public,
  private,
}

extension UserFilterOptionExtension on UserFilterOption {
  String get label {
    switch (this) {
      case UserFilterOption.all:
        return 'Tümü';
      case UserFilterOption.public:
        return 'Herkese Açık';
      case UserFilterOption.private:
        return 'Özel Hesaplar';
    }
  }
}
