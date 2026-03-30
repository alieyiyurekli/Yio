import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class IngredientItem extends StatefulWidget {
  final String name;
  final String? amount;
  final bool initialChecked;
  final ValueChanged<bool>? onChanged;

  const IngredientItem({
    super.key,
    required this.name,
    this.amount,
    this.initialChecked = false,
    this.onChanged,
  });

  @override
  State<IngredientItem> createState() => _IngredientItemState();
}

class _IngredientItemState extends State<IngredientItem> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.initialChecked;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
        widget.onChanged?.call(isChecked);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isChecked
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? AppColors.primary : AppColors.border,
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.textWhite,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isChecked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (widget.amount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.amount!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
