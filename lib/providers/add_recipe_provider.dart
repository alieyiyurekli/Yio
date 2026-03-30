import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/ingredient_model.dart';
import '../models/user_recipe_model.dart';
import '../models/recipe_model.dart';
import '../services/image_storage_service.dart';
import '../services/firebase_storage_service.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/local_recipe_repository.dart';

/// Provider for managing the Add Recipe screen state
///
/// Manages:
/// - Ingredient list with debounced calorie calculations
/// - Recipe metadata (title, instructions, cooking time, difficulty)
/// - Media files (image, video)
/// - Calorie calculations with API debouncing
/// - Form validation
/// - Autocomplete suggestions
/// - Recipe storage using Repository Pattern (easy to switch to Firebase later)
class AddRecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;
  final FirebaseStorageService? _storageService;

  AddRecipeProvider({
    RecipeRepository? repository,
    FirebaseStorageService? storageService,
  })  : _repository = repository ?? LocalRecipeRepository(),
        _storageService = storageService;

  // Recipe metadata
  String _recipeTitle = '';
  String _instructions = '';
  int _cookingTime = 30;
  Difficulty _difficulty = Difficulty.easy;

  // Media files
  File? _recipeImage;
  File? _recipeVideo;
  final List<File> _recipeImages = [];

  // Ingredients
  final List<IngredientModel> _ingredients = [];

  // Loading states
  bool _isSubmitting = false;
  bool _isCalculatingCalories = false;

  // Error handling
  String? _errorMessage;

  // Debounce timers for API calls
  final Map<int, Timer> _debounceTimers = {};
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  // Common ingredient suggestions for autocomplete
  static const List<String> _commonIngredients = [
    // Et ürünleri
    'tavuk',
    'tavuk göğsü',
    'tavuk but',
    'kırmızı et',
    'dana eti',
    'kuzu eti',
    'somon',
    'somon fileto',
    'alabalık',
    'levrek',
    'hamsi',
    'karides',
    'midye',
    
    // Sebzeler
    'soğan',
    'sarısarı soğan',
    'kırmızı soğan',
    'sarımsak',
    'domates',
    'biber',
    'dolmalık biber',
    'biberiye',
    'patlıcan',
    'kabak',
    'havuç',
    'patates',
    'brokoli',
    'karnabahar',
    'ıspanak',
    'marul',
    'salatalık',
    'lavaş',
    'lahana',
    'pırasa',
    'mantar',
    'bezelye',
    'mısır',
    
    // Meyveler
    'elma',
    'armut',
    'muz',
    'portakal',
    'limon',
    'mandalina',
    'çilek',
    'kiraz',
    'karpuz',
    'kavun',
    'şeftali',
    'erik',
    'üzüm',
    
    // Süt ürünleri
    'süt',
    'yoğurt',
    'peynir',
    'kaşar peyniri',
    'beyaz peynir',
    'lor peyniri',
    'mozzarella',
    'tereyağı',
    'krema',
    'kaymak',
    
    // Tahıllar
    'pirinç',
    'bulgur',
    'makarna',
    'noodle',
    'yulaf',
    'mısır unu',
    'buckwheat',
    
    // Bakliyatlar
    'nohut',
    'mercimek',
    'kuru fasulye',
    'barbunya',
    'brüksel lahana',
    
    // Yağlar
    'zeytinyağı',
    'ayçiçek yağı',
    'fıstık yağı',
    
    // Baharatlar ve soslar
    'tuz',
    'karabiber',
    'kırmızı biber',
    'pul biber',
    'keçiboynuzu',
    'kimyon',
    'nane',
    'tarçın',
    'vanilya',
    'soya sosu',
    'ketçap',
    'mayonez',
    'hardal',
    'sirke',
    'limon suyu',
    
    // Diğer
    'yumurta',
    'un',
    'şeker',
    'bal',
    'pekmez',
    'fındık',
    'fıstık',
    'badem',
    'ceviz',
    'zeytin',
  ];

  // Getters
  String get recipeTitle => _recipeTitle;
  String get instructions => _instructions;
  int get cookingTime => _cookingTime;
  Difficulty get difficulty => _difficulty;
  File? get recipeImage => _recipeImage;
  File? get recipeVideo => _recipeVideo;
  List<File> get recipeImages => List.unmodifiable(_recipeImages);
  List<IngredientModel> get ingredients => List.unmodifiable(_ingredients);
  bool get isSubmitting => _isSubmitting;
  bool get isCalculatingCalories => _isCalculatingCalories;
  String? get errorMessage => _errorMessage;
  double get totalCalories =>
      _ingredients.fold(0.0, (sum, ing) => sum + ing.calories);

  // Setters
  void setRecipeTitle(String title) {
    _recipeTitle = title;
    notifyListeners();
  }

  void setInstructions(String instructions) {
    _instructions = instructions;
    notifyListeners();
  }

  void setCookingTime(int minutes) {
    _cookingTime = minutes;
    notifyListeners();
  }

  void setDifficulty(Difficulty difficulty) {
    _difficulty = difficulty;
    notifyListeners();
  }

  void setRecipeImage(File? image) {
    _recipeImage = image;
    notifyListeners();
  }

  void addRecipeImage(File image) {
    _recipeImages.add(image);
    notifyListeners();
  }

  void removeRecipeImage(int index) {
    if (index >= 0 && index < _recipeImages.length) {
      _recipeImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearRecipeImages() {
    _recipeImages.clear();
    notifyListeners();
  }

  void setRecipeVideo(File? video) {
    _recipeVideo = video;
    notifyListeners();
  }

  // Ingredient management
  void addIngredient() {
    _ingredients.insert(
      0,
      IngredientModel(
        name: '',
        amount: 0,
        unit: 'gr',
        calories: 0,
      ),
    );
    notifyListeners();
  }

  void removeIngredient(int index) {
    if (index >= 0 && index < _ingredients.length) {
      // Cancel any pending debounce timer for this ingredient
      _debounceTimers[index]?.cancel();
      _debounceTimers.remove(index);
      
      _ingredients.removeAt(index);
      
      // Reassign debounce timers to maintain index mapping
      final tempTimers = <int, Timer>{};
      _debounceTimers.forEach((key, value) {
        if (key > index) {
          tempTimers[key - 1] = value;
        } else if (key < index) {
          tempTimers[key] = value;
        }
      });
      _debounceTimers.clear();
      _debounceTimers.addAll(tempTimers);
      
      notifyListeners();
    }
  }

  void updateIngredientName(int index, String name) {
    if (index >= 0 && index < _ingredients.length) {
      _ingredients[index] = _ingredients[index].copyWith(name: name);
      // Trigger debounced calorie calculation
      _debouncedCalculateIngredientCalories(index);
      notifyListeners();
    }
  }

  void updateIngredientAmount(int index, String amountStr) {
    if (index >= 0 && index < _ingredients.length) {
      final amount = double.tryParse(amountStr) ?? 0.0;
      _ingredients[index] = _ingredients[index].copyWith(amount: amount);
      // Recalculate calories when amount changes with debounce
      _debouncedCalculateIngredientCalories(index);
      notifyListeners();
    }
  }

  void updateIngredientUnit(int index, String unit) {
    if (index >= 0 && index < _ingredients.length) {
      _ingredients[index] = _ingredients[index].copyWith(unit: unit);
      // Recalculate calories when unit changes (affects weight-based calculations)
      _debouncedCalculateIngredientCalories(index);
      notifyListeners();
    }
  }

  /// Debounced calorie calculation to optimize API calls
  /// Cancels previous timer if ingredient is updated multiple times
  void _debouncedCalculateIngredientCalories(int index) {
    _debounceTimers[index]?.cancel();
    
    _debounceTimers[index] = Timer(_debounceDuration, () {
      _calculateIngredientCalories(index);
      _debounceTimers.remove(index);
    });
  }

  /// Calculate calories for a specific ingredient
  ///
  /// TODO: Implement calorie calculation API integration
  /// Currently returns 0 as placeholder
  Future<void> _calculateIngredientCalories(int index) async {
    if (index < 0 || index >= _ingredients.length) return;

    final ingredient = _ingredients[index];

    if (ingredient.name.isEmpty || ingredient.amount <= 0) {
      _ingredients[index] = ingredient.copyWith(calories: 0);
      notifyListeners();
      return;
    }

    // Set loading state
    _ingredients[index] = ingredient.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Placeholder: estimate calories using simple formula
      // TODO: Replace with actual API call
      final estimatedCalories = _estimateCalories(ingredient);
      
      _ingredients[index] =
          _ingredients[index].copyWith(calories: estimatedCalories, isLoading: false);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Kalori hesaplanamadı: ${e.toString()}';
      _ingredients[index] = _ingredients[index].copyWith(isLoading: false);
    }

    notifyListeners();
  }

  /// Simple calorie estimation based on ingredient type
  /// This is a temporary placeholder until proper API integration
  double _estimateCalories(IngredientModel ingredient) {
    // Very rough estimation: ~100 kcal per 100g for most foods
    final gramsAmount = _convertToGrams(ingredient.amount, ingredient.unit);
    return gramsAmount; // 1 kcal per gram (rough estimate)
  }

  /// Convert ingredient amount to grams
  double _convertToGrams(double amount, String unit) {
    switch (unit.toLowerCase()) {
      case 'gr':
        return amount;
      case 'kg':
        return amount * 1000;
      case 'ml':
        return amount; // Approximate for water-based foods
      case 'lt':
        return amount * 1000;
      case 'bardak':
        return amount * 200; // Turkish su bardağı
      case 'y.kaşığı':
        return amount * 15;
      case 'ç.kaşığı':
        return amount * 5;
      case 'adet':
      case 'dilim':
      case 'diş':
      case 'bütün':
        return amount * 50; // Estimate
      default:
        return amount;
    }
  }

  /// Get autocomplete suggestions for ingredient names
  List<String> getIngredientSuggestions([String query = '']) {
    if (query.isEmpty) {
      return _commonIngredients.take(8).toList();
    }
    
    final lowerQuery = query.toLowerCase();
    return _commonIngredients
        .where((ingredient) => ingredient.toLowerCase().startsWith(lowerQuery))
        .toList();
  }

  /// Calculate calories for all ingredients
  Future<void> calculateAllCalories() async {
    _isCalculatingCalories = true;
    notifyListeners();

    try {
      for (int i = 0; i < _ingredients.length; i++) {
        await _calculateIngredientCalories(i);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Kalori hesaplaması başarısız: ${e.toString()}';
    }

    _isCalculatingCalories = false;
    notifyListeners();
  }

  // Validation
  bool validateForm() {
    if (_recipeTitle.isEmpty) {
      _errorMessage = 'Lütfen tarif başlığını giriniz';
      notifyListeners();
      return false;
    }

    if (_ingredients.isEmpty) {
      _errorMessage = 'Lütfen en az bir malzeme ekleyiniz';
      notifyListeners();
      return false;
    }

    if (_instructions.isEmpty) {
      _errorMessage = 'Lütfen hazırlama talimatlarını giriniz';
      notifyListeners();
      return false;
    }

    // Validate all ingredients
    for (final ingredient in _ingredients) {
      if (ingredient.name.isEmpty || ingredient.amount <= 0) {
        _errorMessage =
            'Lütfen tüm malzemelerin adını ve miktarını giriniz';
        notifyListeners();
        return false;
      }
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  // Submit recipe
  Future<bool> submitRecipe() async {
    if (!validateForm()) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      // Generate recipe ID
      final recipeId = DateTime.now().millisecondsSinceEpoch.toString();

      // --- Image upload: prefer Cloud Storage, fall back to local ---
      List<String> savedImagePaths = [];
      if (_recipeImages.isNotEmpty) {
        if (_storageService != null) {
          debugPrint('⬆️  Uploading ${_recipeImages.length} images to Firebase Storage...');
          savedImagePaths = await _storageService!.uploadImages(
            imageFiles: _recipeImages,
            recipeId: recipeId,
          );
          debugPrint('✅ ${savedImagePaths.length} images uploaded to Cloud Storage');
        } else {
          savedImagePaths = await ImageStorageService.saveImages(
              _recipeImages, recipeId);
          debugPrint('💾 ${savedImagePaths.length} images saved locally');
        }
      }

      // --- Video upload: prefer Cloud Storage ---
      String? savedVideoPath = _recipeVideo?.path;
      if (_recipeVideo != null && _storageService != null) {
        debugPrint('⬆️  Uploading video to Firebase Storage...');
        savedVideoPath = await _storageService!.uploadVideo(
          videoFile: _recipeVideo!,
          recipeId: recipeId,
        );
        debugPrint('✅ Video uploaded to Cloud Storage: $savedVideoPath');
      }

      // Create UserRecipeModel
      final recipe = UserRecipeModel(
        id: recipeId,
        title: _recipeTitle,
        instructions: _instructions,
        cookingTime: _cookingTime,
        difficulty: _difficulty,
        videoPath: savedVideoPath,
        imagePaths: savedImagePaths,
        ingredients: _ingredients,
        totalCalories: totalCalories,
      );

      // Save to repository (Firestore or local)
      final success = await _repository.saveRecipe(recipe);
      if (success) {
        debugPrint('=== YENİ TARİF KAYDEDİLDİ ===');
        debugPrint('ID: ${recipe.id}');
        debugPrint('Başlık: ${recipe.title}');
        debugPrint('Toplam Kalori: ${recipe.totalCalories} kcal');
        debugPrint('Malzeme Sayısı: ${recipe.ingredients.length}');
        debugPrint('========================');
      } else {
        debugPrint('⚠️ Repository kaydetme başarısız');
        _printRecipeDetails(recipe);
      }

      // Success - reset form
      _resetForm();
      _errorMessage = null;

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Tarif kaydedilemedi: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Print recipe details to console
  void _printRecipeDetails(UserRecipeModel recipe) {
    debugPrint('=== YENİ TARİF EKLENDİ ===');
    debugPrint('ID: ${recipe.id}');
    debugPrint('Başlık: ${recipe.title}');
    debugPrint('Pişirme Süresi: ${recipe.cookingTime} dakika');
    debugPrint('Zorluk: ${recipe.difficulty}');
    debugPrint('Toplam Kalori: ${recipe.totalCalories} kcal');
    debugPrint('Malzemeler:');
    for (var ing in recipe.ingredients) {
      debugPrint('  - ${ing.name}: ${ing.amount} ${ing.unit} (${ing.calories} kcal)');
    }
    debugPrint('Görsel: ${recipe.imagePath != null ? 'Var' : 'Yok'}');
    debugPrint('Video: ${recipe.videoPath != null ? 'Var' : 'Yok'}');
    debugPrint('========================');
  }

  // Reset form
  void _resetForm() {
    _recipeTitle = '';
    _instructions = '';
    _cookingTime = 30;
    _difficulty = Difficulty.easy;
    _recipeImage = null;
    _recipeVideo = null;
    _recipeImages.clear();
    _ingredients.clear();
    _errorMessage = null;
    
    // Cancel all pending debounce timers
    _debounceTimers.forEach((_, timer) => timer.cancel());
    _debounceTimers.clear();
  }

  void reset() {
    _resetForm();
    notifyListeners();
  }

  // Get recipe summary as JSON
  Map<String, dynamic> getRecipeSummary() {
    return {
      'title': _recipeTitle,
      'instructions': _instructions,
      'cookingTime': _cookingTime,
      'difficulty': _difficulty,
      'totalCalories': totalCalories,
      'ingredients': _ingredients.map((i) => i.toJson()).toList(),
      'hasImage': _recipeImage != null,
      'hasVideo': _recipeVideo != null,
    };
  }

  @override
  void dispose() {
    // Cancel all pending timers when provider is disposed
    _debounceTimers.forEach((_, timer) => timer.cancel());
    _debounceTimers.clear();
    super.dispose();
  }
}
