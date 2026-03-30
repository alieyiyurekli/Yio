import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class StoryAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isYourStory;
  final VoidCallback? onTap;

  const StoryAvatar({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.isYourStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isYourStory
                          ? [AppColors.textLight, AppColors.textLight]
                          : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardBackground,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (exception, stackTrace) {},
                      child: Image.network(
                        avatarUrl,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: AppColors.textLight,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (isYourStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardBackground,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 70,
              height: 14,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
