import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/mutual_follow_provider.dart';

/// Mutual Follow Badge (Takipleşme Rozeti)
/// İki kullanıcının birbirini takip ettiğini gösteren rozet
class MutualFollowBadge extends StatelessWidget {
  final String userId;
  final double size;
  final bool showText;

  const MutualFollowBadge({
    super.key,
    required this.userId,
    this.size = 16,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MutualFollowProvider>(
      builder: (context, mutualFollowProvider, _) {
        final isMutual = mutualFollowProvider.isUserMutualFollow(userId);

        if (!isMutual) {
          return const SizedBox.shrink();
        }

        if (showText) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: size,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Takipleşiyor',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.lightSurface,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.people_alt_rounded,
            size: size * 0.6,
            color: AppColors.lightTextInverse,
          ),
        );
      },
    );
  }
}

/// Mutual Follow Indicator (Takipleşme Göstergesi)
/// Profil resminin üzerinde takipleşme durumunu gösteren overlay
class MutualFollowIndicator extends StatelessWidget {
  final Widget child;
  final String userId;
  final double badgeSize;

  const MutualFollowIndicator({
    super.key,
    required this.child,
    required this.userId,
    this.badgeSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MutualFollowProvider>(
      builder: (context, mutualFollowProvider, _) {
        final isMutual = mutualFollowProvider.isUserMutualFollow(userId);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (isMutual)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.lightSurface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: badgeSize * 0.5,
                    color: AppColors.lightTextInverse,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Mutual Follow Status Widget (Takipleşme Durum Widget'ı)
/// Kullanıcının takipleşme durumunu gösteren detaylı widget
class MutualFollowStatusWidget extends StatelessWidget {
  final String userId;
  final String userName;

  const MutualFollowStatusWidget({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MutualFollowProvider>(
      builder: (context, mutualFollowProvider, _) {
        final isMutual = mutualFollowProvider.isUserMutualFollow(userId);

        if (!isMutual) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 16,
                color: AppColors.lightTextInverse,
              ),
              const SizedBox(width: 6),
              Text(
                '$userName ile takipleşiyorsunuz',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextInverse,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
