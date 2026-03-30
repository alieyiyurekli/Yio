import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/auth_service.dart';

/// Admin Home Page — placeholder dashboard for admin role users.
///
/// Shown when [AppUser.role] == 'admin' after successful auth + onboarding.
/// Navigation handled entirely by [AppRouter].
///
/// TODO: Implement full admin dashboard (user management, content moderation, etc.)
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final authService = AuthService();
              await authService.signOut();
              // AppRouter's authStateChanges will fire and navigate to LoginPage
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Admin Paneli',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Yönetici paneliniz hazırlanıyor. Yakında burada kullanıcı yönetimi, içerik moderasyonu ve uygulama istatistiklerine erişebileceksiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const _AdminStatCard(
                icon: Icons.people_outline,
                label: 'Kullanıcı Yönetimi',
                description: 'Yakında',
                onTap: null,
              ),
              const SizedBox(height: 12),
              const _AdminStatCard(
                icon: Icons.restaurant_menu,
                label: 'İçerik Moderasyonu',
                description: 'Yakında',
                onTap: null,
              ),
              const SizedBox(height: 12),
              const _AdminStatCard(
                icon: Icons.bar_chart,
                label: 'İstatistikler',
                description: 'Yakında',
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;

  const _AdminStatCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: AppColors.divider.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: onTap != null
                      ? AppColors.textSecondary
                      : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
