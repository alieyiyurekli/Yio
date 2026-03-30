import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ingredient_model.dart';
import '../core/constants/colors.dart';

/// Basit ve kompakt malzeme input widget
/// 
/// Format: [Ürün Adı] [Miktar] [Birim] [Kalori] [Sil]
class IngredientInputRow extends StatefulWidget {
  final IngredientModel ingredient;
  final Function(String) onNameChanged;
  final Function(String) onAmountChanged;
  final Function(String) onUnitChanged;
  final VoidCallback onRemove;
  final bool showRemoveButton;

  const IngredientInputRow({
    super.key,
    required this.ingredient,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onUnitChanged,
    required this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  State<IngredientInputRow> createState() => _IngredientInputRowState();
}

class _IngredientInputRowState extends State<IngredientInputRow> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    _amountController = TextEditingController(
      text: widget.ingredient.amount > 0 ? widget.ingredient.amount.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.shadowLight, width: 0.5),
        ),
      child: Column(
        children: [
          // İlk satır: Ürün adı
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Ürün',
              hintText: 'Örn: Tavuk',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: widget.onNameChanged,
          ),
          
          const SizedBox(height: 6),
          
          // İkinci satır: Miktar + Birim + Kalori + Sil
          Row(
            children: [
              // Miktar input
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Miktar',
                    hintText: '0',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: widget.onAmountChanged,
                ),
              ),
              
              const SizedBox(width: 3),
              
              // Birim dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.ingredient.unit,
                  decoration: InputDecoration(
                    labelText: 'Birim',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    fillColor: AppColors.cardBackground,
                    filled: true,
                  ),
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  items: IngredientModel.allUnits.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onUnitChanged(value);
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 3),
              
              // Kalori gösterimi
              if (widget.ingredient.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (widget.ingredient.calories > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 12, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.ingredient.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(width: 50),
              
              const SizedBox(width: 3),
              
              // Sil butonu
              if (widget.showRemoveButton)
                InkWell(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
