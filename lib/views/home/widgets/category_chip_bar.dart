import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_categories.dart';
import '../../../providers/expense_provider.dart';

class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final selectedCategoryId = expenseProvider.selectedCategoryId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppCategories.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? selectedCategoryId == null
              : selectedCategoryId == AppCategories.categories[index - 1].id;

          final label = isAll ? 'All' : AppCategories.categories[index - 1].name;
          final icon = isAll ? Icons.grid_view_rounded : AppCategories.categories[index - 1].icon;
          final iconColor = isAll ? AppColors.primary : AppCategories.categories[index - 1].color;

          return FilterChip(
            selected: isSelected,
            label: Text(label),
            avatar: Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : iconColor,
            ),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            onSelected: (_) {
              if (isAll) {
                expenseProvider.setSelectedCategory(null);
              } else {
                expenseProvider.setSelectedCategory(
                  isSelected ? null : AppCategories.categories[index - 1].id,
                );
              }
            },
          );
        },
      ),
    );
  }
}
