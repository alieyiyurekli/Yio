import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// Modern Dark Mode Settings Screen
/// 
/// Material 3 design with animated theme selection cards
/// and system mode toggle switch
class DarkModeScreen extends StatelessWidget {
  const DarkModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dark Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section title
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Theme selection cards
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isSystemMode = themeProvider.isSystemMode;
              final selectedMode = themeProvider.themeModeOption;

              return Column(
                children: [
                  // Light and Dark cards row
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeCard(
                          isSelected: selectedMode == ThemeModeOption.light,
                          isSystemMode: isSystemMode,
                          title: 'Light',
                          icon: Icons.light_mode_outlined,
                          isDark: false,
                          onTap: () => themeProvider.setThemeMode(ThemeModeOption.light),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ThemeCard(
                          isSelected: selectedMode == ThemeModeOption.dark,
                          isSystemMode: isSystemMode,
                          title: 'Dark',
                          icon: Icons.dark_mode_outlined,
                          isDark: true,
                          onTap: () => themeProvider.setThemeMode(ThemeModeOption.dark),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // System mode toggle
                  _SystemModeToggle(
                    isEnabled: isSystemMode,
                    onChanged: (value) {
                      if (value) {
                        themeProvider.setThemeMode(ThemeModeOption.system);
                      } else {
                        // When turning off system mode, switch to light
                        themeProvider.setThemeMode(ThemeModeOption.light);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Theme selection card with preview and animation
class _ThemeCard extends StatefulWidget {
  final bool isSelected;
  final bool isSystemMode;
  final String title;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.isSelected,
    required this.isSystemMode,
    required this.title,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _borderAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_ThemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_scaleAnimation.value * 0.02);
        final borderWidth = 2.0 + (_borderAnimation.value * 2.0);

        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? colorScheme.primaryContainer.withOpacity(0.3)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.2),
                  width: widget.isSelected ? borderWidth : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Preview mock UI
                    _ThemePreview(isDark: widget.isDark),
                    const SizedBox(height: 16),

                    // Icon and title
                    Icon(
                      widget.icon,
                      size: 24,
                      color: widget.isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: widget.isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Radio indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: widget.isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Preview mock UI showing theme appearance
class _ThemePreview extends StatelessWidget {
  final bool isDark;

  const _ThemePreview({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            // Content blocks
            Row(
              children: [
                _buildBlock(isDark, colorScheme.primary, 24),
                const SizedBox(width: 6),
                _buildBlock(isDark, colorScheme.secondary, 16),
                const SizedBox(width: 6),
                _buildBlock(isDark, colorScheme.tertiary, 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(bool isDark, Color color, double width) {
    return Container(
      width: width,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.8 : 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// System mode toggle switch
class _SystemModeToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _SystemModeToggle({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SwitchListTile(
      value: isEnabled,
      onChanged: onChanged,
      title: const Text('Use device settings'),
      subtitle: const Text(
        'Match appearance to your device\'s Display & Brightness settings',
      ),
      activeThumbColor: colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
