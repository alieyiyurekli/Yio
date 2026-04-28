import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/follow_provider.dart';
import '../../providers/search_provider.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadSuggestedUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final searchProvider = context.read<SearchProvider>();
    if (query.isEmpty) {
      setState(() => _isSearchActive = false);
      searchProvider.loadSuggestedUsers();
    } else {
      setState(() => _isSearchActive = true);
      searchProvider.searchUsers(query);
    }
  }

  void _onUserTap(Map<String, dynamic> userData) {
    final userId = userData['id'] as String;
    context.read<SearchProvider>().addToRecentSearches(userData);
    context.push('/other-profile/$userId');
  }
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    appBar: AppBar(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          'Kullanıcı Ara',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı veya isim ara...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isSearchActive
                ? _buildSearchResults()
                : _buildDefaultContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer2<SearchProvider, FollowProvider>(
      builder: (context, searchProvider, followProvider, _) {
        if (searchProvider.isSearching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (searchProvider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 48,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkIconInactive
                      : AppColors.lightTextTertiary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Kullanıcı bulunamadı',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: searchProvider.searchResults.length,
          itemBuilder: (context, index) {
            final userData = searchProvider.searchResults[index];
            final userId = userData['id'] as String;
            final followStatus = followProvider.getFollowStatus(userId);

            return FutureBuilder<String>(
              future: followStatus.then((s) => s.name),
              builder: (context, snapshot) {
                final statusName = snapshot.data ?? 'notFollowing';
                return _buildUserListItem(
                  userData: userData,
                  followStatus: statusName,
                  onTap: () => _onUserTap(userData),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Consumer<SearchProvider>(
        builder: (context, searchProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Searches
              if (searchProvider.recentSearches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    'Son Aramalar',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: searchProvider.recentSearches.length,
                    itemBuilder: (context, index) {
                      final userData = searchProvider.recentSearches[index];
                      return _buildRecentSearchItem(userData);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Suggested Users
              if (searchProvider.suggestedUsers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    'Önerilen Kullanıcılar',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: searchProvider.suggestedUsers.length,
                  itemBuilder: (context, index) {
                    final userData = searchProvider.suggestedUsers[index];
                    return Consumer<FollowProvider>(
                      builder: (context, followProvider, _) {
                        final userId = userData['id'] as String;
                        final followStatus = followProvider.getFollowStatus(userId);
                        return FutureBuilder<String>(
                          future: followStatus.then((s) => s.name),
                          builder: (context, snapshot) {
                            final statusName = snapshot.data ?? 'notFollowing';
                            return _buildUserListItem(
                              userData: userData,
                              followStatus: statusName,
                              onTap: () => _onUserTap(userData),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],

              if (searchProvider.suggestedUsers.isEmpty &&
                  searchProvider.recentSearches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl4),
                    child: Text(
                      'Kullanıcı bulmaya başla',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentSearchItem(Map<String, dynamic> userData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = userData['id'] as String;
    final displayName = userData['displayName'] as String? ?? 'Kullanıcı';
    final photoUrl = userData['photoUrl'] as String?;

    return GestureDetector(
      onTap: () => _onUserTap(userData),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: 70,
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem({
    required Map<String, dynamic> userData,
    required String followStatus,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = userData['id'] as String;
    final displayName = userData['displayName'] as String? ?? 'Kullanıcı';
    final username = userData['username'] as String? ?? userData['email']?.toString().split('@')[0] ?? 'user';
    final photoUrl = userData['photoUrl'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: ClipOval(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '@$username',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Follow Button
            _buildFollowButton(userId, followStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(String userId, String followStatus) {
    final followProvider = context.read<FollowProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFollowing = followStatus == 'following';
    final isPending = followStatus == 'pending';

    return SizedBox(
      width: 90,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (isFollowing) {
              await followProvider.unfollowUser(userId);
            } else if (isPending) {
              await followProvider.cancelFollowRequest(userId);
            } else {
              await followProvider.followUser(userId);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isFollowing
                  ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                  : AppColors.primary,
              border: Border.all(
                color: isFollowing ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                isPending
                    ? 'İsteğiniz Var'
                    : (isFollowing ? 'Takip Et' : 'Takip Et'),
                style: AppTextStyles.labelSmall.copyWith(
                  color: isFollowing ? AppColors.primary : AppColors.lightTextInverse,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Icon(
        Icons.person,
        color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
      ),
    );
  }
}
