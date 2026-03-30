/// Recipe categories, cuisines, and tags constants
class RecipeConstants {
  // Categories
  static const List<String> categories = [
    'Ana Yemek',
    'Kahvaltı',
    'Tatlı',
    'İçecek',
    'Atıştırmalık',
    'Sağlıklı',
  ];

  // Cuisines
  static const List<String> cuisines = [
    'Türk',
    'İtalyan',
    'Çin',
    'Japon',
    'Meksika',
    'Hint',
    'Akdeniz',
  ];

  // Tags
  static const List<String> tags = [
    'Vegan',
    'Vejetaryen',
    'Glutensiz',
    'Keto',
    'Yüksek Protein',
    'Düşük Karbonhidrat',
    'Hızlı',
    'Kolay',
  ];

  // Category colors for badges
  static const Map<String, int> categoryColors = {
    'Ana Yemek': 0xFFFF7A45,
    'Kahvaltı': 0xFFFFC107,
    'Tatlı': 0xFFE91E63,
    'İçecek': 0xFF2196F3,
    'Atıştırmalık': 0xFF4CAF50,
    'Sağlıklı': 0xFF8BC34A,
  };
}
