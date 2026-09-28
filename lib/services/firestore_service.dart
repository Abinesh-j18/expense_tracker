import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';

class FirestoreService {
  final FirebaseFirestore? _firestore;

  // Stream controllers mapped per userId for isolated streams
  final Map<String, StreamController<List<ExpenseModel>>> _userControllers = {};

  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore;

  StreamController<List<ExpenseModel>> _getController(String userId) {
    return _userControllers.putIfAbsent(
      userId,
      () => StreamController<List<ExpenseModel>>.broadcast(),
    );
  }

  // Load user expenses from local storage
  Future<List<ExpenseModel>> _loadUserExpenses(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_expenses_$userId';
      final jsonString = prefs.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonString);
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ExpenseModel.fromMap(map, map['id'] as String? ?? '');
        }).toList();
      }

      // Pre-seed sample expenses ONLY for the demo account or guest session
      if (userId == 'demo_user_id' || userId == 'guest_user') {
        final initial = _createDemoExpenses(userId);
        await _saveUserExpenses(userId, initial);
        return initial;
      }

      // Brand new registered users start with an empty list
      return [];
    } catch (e) {
      debugPrint('Error loading user expenses: $e');
      return [];
    }
  }

  Future<void> _saveUserExpenses(String userId, List<ExpenseModel> expenses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_expenses_$userId';
      final list = expenses.map((e) {
        final map = e.toMap();
        map['id'] = e.id;
        if (map['date'] is Timestamp) {
          map['date'] = (map['date'] as Timestamp).toDate().toIso8601String();
        } else if (map['date'] is DateTime) {
          map['date'] = (map['date'] as DateTime).toIso8601String();
        }
        if (map['createdAt'] is Timestamp) {
          map['createdAt'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
        } else if (map['createdAt'] is DateTime) {
          map['createdAt'] = (map['createdAt'] as DateTime).toIso8601String();
        }
        return map;
      }).toList();
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving user expenses: $e');
    }
  }

  List<ExpenseModel> _createDemoExpenses(String userId) {
    final now = DateTime.now();
    return [
      ExpenseModel(
        id: 'demo-1',
        title: 'Grocery Supermarket',
        amount: 84.50,
        categoryId: 'groceries',
        date: now.subtract(const Duration(hours: 3)),
        note: 'Vegetables, milk, fruits, and bread',
        userId: userId,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      ExpenseModel(
        id: 'demo-2',
        title: 'Starbucks Coffee',
        amount: 6.75,
        categoryId: 'food',
        date: now.subtract(const Duration(days: 1)),
        note: 'Caramel Macchiato with team',
        userId: userId,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ExpenseModel(
        id: 'demo-3',
        title: 'Electricity & Water Bill',
        amount: 120.00,
        categoryId: 'bills',
        date: now.subtract(const Duration(days: 2)),
        note: 'Monthly utility bill paid online',
        userId: userId,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ExpenseModel(
        id: 'demo-4',
        title: 'Uber Ride to Office',
        amount: 18.25,
        categoryId: 'transport',
        date: now.subtract(const Duration(days: 3)),
        note: 'Morning commute',
        userId: userId,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ExpenseModel(
        id: 'demo-5',
        title: 'Flutter Course on Udemy',
        amount: 14.99,
        categoryId: 'education',
        date: now.subtract(const Duration(days: 5)),
        note: 'Advanced Flutter & Firebase course',
        userId: userId,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  // Get user-scoped expenses collection reference
  CollectionReference<Map<String, dynamic>> _userExpensesRef(String userId) {
    return _firestore!.collection('users').doc(userId).collection('expenses');
  }

  // Real-time Stream of expenses for the given user
  Stream<List<ExpenseModel>> getExpensesStream(String userId) async* {
    if (_firestore == null) {
      final initial = await _loadUserExpenses(userId);
      yield initial;
      yield* _getController(userId).stream;
      return;
    }

    try {
      yield* _userExpensesRef(userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ExpenseModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      debugPrint('FirestoreService.getExpensesStream error: $e');
      final local = await _loadUserExpenses(userId);
      yield local;
      yield* _getController(userId).stream;
    }
  }

  // Add new expense
  Future<String> addExpense(ExpenseModel expense) async {
    final generatedId = DateTime.now().millisecondsSinceEpoch.toString();
    final expenseWithId = expense.id.isEmpty ? expense.copyWith(id: generatedId) : expense;

    if (_firestore == null) {
      final list = await _loadUserExpenses(expense.userId);
      list.insert(0, expenseWithId);
      await _saveUserExpenses(expense.userId, list);
      _getController(expense.userId).add(List.from(list));
      return expenseWithId.id;
    }

    try {
      final docRef = await _userExpensesRef(expense.userId).add(expense.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('FirestoreService.addExpense error: $e');
      final list = await _loadUserExpenses(expense.userId);
      list.insert(0, expenseWithId);
      await _saveUserExpenses(expense.userId, list);
      _getController(expense.userId).add(List.from(list));
      return expenseWithId.id;
    }
  }

  // Edit / Update existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    if (_firestore == null) {
      final list = await _loadUserExpenses(expense.userId);
      final index = list.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        list[index] = expense;
        await _saveUserExpenses(expense.userId, list);
        _getController(expense.userId).add(List.from(list));
      }
      return;
    }

    try {
      await _userExpensesRef(expense.userId)
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      debugPrint('FirestoreService.updateExpense error: $e');
      final list = await _loadUserExpenses(expense.userId);
      final index = list.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        list[index] = expense;
        await _saveUserExpenses(expense.userId, list);
        _getController(expense.userId).add(List.from(list));
      }
    }
  }

  // Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    if (_firestore == null) {
      final list = await _loadUserExpenses(userId);
      list.removeWhere((e) => e.id == expenseId);
      await _saveUserExpenses(userId, list);
      _getController(userId).add(List.from(list));
      return;
    }

    try {
      await _userExpensesRef(userId).doc(expenseId).delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteExpense error: $e');
      final list = await _loadUserExpenses(userId);
      list.removeWhere((e) => e.id == expenseId);
      await _saveUserExpenses(userId, list);
      _getController(userId).add(List.from(list));
    }
  }

  void dispose() {
    for (final controller in _userControllers.values) {
      controller.close();
    }
    _userControllers.clear();
  }
}
