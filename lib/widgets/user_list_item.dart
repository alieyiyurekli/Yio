import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/follow_provider.dart';
import 'follow_button.dart';

/// Reusable User List Item Widget
/// Displays user information with follow button
class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final bool showFollowButton;
  final Widget? trailing;

  const UserListItem({
    super.key,
    required this.user,
    this.onTap,
    this.showFollowButton = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final item = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Profile Picture
          _buildProfilePicture(isDark),
          const SizedBox(width: AppSpacing.lg),
          // User Info
          Expanded(
            child: _buildUserInfo(isDark),
          ),
          // Trailing Widget or Follow Button
          if (trailing != null)
            trailing!
          else if (showFollowButton)
            FollowButton(userId: user.id),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: item,
      );
    }

    return item;
  }

  Widget _buildProfilePicture(bool isDark) {
    return Container(
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
                errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildUserInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName ?? 'Kullanıcı',
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '@${user.email.split('@')[0]}',
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Icon(
        Icons.person,
        color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
      ),
    );
  }
}

/// User List Item with Map data (for search results)
class UserListItemFromMap extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onTap;
  final bool showFollowButton;
  final Widget? trailing;

  const UserListItemFromMap({
    super.key,
    required this.userData,
    this.onTap,
    this.showFollowButton = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = userData['id'] as String;
    final displayName = userData['displayName'] as String? ?? 'Kullanıcı';
    final username = userData['username'] as String? ?? 'user';
    final photoUrl = userData['photoUrl'] as String?;

    final item = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Profile Picture
          _buildProfilePicture(isDark, photoUrl),
          const SizedBox(width: AppSpacing.lg),
          // User Info
          Expanded(
            child: _buildUserInfo(isDark, displayName, username),
          ),
          // Trailing Widget or Follow Button
          if (trailing != null)
            trailing!
          else if (showFollowButton)
            FollowButton(userId: userId),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: item,
      );
    }

    return item;
  }

  Widget _buildProfilePicture(bool isDark, String? photoUrl) {
    return Container(
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
                errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildUserInfo(bool isDark, String displayName, String username) {
    return Column(
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
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Icon(
        Icons.person,
        color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
      ),
    );
  }
}
