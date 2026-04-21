import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';
import '../../core/services/recipe_service.dart';
import '../../core/services/user_service.dart';
import '../../services/firebase_storage_service.dart';

/// Add Recipe Page — Fully functional form connected to Firebase
///
/// Flow:
/// 1. User fills in title, description, ingredients, steps, etc.
/// 2. User picks an image from gallery
/// 3. User taps Save
/// 4. Image is uploaded to Firebase Storage
/// 5. Recipe is saved to Firestore (global recipes/ collection)
/// 6. User is navigated back with success snackbar
class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookingTimeController = TextEditingController(text: '30');
  final _caloriesController = TextEditingController(text: '0');

  // Dynamic ingredient & step controllers
  final List<TextEditingController> _ingredientControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];

  // Dropdowns
  String _selectedCategory = 'Kahvaltı';
  String _selectedDifficulty = 'easy';

  // Image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Loading state
  bool _isLoading = false;

  // Constants
  static const List<String> _categories = [
    'Kahvaltı',
    'Öğle Yemeği',
    'Akşam Yemeği',
    'Atıştırmalık',
    'Tatlı',
    'Çorba',
    'Salata',
    'İçecek',
  ];

  static const Map<String, String> _difficulties = {
    'easy': 'Kolay',
    'medium': 'Orta',
    'hard': 'Zor',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _caloriesController.dispose();
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Image Picker ──────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
        );
      }
    }
  }

  // ── Dynamic List Management ───────────────────────────────────────────────────

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientControllers.length <= 1) return;
    _ingredientControllers[index].dispose();
    setState(() {
      _ingredientControllers.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length <= 1) return;
    _stepControllers[index].dispose();
    setState(() {
      _stepControllers.removeAt(index);
    });
  }

  // ── Validation ────────────────────────────────────────────────────────────────

  String? _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      return 'Tarif başlığı boş olamaz';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Açıklama boş olamaz';
    }
    final hasIngredient =
        _ingredientControllers.any((c) => c.text.trim().isNotEmpty);
    if (!hasIngredient) {
      return 'En az 1 malzeme girmelisiniz';
    }
    final hasStep = _stepControllers.any((c) => c.text.trim().isNotEmpty);
    if (!hasStep) {
      return 'En az 1 adım girmelisiniz';
    }
    if (_selectedImage == null) {
      return 'Lütfen bir fotoğraf seçin';
    }
    return null;
  }

  // ── Save Recipe ───────────────────────────────────────────────────────────────

  Future<void> _saveRecipe() async {
    final error = _validateForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<FirebaseAuth>().currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final recipeService = context.read<RecipeService>();
      final userService = UserService();

      // Get user profile for username/name
      final userProfile = await userService.getUserProfile(currentUser.uid);
      final username = userProfile?.username ?? currentUser.email ?? 'user';
      final name = userProfile?.name ?? currentUser.displayName ?? 'Kullanıcı';

      // Firebase Storage service for current user
      final storageService = FirebaseStorageService(userId: currentUser.uid);

      // Collect ingredients (non-empty only)
      final ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Collect steps (non-empty only)
      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await recipeService.createRecipe(
        userId: currentUser.uid,
        username: username,
        name: name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: ingredients,
        steps: steps,
        cookingTime: int.tryParse(_cookingTimeController.text) ?? 30,
        calories: int.tryParse(_caloriesController.text) ?? 0,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        imageFile: _selectedImage,
        storageService: storageService,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarif başarıyla kaydedildi! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilemedi: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tarif Ekle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveRecipe,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Image Picker ─────────────────────────────────────────────────
            _buildSectionTitle('Fotoğraf'),
            _buildImagePicker(),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────────────
            _buildSectionTitle('Tarif Adı *'),
            _buildTextField(
              controller: _titleController,
              hint: 'örn. Mercimek Çorbası',
              maxLength: 80,
            ),
            const SizedBox(height: 20),

            // ── Description ──────────────────────────────────────────────────
            _buildSectionTitle('Açıklama *'),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Tarifin kısa açıklaması...',
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 20),

            // ── Ingredients ──────────────────────────────────────────────────
            _buildSectionTitle('Malzemeler *'),
            ..._buildIngredientsList(),
            _buildAddButton(
              label: '+ Malzeme Ekle',
              onTap: _addIngredient,
            ),
            const SizedBox(height: 20),

            // ── Steps ────────────────────────────────────────────────────────
            _buildSectionTitle('Yapılış Adımları *'),
            ..._buildStepsList(),
            _buildAddButton(
              label: '+ Adım Ekle',
              onTap: _addStep,
            ),
            const SizedBox(height: 20),

            // ── Cooking Time & Calories ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Pişirme Süresi (dk)'),
                      _buildNumberField(
                        controller: _cookingTimeController,
                        hint: '30',
                        suffix: 'dk',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Kalori'),
                      _buildNumberField(
                        controller: _caloriesController,
                        hint: '0',
                        suffix: 'kcal',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────────────
            _buildSectionTitle('Kategori'),
            _buildDropdown<String>(
              value: _selectedCategory,
              items: _categories,
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 20),

            // ── Difficulty ───────────────────────────────────────────────────
            _buildSectionTitle('Zorluk'),
            _buildDropdown<String>(
              value: _selectedDifficulty,
              items: _difficulties.keys.toList(),
              labelBuilder: (v) => _difficulties[v]!,
              onChanged: (v) => setState(() => _selectedDifficulty = v!),
            ),
            const SizedBox(height: 32),

            // ── Save Button ──────────────────────────────────────────────────
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImage == null
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.primary,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fotoğraf Seç',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Galeriden bir fotoğraf seçin',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          counterStyle: const TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight),
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    return List.generate(
      _ingredientControllers.length,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _ingredientControllers[i],
                  decoration: const InputDecoration(
                    hintText: 'örn. 2 su bardağı un',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            if (_ingredientControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red, size: 22),
                onPressed: () => _removeIngredient(i),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStepsList() {
    return List.generate(
      _stepControllers.length,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 8, right: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _stepControllers[i],
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Bu adımda ne yapılacak?',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            if (_stepControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red, size: 22),
                onPressed: () => _removeStep(i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveRecipe,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Tarifi Kaydet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
