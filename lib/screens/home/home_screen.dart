import 'package:flutter/material.dart';
import '../../data/mock/dummy_data.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/story_avatar.dart';
import '../../core/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            _buildAppBar(),

            // Stories
            _buildStories(),

            // Tabs
            _buildTabs(),

            // Recipe Feed
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: DummyData.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = DummyData.recipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/recipeDetail',
                        arguments: recipe,
                      );
                    },
                    onLike: () {
                      setState(() {
                        recipe.isFavorite = !recipe.isFavorite;
                        recipe.likes += recipe.isFavorite ? 1 : -1;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'YIO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          // Notification Icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          // Message Icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined),
          ),
          // AI Assistant Icon
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/aiAssistant');
              },
              icon: const Icon(
                Icons.smart_toy,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: DummyData.storyNames.length,
        itemBuilder: (context, index) {
          return StoryAvatar(
            name: DummyData.storyNames[index],
            avatarUrl: DummyData.storyAvatars[index],
            isYourStory: index == 0,
            onTap: () {
              // Handle story tap
            },
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Trend', 'Following', 'New'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedTab == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTab == index
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_selectedTab == index)
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
        ),
      ),
    );
  }
}
