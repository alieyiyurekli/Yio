/// Model for representing a recipe ingredient with nutritional information
class IngredientModel {
  final String id;
  String name;
  double amount;
  String unit;
  double calories;
  bool isLoading;

  IngredientModel({
    String? id,
    required this.name,
    required this.amount,
    this.unit = 'gr',
    this.calories = 0.0,
    this.isLoading = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Available units for ingredients
  static const List<String> weightUnits = ['gr', 'kg'];
  static const List<String> volumeUnits = ['ml', 'lt', 'bardak', 'y.kaşığı', 'ç.kaşığı'];
  static const List<String> countUnits = ['adet', 'dilim', 'diş', 'bütün'];
  
  /// All available units
  static const List<String> allUnits = [
    'gr', 'kg',
    'ml', 'lt', 'bardak', 'y.kaşığı', 'ç.kaşığı',
    'adet', 'dilim', 'diş', 'bütün',
  ];

  /// Get display name for unit
  static String getUnitDisplayName(String unit) {
    final displayNames = {
      'gr': 'gram',
      'kg': 'kilogram',
      'oz': 'ons',
      'lb': 'pound',
      'ml': 'mililitre',
      'lt': 'litre',
      'su bardağı': 'su bardağı',
      'yemek kaşığı': 'yemek kaşığı',
      'çay kaşığı': 'çay kaşığı',
      'fl oz': 'sıvı ons',
      'adet': 'adet',
      'dilim': 'dilim',
      'diş': 'diş',
      'bütün': 'bütün',
    };
    return displayNames[unit] ?? unit;
  }

  /// Check if unit is weight-based
  static bool isWeightUnit(String unit) {
    return weightUnits.contains(unit);
  }

  /// Check if unit is volume-based
  static bool isVolumeUnit(String unit) {
    return volumeUnits.contains(unit);
  }

  /// Check if unit is count-based
  static bool isCountUnit(String unit) {
    return countUnits.contains(unit);
  }

  /// Create a copy of the ingredient with updated values
  IngredientModel copyWith({
    String? name,
    double? amount,
    String? unit,
    double? calories,
    bool? isLoading,
  }) {
    return IngredientModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Convert ingredient to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'calories': calories,
    };
  }

  /// Create ingredient from JSON
  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'gr',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get formatted amount string
  String get formattedAmount {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} $unit';
    }
    return '$amount $unit';
  }

  @override
  String toString() {
    return 'IngredientModel(name: $name, amount: $formattedAmount, calories: $calories)';
  }
}
