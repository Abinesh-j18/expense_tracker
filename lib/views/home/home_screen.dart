import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_indicator.dart';
import '../analytics/analytics_screen.dart';
import '../expense/add_edit_expense_screen.dart';
import '../expense/expense_details_modal.dart';
import '../settings/settings_screen.dart';
import 'widgets/category_chip_bar.dart';
import 'widgets/expense_list_item.dart';
import 'widgets/monthly_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<ExpenseProvider>().subscribeToExpenses(authProvider.userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: expenseProvider.selectedDateRange,
    );
    if (picked != null) {
      expenseProvider.setDateRange(picked);
    }
  }

  Widget _buildExpensesTab() {
    final expenseProvider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final filteredExpenses = expenseProvider.filteredExpenses;

    if (expenseProvider.isLoading) {
      return const LoadingIndicator(message: 'Loading your expenses...');
    }

    if (expenseProvider.errorMessage != null && expenseProvider.allExpenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                expenseProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  expenseProvider.subscribeToExpenses(authProvider.userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        expenseProvider.subscribeToExpenses(authProvider.userId);
      },
      child: CustomScrollView(
        slivers: [
          // Monthly Summary Banner
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: MonthlySummaryCard(),
            ),
          ),

          // Horizontal Category Filter Chips
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CategoryChipBar(),
            ),
          ),

          // Active Filter Indication Banner (if date range is selected)
          if (expenseProvider.selectedDateRange != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'Custom Date Filter Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => expenseProvider.setDateRange(null),
                            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // History Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (expenseProvider.selectedCategoryId != null ||
                      expenseProvider.searchQuery.isNotEmpty ||
                      expenseProvider.selectedDateRange != null) ...[
                    TextButton(
                      onPressed: () {
                        expenseProvider.clearFilters();
                        _searchController.clear();
                        setState(() => _isSearching = false);
                      },
                      child: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // List of Expenses or Empty State
          if (filteredExpenses.isEmpty) ...[
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                title: expenseProvider.searchQuery.isNotEmpty
                    ? 'No matching expenses'
                    : 'No expenses for this period',
                description: expenseProvider.searchQuery.isNotEmpty
                    ? 'Try searching with another keyword.'
                    : 'Tap the button below to add your first expense.',
                actionText: 'Add Expense',
                onActionPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditExpenseScreen(),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = filteredExpenses[index];
                  return ExpenseListItem(
                    expense: expense,
                    onTap: () => ExpenseDetailsModal.show(context, expense),
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditExpenseScreen(expense: expense),
                        ),
                      );
                    },
                    onDelete: () async {
                      await expenseProvider.deleteExpense(
                        authProvider.userId,
                        expense.id,
                      );
                    },
                  );
                },
                childCount: filteredExpenses.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80), // Padding for FAB
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search expenses by title or note...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (query) => expenseProvider.setSearchQuery(query),
              )
            : const Text(
                'Expense Tracker',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _isSearching ? 'Close Search' : 'Search Expenses',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  expenseProvider.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Filter by Date Range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildExpensesTab(),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditExpenseScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() => _currentTabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
