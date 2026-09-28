import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  StreamSubscription<List<ExpenseModel>>? _expensesSubscription;

  List<ExpenseModel> _allExpenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedCategoryId; // null means 'All'
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  ExpenseProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  // Getters
  List<ExpenseModel> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  // Subscribe to real-time expenses for current user
  void subscribeToExpenses(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _expensesSubscription?.cancel();
    _expensesSubscription = _firestoreService.getExpensesStream(userId).listen(
      (expenses) {
        _allExpenses = expenses;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Failed to load expenses: $error';
        notifyListeners();
      },
    );
  }

  // Filtered expenses based on selected month, category, date range, and search query
  List<ExpenseModel> get filteredExpenses {
    return _allExpenses.where((expense) {
      // 1. Month / Date Range Filter
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (expense.date.isBefore(start) || expense.date.isAfter(end)) {
          return false;
        }
      } else {
        // Month filter
        if (expense.date.year != _selectedMonth.year ||
            expense.date.month != _selectedMonth.month) {
          return false;
        }
      }

      // 2. Category Filter
      if (_selectedCategoryId != null &&
          expense.categoryId.toLowerCase() != _selectedCategoryId!.toLowerCase()) {
        return false;
      }

      // 3. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = expense.title.toLowerCase().contains(query);
        final matchesNote = expense.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesNote) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Total expenses for the currently selected month
  double get totalForSelectedMonth {
    return _allExpenses
        .where((e) =>
            e.date.year == _selectedMonth.year &&
            e.date.month == _selectedMonth.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Total for the currently filtered set
  double get totalFilteredAmount {
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Map of Category ID -> Total Amount for the selected month
  Map<String, double> get categoryBreakdownForSelectedMonth {
    final Map<String, double> map = {};
    final monthExpenses = _allExpenses.where((e) =>
        e.date.year == _selectedMonth.year &&
        e.date.month == _selectedMonth.month);

    for (final exp in monthExpenses) {
      map[exp.categoryId] = (map[exp.categoryId] ?? 0.0) + exp.amount;
    }
    return map;
  }

  // Navigation: Next & Previous Month
  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _selectedDateRange = null; // Reset custom date range
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _selectedDateRange = null; // Reset custom date range
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    _selectedDateRange = null;
    notifyListeners();
  }

  // Filter setters
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _selectedDateRange = null;
    notifyListeners();
  }

  // CRUD Operations
  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      await _firestoreService.addExpense(expense);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    try {
      await _firestoreService.updateExpense(expense);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String userId, String expenseId) async {
    try {
      await _firestoreService.deleteExpense(userId, expenseId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
