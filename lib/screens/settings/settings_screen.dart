import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/settings_widgets.dart';
import 'dark_mode_screen.dart';

/// Premium Settings Screen
/// Instagram-level quality settings with all sections
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    // Initialize settings provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().init();
    });
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Account Section
          SettingsSection(
            title: 'Hesap',
            children: [
              NavigationTile(
                icon: Icons.person_outline,
                title: 'Profili Düzenle',
                onTap: () {
                  // Navigate to edit profile
                },
                isFirst: true,
              ),
              NavigationTile(
                icon: Icons.email_outlined,
                title: 'E-posta Değiştir',
                onTap: () {
                  // Navigate to change email
                },
              ),
              NavigationTile(
                icon: Icons.lock_outline,
                title: 'Şifre Değiştir',
                onTap: () {
                  // Navigate to change password
                },
              ),
              DestructiveActionTile(
                icon: Icons.delete_outline,
                title: 'Hesabı Sil',
                subtitle: 'Bu işlem geri alınamaz',
                onTap: () => _showDeleteAccountDialog(),
                isLast: true,
              ),
            ],
          ),

          // Notifications Section
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SettingsSection(
                title: 'Bildirimler',
                children: [
                  ToggleTile(
                    icon: Icons.favorite_border,
                    title: 'Beğeni Bildirimleri',
                    value: settings.likesNotifications,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      settings.setLikesNotifications(value);
                    },
                    isFirst: true,
                  ),
                  ToggleTile(
                    icon: Icons.comment_outlined,
                    title: 'Yorum Bildirimleri',
                    value: settings.commentsNotifications,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      settings.setCommentsNotifications(value);
                    },
                  ),
                  ToggleTile(
                    icon: Icons.person_add_outlined,
                    title: 'Takipçi Bildirimleri',
                    value: settings.followersNotifications,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      settings.setFollowersNotifications(value);
                    },
                    isLast: true,
                  ),
                ],
              );
            },
          ),

          // Appearance Section
          SettingsSection(
            title: 'Görünüm',
            children: [
              NavigationTile(
                icon: Icons.dark_mode_outlined,
                title: 'Karanlık Mod',
                subtitle: _getThemeSubtitle(context),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DarkModeScreen(),
                    ),
                  );
                },
                isFirst: true,
                isLast: true,
              ),
            ],
          ),

          // Content Preferences Section
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SettingsSection(
                title: 'İçerik Tercihleri',
                children: [
                  NavigationTile(
                    icon: Icons.restaurant_outlined,
                    title: 'Diyet Türü',
                    subtitle: _getDietTypeLabel(settings.dietType),
                    onTap: () => _showDietTypeDialog(settings),
                    isFirst: true,
                  ),
                  NavigationTile(
                    icon: Icons.bar_chart_outlined,
                    title: 'Zorluk Filtresi',
                    subtitle: _getDifficultyLabel(settings.difficultyFilter),
                    onTap: () => _showDifficultyDialog(settings),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.timer_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Maksimum Pişirme Süresi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${settings.maxCookingTime} dakika',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: settings.maxCookingTime.toDouble(),
                          min: 0,
                          max: 120,
                          divisions: 12,
                          label: '${settings.maxCookingTime} dk',
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            settings.setMaxCookingTime(value.toInt());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Privacy Section
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SettingsSection(
                title: 'Gizlilik',
                children: [
                  ToggleTile(
                    icon: Icons.lock_outline,
                    title: 'Özel Hesap',
                    subtitle: 'Sadece takipçileriniz içeriğinizi görebilir',
                    value: settings.privateAccount,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      settings.setPrivateAccount(value);
                    },
                    isFirst: true,
                  ),
                  NavigationTile(
                    icon: Icons.visibility_outlined,
                    title: 'Profilimi Kim Görebilir',
                    subtitle: _getVisibilityLabel(settings.profileVisibility),
                    onTap: () => _showVisibilityDialog(settings),
                  ),
                  ToggleTile(
                    icon: Icons.person_add_outlined,
                    title: 'Takip İsteği Onayı',
                    subtitle: 'Takip isteklerini manuel onayla',
                    value: settings.followRequestApproval,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      settings.setFollowRequestApproval(value);
                    },
                    isLast: true,
                  ),
                ],
              );
            },
          ),

          // Data Section
          SettingsSection(
            title: 'Veri',
            children: [
              NavigationTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Önbelleği Temizle',
                subtitle: 'Geçici dosyaları ve önbelleği sil',
                onTap: () => _showClearCacheDialog(),
                isFirst: true,
                isLast: true,
              ),
            ],
          ),

          // About Section
          SettingsSection(
            title: 'Hakkında',
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: 'Sürüm',
                subtitle: 'v$_appVersion ($_buildNumber)',
                isFirst: true,
              ),
              NavigationTile(
                icon: Icons.description_outlined,
                title: 'Gizlilik Politikası',
                onTap: () {
                  // Open privacy policy
                },
              ),
              NavigationTile(
                icon: Icons.gavel_outlined,
                title: 'Kullanım Koşulları',
                onTap: () {
                  // Open terms of service
                },
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeSubtitle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    switch (themeProvider.themeModeOption) {
      case ThemeModeOption.light:
        return 'Aydınlık';
      case ThemeModeOption.dark:
        return 'Karanlık';
      case ThemeModeOption.system:
        return 'Sistem Ayarı';
    }
  }

  String _getDietTypeLabel(String dietType) {
    switch (dietType) {
      case 'vegan':
        return 'Vegan';
      case 'vegetarian':
        return 'Vejetaryen';
      case 'keto':
        return 'Keto';
      default:
        return 'Yok';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Kolay';
      case 'medium':
        return 'Orta';
      case 'hard':
        return 'Zor';
      default:
        return 'Tümü';
    }
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'followers':
        return 'Sadece Takipçiler';
      case 'following':
        return 'Takip Edilenler';
      default:
        return 'Herkes';
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle delete account
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showDietTypeDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diyet Türü'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DietTypeOption(
              label: 'Yok',
              value: 'none',
              selected: settings.dietType,
              onTap: () {
                settings.setDietType('none');
                Navigator.of(context).pop();
              },
            ),
            _DietTypeOption(
              label: 'Vegan',
              value: 'vegan',
              selected: settings.dietType,
              onTap: () {
                settings.setDietType('vegan');
                Navigator.of(context).pop();
              },
            ),
            _DietTypeOption(
              label: 'Vejetaryen',
              value: 'vegetarian',
              selected: settings.dietType,
              onTap: () {
                settings.setDietType('vegetarian');
                Navigator.of(context).pop();
              },
            ),
            _DietTypeOption(
              label: 'Keto',
              value: 'keto',
              selected: settings.dietType,
              onTap: () {
                settings.setDietType('keto');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zorluk Filtresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DifficultyOption(
              label: 'Tümü',
              value: 'all',
              selected: settings.difficultyFilter,
              onTap: () {
                settings.setDifficultyFilter('all');
                Navigator.of(context).pop();
              },
            ),
            _DifficultyOption(
              label: 'Kolay',
              value: 'easy',
              selected: settings.difficultyFilter,
              onTap: () {
                settings.setDifficultyFilter('easy');
                Navigator.of(context).pop();
              },
            ),
            _DifficultyOption(
              label: 'Orta',
              value: 'medium',
              selected: settings.difficultyFilter,
              onTap: () {
                settings.setDifficultyFilter('medium');
                Navigator.of(context).pop();
              },
            ),
            _DifficultyOption(
              label: 'Zor',
              value: 'hard',
              selected: settings.difficultyFilter,
              onTap: () {
                settings.setDifficultyFilter('hard');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVisibilityDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Görünürlüğü'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VisibilityOption(
              label: 'Herkes',
              value: 'everyone',
              selected: settings.profileVisibility,
              onTap: () {
                settings.setProfileVisibility('everyone');
                Navigator.of(context).pop();
              },
            ),
            _VisibilityOption(
              label: 'Sadece Takipçiler',
              value: 'followers',
              selected: settings.profileVisibility,
              onTap: () {
                settings.setProfileVisibility('followers');
                Navigator.of(context).pop();
              },
            ),
            _VisibilityOption(
              label: 'Takip Edilenler',
              value: 'following',
              selected: settings.profileVisibility,
              onTap: () {
                settings.setProfileVisibility('following');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Önbelleği Temizle'),
        content: const Text(
          'Önbelleği temizlemek istediğinizden emin misiniz? Bu işlem geçici dosyaları silecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle clear cache
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Önbellek temizlendi')),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}

// Helper widgets for dialogs
class _DietTypeOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _DietTypeOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == value;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == value;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == value;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
