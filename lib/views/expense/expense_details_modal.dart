import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/confirm_dialog.dart';
import 'add_edit_expense_screen.dart';

class ExpenseDetailsModal extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailsModal({super.key, required this.expense});

  static void show(BuildContext context, ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ExpenseDetailsModal(expense: expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getById(expense.categoryId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Category Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: category.color, size: 32),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            expense.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Amount
          Text(
            CurrencyFormatter.format(expense.amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 20),

          // Info Tiles
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildInfoRow('Category', category.name, isDark),
                const Divider(height: 16),
                _buildInfoRow('Date', DateFormatter.formatFull(expense.date), isDark),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildInfoRow('Note', expense.note!, isDark),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Edit and Delete
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Delete Expense',
                      content: 'Are you sure you want to delete this expense?',
                    );
                    if (confirm == true && context.mounted) {
                      final auth = context.read<AuthProvider>();
                      final expenseProv = context.read<ExpenseProvider>();
                      await expenseProv.deleteExpense(auth.userId, expense.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close modal
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditExpenseScreen(expense: expense),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: const Text('Edit', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
