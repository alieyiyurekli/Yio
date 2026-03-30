import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_recipe_model.dart';
import '../../data/mock/dummy_data.dart';
import '../../core/constants/colors.dart';
import '../../core/models/app_user.dart';
import '../../core/services/user_service.dart';
import '../../repositories/recipe_repository.dart';
import '../recipe/user_recipe_detail_screen.dart';
import '../../widgets/recipe_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  late final RecipeRepository _repository;
  final _userService = UserService();
  String? _currentUserId;
  List<UserRecipeModel> _userRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = context.read<RecipeRepository>();
    _currentUserId = context.read<FirebaseAuth>().currentUser?.uid;
    _loadUserRecipes();
  }

  Future<void> _loadUserRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _repository.getAllRecipes();
      debugPrint('=== PROFİL: ${recipes.length} tarif yüklendi ===');
      for (var recipe in recipes) {
        debugPrint('- ${recipe.title} (${recipe.totalCalories} kcal)');
      }
      setState(() {
        _userRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('=== PROFİL HATA: $e ===');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarifler yüklenemedi: $e')),
        );
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar with Settings
            SliverAppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              pinned: true,
              actions: [
                IconButton(
                  onPressed: () {
                    // TODO: Implement settings
                  },
                  icon: const Icon(Icons.settings),
                ),
                IconButton(
                  onPressed: () async {
                    await context.read<FirebaseAuth>().signOut();
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),

            // Profile Section — Show user data from Firestore
            SliverToBoxAdapter(
              child: _currentUserId != null
                  ? StreamBuilder<AppUser?>(
                      stream: _userService.userProfileStream(_currentUserId!),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || user == null) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Kullanıcı bilgileri yükleniyor...'),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? Text(
                                          _getInitials(user.name),
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textWhite,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Username
                              Text(
                                user.name.isNotEmpty ? user.name : 'Kullanıcı',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Username (@handle)
                              if (user.username != null)
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (user.username != null)
                                const SizedBox(height: 8),

                              // Description/Bio
                              Text(
                                user.bio ?? 'Yemek sevgili | Pişirme tutkunu',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatColumn(
                                    label: 'İlgi Alanları',
                                    value: '${user.interests.length}',
                                  ),
                                  _StatColumn(
                                    label: 'Takipçiler',
                                    value: '0',
                                  ),
                                  _StatColumn(
                                    label: 'Takip Edilen',
                                    value: '0',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Achievements
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Başarımlar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _AchievementBadge(
                                        icon: Icons.restaurant,
                                        label: 'Yeni Üye',
                                      ),
                                      _AchievementBadge(
                                        icon: Icons.verified,
                                        label: 'Onboarding',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Kullanıcı yükleniyor...'),
                    ),
            ),

            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                selectedTab: _selectedTab,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
              ),
            ),

            // Recipe List
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : _userRecipes.isEmpty && _selectedTab == 0
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 64,
                                  color: AppColors.textLight,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Henüz tarifiniz yok',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'İlk tarifinizi eklemek için + butonuna basın',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (_selectedTab == 0) {
                              // Show user recipes - convert to Recipe for RecipeCard
                              if (index >= _userRecipes.length) {
                                return const SizedBox.shrink();
                              }
                              final userRecipe = _userRecipes[index];
                              final recipe = userRecipe.toRecipe();

                              return Stack(
                                children: [
                                  RecipeCard(
                                    recipe: recipe,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const UserRecipeDetailScreen(),
                                          settings: RouteSettings(
                                            arguments: userRecipe,
                                          ),
                                        ),
                                      );
                                    },
                                    onLike: null, // Disable like for user's own recipes
                                  ),
                                  // Delete button overlay
                                  Positioned(
                                    top: 20,
                                    left: 28,
                                    child: Material(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text('Tarifi Sil'),
                                              content: Text(
                                                  '${userRecipe.title} tarifini silmek istediğinizden emin misiniz?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('İptal'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    await _repository
                                                        .deleteRecipe(
                                                            userRecipe.id);
                                                    _loadUserRecipes();
                                                  },
                                                  child: const Text('Sil',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Video indicator badge
                                  if (userRecipe.videoPath != null)
                                    Positioned(
                                      bottom: 12,
                                      left: 28,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.play_arrow,
                                                color: Colors.white, size: 14),
                                            SizedBox(width: 3),
                                            Text(
                                              '— —',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            } else {
                              // Show favorites (dummy data for now)
                              final recipes = DummyData.recipes
                                  .where((r) => r.isFavorite)
                                  .toList();
                              if (index >= recipes.length) {
                                return const SizedBox.shrink();
                              }
                              return RecipeCard(
                                recipe: recipes[index],
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/recipeDetail',
                                    arguments: recipes[index],
                                  );
                                },
                                onLike: () {
                                  setState(() {
                                    recipes[index].isFavorite =
                                        !recipes[index].isFavorite;
                                    recipes[index].likes +=
                                        recipes[index].isFavorite ? 1 : -1;
                                  });
                                },
                              );
                            }
                          },
                          childCount: _selectedTab == 0
                              ? _userRecipes.length
                              : DummyData.recipes
                                      .where((r) => r.isFavorite)
                                      .length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  _TabBarDelegate({
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tariflerim',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedTab == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedTab == 0
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (selectedTab == 0)
                    Container(
                      height: 3,
                      width: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Favoriler',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedTab == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedTab == 1
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (selectedTab == 1)
                    Container(
                      height: 3,
                      width: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return oldDelegate.selectedTab != selectedTab;
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AchievementBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
