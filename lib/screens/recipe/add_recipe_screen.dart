import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/add_recipe_provider.dart';
import '../../models/recipe_model.dart';
import '../../widgets/ingredient_input_row.dart';
import '../../core/constants/colors.dart';

/// Screen for adding a new recipe with media, ingredients, and metadata
/// 
/// Features:
/// - Media upload (image and video)
/// - Recipe title input
/// - Dynamic ingredient list with automatic calorie calculation
/// - Autocomplete ingredient suggestions
/// - Swipe-to-delete ingredients (Dismissible)
/// - Debounced API calls for calorie calculation
/// - Compact ingredient list design
/// - FAB button for adding ingredients
/// - Smooth animations
/// - Sticky total calories summary
/// - Form validation and submission
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _instructionsController = TextEditingController();
  final _titleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AddRecipeProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = AddRecipeProvider();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        _provider.addRecipeImage(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick video from gallery
  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        _provider.setRecipeVideo(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video yüklenemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show image source bottom sheet
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Yeni Tarif Ekle'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // Main scrollable content
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media Upload Section
                        _buildMediaSection(_provider),
                        const SizedBox(height: 24),

                        // Recipe Title
                        _buildTitleSection(_provider),
                        const SizedBox(height: 24),

                        // Ingredients Section
                        _buildIngredientsSection(_provider),
                        const SizedBox(height: 24),

                        // Instructions Section
                        _buildInstructionsSection(_provider),
                        const SizedBox(height: 24),

                        // Cooking Time Slider
                        _buildCookingTimeSection(_provider),
                        const SizedBox(height: 24),

                        // Difficulty Selection
                        _buildDifficultySection(_provider),
                        const SizedBox(height: 32),

                        // Submit Button
                        _buildSubmitButton(_provider),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Sticky Total Calories Summary at bottom
                if (_provider.totalCalories > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildStickyCaloriesSummary(_provider),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sticky Calories Summary at bottom
  Widget _buildStickyCaloriesSummary(AddRecipeProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.95),
            AppColors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: AppColors.textWhite,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Kalori',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${provider.totalCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Media Upload Section
  Widget _buildMediaSection(AddRecipeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Görseller & Video',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Images Grid
        if (provider.recipeImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: provider.recipeImages.length + 1,
            itemBuilder: (context, index) {
              // Add new image button
              if (index == provider.recipeImages.length) {
                return GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ekle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Image preview
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      provider.recipeImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => provider.removeRecipeImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Image number badge
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Empty state - show add buttons
          Row(
            children: [
              // Image Upload Card
              Expanded(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Fotoğraf Ekle',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kamera veya Galeri',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Video Upload Card
              Expanded(
                child: GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.textSecondary.withValues(alpha: 0.1),
                          AppColors.textSecondary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: provider.recipeVideo != null
                        ? Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => provider.setRecipeVideo(null),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.textSecondary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Video Seçildi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.videocam_rounded,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Video Ekle',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Galeriden seç',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Recipe Title Section
  Widget _buildTitleSection(AddRecipeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarif Başlığı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          maxLength: 60,
          decoration: InputDecoration(
            hintText: 'Örn: Kıymalı Pide, Tavuk Sote',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
          ),
          onChanged: provider.setRecipeTitle,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen tarif başlığını giriniz';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Ingredients Section with compact list design
  Widget _buildIngredientsSection(AddRecipeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Malzemeler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Aşağıdaki "Malzeme Ekle" butonunu kullanın',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),

            // Malzeme Ekle Butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.addIngredient();
                },
                icon: const Icon(Icons.add),
                label: const Text('Malzeme Ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients List
            if (provider.ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Henüz malzeme eklenmemiş',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Başlamak için "Malzeme Ekle" butonuna dokunun',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...provider.ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return IngredientInputRow(
                  key: ValueKey(ingredient.id),
                  ingredient: ingredient,
                  onNameChanged: (name) {
                    provider.updateIngredientName(index, name);
                  },
                  onAmountChanged: (amount) {
                    provider.updateIngredientAmount(index, amount);
                  },
                  onUnitChanged: (unit) {
                    provider.updateIngredientUnit(index, unit);
                  },
                  onRemove: () => provider.removeIngredient(index),
                  showRemoveButton: true,
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Instructions Section
  Widget _buildInstructionsSection(AddRecipeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hazırlama Talimatları',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _instructionsController,
          maxLines: 10,
          minLines: 5,
          decoration: InputDecoration(
            hintText: '1. Malzemeleri hazırlayın...\n2. Tencereye alın...\n3. Pişirin...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
          ),
          onChanged: provider.setInstructions,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen hazırlama talimatlarını giriniz';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Cooking Time Section
  Widget _buildCookingTimeSection(AddRecipeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pişirme Süresi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.cookingTime} dakika',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: provider.cookingTime.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              activeColor: AppColors.primary,
              onChanged: (value) {
                provider.setCookingTime(value.toInt());
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5 dk', style: TextStyle(color: AppColors.textSecondary)),
                Text('180 dk', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Difficulty Selection Section
  Widget _buildDifficultySection(AddRecipeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zorluk Seviyesi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<Difficulty>(
              segments: const [
                ButtonSegment(
                  value: Difficulty.easy,
                  label: Text('Kolay'),
                  icon: Icon(Icons.sentiment_satisfied),
                ),
                ButtonSegment(
                  value: Difficulty.medium,
                  label: Text('Orta'),
                  icon: Icon(Icons.sentiment_neutral),
                ),
                ButtonSegment(
                  value: Difficulty.hard,
                  label: Text('Zor'),
                  icon: Icon(Icons.sentiment_very_dissatisfied),
                ),
              ],
              selected: {provider.difficulty},
              onSelectionChanged: (Set<Difficulty> selection) {
                provider.setDifficulty(selection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.cardBackground;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.textWhite;
                  }
                  return AppColors.textPrimary;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Submit Button
  Widget _buildSubmitButton(AddRecipeProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isSubmitting
            ? null
            : () async {
                // Form validation (TextFormField validators)
                if (!_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tüm alanları doldurunuz'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Submit recipe
                final success = await provider.submitRecipe();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarif başarıyla eklendi!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                } else if (provider.errorMessage != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: provider.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Tarifi Kaydet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
