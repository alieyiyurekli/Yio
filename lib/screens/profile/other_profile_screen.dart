import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/follow_provider.dart';
import '../../widgets/mutual_follow_badge.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;

  const OtherProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> _getUser(String userId) async {
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
      ),
      body: FutureBuilder<UserModel?>(
        future: _getUser(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Kullanıcı bulunamadı',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            );
          }

          final user = snapshot.data!;
          return _buildProfileContent(user, isDark);
        },
      ),
    );
  }

  Widget _buildProfileContent(UserModel user, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Profile Picture with Mutual Follow Indicator
                MutualFollowIndicator(
                  userId: widget.userId,
                  badgeSize: 24,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: user.photoUrl != null
                          ? Image.network(
                              user.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildProfilePlaceholder(),
                            )
                          : _buildProfilePlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Display Name
                Text(
                  user.displayName ?? 'Kullanıcı',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Username
                Text(
                  '@${user.email.split('@')[0]}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.bio!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  count: user.recipeCount,
                  label: 'Tarif',
                  isDark: isDark,
                ),
                _buildStatItem(
                  count: user.followersCount,
                  label: 'Takipçi',
                  isDark: isDark,
                  onTap: () => context.push('/followers/${widget.userId}'),
                ),
                _buildStatItem(
                  count: user.followingCount,
                  label: 'Takip Edilen',
                  isDark: isDark,
                  onTap: () => context.push('/following/${widget.userId}'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Mutual Follow Status
          MutualFollowStatusWidget(
            userId: widget.userId,
            userName: user.displayName ?? 'Kullanıcı',
          ),

          const SizedBox(height: AppSpacing.lg),

          // Follow Button
          Consumer<FollowProvider>(
            builder: (context, followProvider, _) {
              final followStatus = followProvider.getFollowStatus(widget.userId);
              return FutureBuilder<String>(
                future: followStatus.then((s) => s.name),
                builder: (context, snapshot) {
                  final statusName = snapshot.data ?? 'notFollowing';
                  final isFollowing = statusName == 'following';
                  final isPending = statusName == 'pending';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (isFollowing) {
                              await followProvider.unfollowUser(widget.userId);
                            } else if (isPending) {
                              await followProvider
                                  .cancelFollowRequest(widget.userId);
                            } else {
                              await followProvider.followUser(widget.userId);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFollowing
                                  ? (isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface)
                                  : AppColors.primary,
                              border: Border.all(
                                color: isFollowing
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                isPending
                                    ? 'İsteğiniz Bekleniyor'
                                    : (isFollowing ? 'Takip Etmeyi Bırak' : 'Takip Et'),
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: isFollowing
                                      ? AppColors.primary
                                      : AppColors.lightTextInverse,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl4),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }

  Widget _buildProfilePlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Icon(
        Icons.person,
        size: 40,
        color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
      ),
    );
  }
}
