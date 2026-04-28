import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/router/go_router_config.dart';
import '../../providers/search_provider.dart';
import '../../providers/follow_provider.dart';

class UserSearchTab extends StatefulWidget {
  const UserSearchTab({super.key});

  @override
  State<UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends State<UserSearchTab> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final followProvider = context.watch<FollowProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _query = value.trim());
                  if (_query.isEmpty) {
                    // Empty state
                  } else {
                    searchProvider.searchUsers(_query);
                  }
                },
              ),
            ),

            // Results
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyState()
                  : _buildUserSearchResults(searchProvider, followProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kullanıcı Ara',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İsim veya kullanıcı adı ile arama yapın',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSearchResults(SearchProvider searchProvider, FollowProvider followProvider) {
    if (searchProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              '"$_query" için kullanıcı bulunamadı',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: searchProvider.searchResults.length,
      itemBuilder: (context, index) {
        final userData = searchProvider.searchResults[index];
        return _buildUserListItem(userData, followProvider);
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, FollowProvider followProvider) {
    final userId = userData['id']?.toString() ?? '';
    final displayName = userData['displayName']?.toString() ?? 'Kullanıcı';
    final username = userData['username']?.toString() ?? userData['email']?.toString().split('@')[0] ?? 'user';
    final photoUrl = userData['photoUrl']?.toString();

    return FutureBuilder<String>(
      future: followProvider.getFollowStatus(userId).then((s) => s.name),
      builder: (context, snapshot) {
        final followStatus = snapshot.data ?? 'notFollowing';
        final isFollowing = followStatus == 'following';
        final isPending = followStatus == 'pending';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: () {
                  // Profil detaylarına git - OtherProfileScreen
                  if (userId.isNotEmpty && context.mounted) {
                    context.push('${AppRoutes.otherProfile}/$userId');
                  }
                },
                child: Container(
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
              ),
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Profil detaylarına git
                    if (userId.isNotEmpty && context.mounted) {
                      context.push('${AppRoutes.otherProfile}/$userId');
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Follow Button
              SizedBox(
                width: 80,
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
                        color: isFollowing ? Colors.grey[200] : AppColors.primary,
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
                          style: TextStyle(
                            color: isFollowing ? AppColors.primary : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.person,
        color: Colors.grey,
      ),
    );
  }
}
