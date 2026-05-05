import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/follow_models.dart';
import '../../providers/follow_provider.dart';

/// Reusable Follow Button Widget
/// Handles follow, unfollow, and follow request states
class FollowButton extends StatefulWidget {
  final String userId;
  final double? width;
  final double? height;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.userId,
    this.width,
    this.height,
    this.onFollowChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final followProvider = context.read<FollowProvider>();
    final followStatus = followProvider.getFollowStatus(widget.userId);

    return FutureBuilder<FollowStatus>(
      future: followStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width ?? 90,
            height: widget.height ?? 32,
            child: const Center(child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          );
        }

        final status = snapshot.data ?? FollowStatus.notFollowing;
        final isFollowing = status == FollowStatus.following;
        final isPending = status == FollowStatus.pending;

        return SizedBox(
          width: widget.width ?? 90,
          height: widget.height ?? 32,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : () => _handleFollowAction(followProvider),
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
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFollowing ? AppColors.primary : AppColors.lightTextInverse,
                            ),
                          ),
                        )
                      : Text(
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
      },
    );
  }

  Future<void> _handleFollowAction(FollowProvider followProvider) async {
    setState(() => _isLoading = true);

    try {
      final status = await followProvider.getFollowStatus(widget.userId);

      if (status == FollowStatus.following) {
        await followProvider.unfollowUser(widget.userId);
      } else if (status == FollowStatus.pending) {
        await followProvider.cancelFollowRequest(widget.userId);
      } else {
        await followProvider.followUser(widget.userId);
      }

      widget.onFollowChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
