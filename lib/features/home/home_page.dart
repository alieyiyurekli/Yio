import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../navigation/bottom_navbar.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';

/// Home Page — main bottom navigation shell for authenticated normal users.
///
/// This is the entry point after successful auth + onboarding.
/// It wraps the existing [HomeScreen], [ProfileScreen], and placeholder tabs.
/// Navigation to this widget is handled entirely by [AppRouter] — no manual
/// Navigator calls are used here.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    _SearchTab(),
    _LikesTab(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ── Placeholder tabs — to be implemented in future features ──────────────────

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Arama',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yakında geliyor...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikesTab extends StatelessWidget {
  const _LikesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Beğendiklerim',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Beğendiğin tarifler burada görünecek',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
