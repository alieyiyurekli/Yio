import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/follow_provider.dart';
import 'package:go_router/go_router.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;

  const FollowersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<UserModel> _followers = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreFollowers();
    }
  }

  Future<void> _loadFollowers({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _followers = [];
        _lastDoc = null;
        _hasMore = true;
      }
    });

    try {
      Query query = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .limit(20);

      if (_lastDoc != null && !refresh) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final userIds = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] as String;
      }).toList();

      final users = await Future.wait(
        userIds.map((id) => _getUserById(id)),
      );

      final validUsers = users.whereType<UserModel>().toList();

      setState(() {
        if (refresh) {
          _followers = validUsers;
        } else {
          _followers.addAll(validUsers);
        }
        _lastDoc = snapshot.docs.last;
        _hasMore = snapshot.docs.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreFollowers() async {
    await _loadFollowers();
  }

  Future<UserModel?> _getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkIconActive : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Takipçiler',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFollowers(refresh: true),
        child: _followers.isEmpty && !_isLoading
            ? _buildEmptyState(isDark)
            : ListView.builder(
                controller: _scrollController,
                itemCount: _followers.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _followers.length) {
                    return _buildLoadingIndicator();
                  }
                  return _buildFollowerItem(_followers[index], isDark);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark
                ? AppColors.darkIconInactive
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz takipçi yok',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerItem(UserModel user, bool isDark) {
    return Consumer<FollowProvider>(
      builder: (context, followProvider, _) {
        final followStatus = followProvider.getFollowStatus(user.id);
        return FutureBuilder<String>(
          future: followStatus.then((s) => s.name),
          builder: (context, snapshot) {
            final statusName = snapshot.data ?? 'notFollowing';
            return GestureDetector(
              onTap: () => context.push('/other-profile/${user.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
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
                        child: user.photoUrl != null
                            ? Image.network(
                                user.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
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
                            user.displayName ?? 'Kullanıcı',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '@${user.email.split('@')[0]}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Follow Button
                    _buildFollowButton(user.id, statusName, isDark),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowButton(String userId, String followStatus, bool isDark) {
    final followProvider = context.read<FollowProvider>();
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
                  ? (isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface)
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
                  color: isFollowing
                      ? AppColors.primary
                      : AppColors.lightTextInverse,
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

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
