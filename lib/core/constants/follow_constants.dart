/// Follow system constants
class FollowConstants {
  FollowConstants._();

  // Rate limiting
  static const int maxFollowsPerDay = 100;
  static const int maxFollowsPerHour = 20;
  static const int maxFollowRequestsPerDay = 50;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Caching
  static const Duration userCacheDuration = Duration(minutes: 5);
  static const Duration searchCacheDuration = Duration(minutes: 10);

  // Search
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
  static const int minSearchLength = 2;
  static const int maxSearchLength = 30;
  static const int maxSearchResults = 50;
  static const int suggestedUsersCount = 10;

  // Collection paths
  static const String usersCollection = 'users';
  static const String followingSubcollection = 'following';
  static const String followersSubcollection = 'followers';
  static const String followRequestsSubcollection = 'followRequests';

  // Field names
  static const String fieldUserId = 'userId';
  static const String fieldFollowedAt = 'followedAt';
  static const String fieldStatus = 'status';
  static const String fieldRequesterId = 'requesterId';
  static const String fieldRequesterName = 'requesterName';
  static const String fieldRequesterPhotoUrl = 'requesterPhotoUrl';
  static const String fieldRequestedAt = 'requestedAt';
  static const String fieldIsPrivate = 'isPrivate';
  static const String fieldFollowersCount = 'followersCount';
  static const String fieldFollowingCount = 'followingCount';
  static const String fieldFollowRequestApproval = 'followRequestApproval';
}

/// Collection paths helper
class CollectionPaths {
  CollectionPaths._();

  static String users() => FollowConstants.usersCollection;
  
  static String userFollowing(String userId) =>
      '${FollowConstants.usersCollection}/$userId/${FollowConstants.followingSubcollection}';
  
  static String userFollowers(String userId) =>
      '${FollowConstants.usersCollection}/$userId/${FollowConstants.followersSubcollection}';
  
  static String userFollowRequests(String userId) =>
      '${FollowConstants.usersCollection}/$userId/${FollowConstants.followRequestsSubcollection}';
}

/// Firestore field names
class FieldNames {
  FieldNames._();

  // User fields
  static const String uid = 'uid';
  static const String email = 'email';
  static const String name = 'name';
  static const String username = 'username';
  static const String photoUrl = 'photoUrl';
  static const String bio = 'bio';
  static const String isPrivate = 'isPrivate';
  static const String followersCount = 'followersCount';
  static const String followingCount = 'followingCount';
  static const String followRequestApproval = 'followRequestApproval';
  static const String createdAt = 'createdAt';

  // Follow fields
  static const String userId = 'userId';
  static const String followedAt = 'followedAt';
  static const String status = 'status';

  // Follow request fields
  static const String requesterId = 'requesterId';
  static const String requesterName = 'requesterName';
  static const String requesterPhotoUrl = 'requesterPhotoUrl';
  static const String requestedAt = 'requestedAt';
}
