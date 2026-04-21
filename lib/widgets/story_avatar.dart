import 'package:flutter/material.dart';

/// Premium Story Avatar with dark mode support
/// Instagram-style story bubbles with soft borders
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                          ? [
                              isDark 
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE0E0E0),
                              isDark 
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE0E0E0),
                            ]
                          : [
                              isDark 
                                  ? const Color(0xFFFF8A50)
                                  : theme.colorScheme.primary,
                              isDark 
                                  ? const Color(0xFFFF9B6E)
                                  : const Color(0xFFFF9B6E),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark 
                          ? const Color(0xFF2A2A2A)
                          : theme.colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (exception, stackTrace) {},
                      child: Image.network(
                        avatarUrl,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: isDark 
                                ? const Color(0xFFE0E0E0)
                                : theme.colorScheme.onSurfaceVariant,
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
                        color: isDark 
                            ? const Color(0xFFFF8A50)
                            : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark 
                              ? const Color(0xFF121212)
                              : theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
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
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  color: isDark 
                      ? const Color(0xFFE0E0E0)
                      : theme.colorScheme.onSurface,
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
