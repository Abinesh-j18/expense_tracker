import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';

class FirestoreService {
  final FirebaseFirestore? _firestore;

  // Local fallback cache for offline or demo testing
  final List<ExpenseModel> _demoExpenses = [];
  final StreamController<List<ExpenseModel>> _demoStreamController =
      StreamController<List<ExpenseModel>>.broadcast();

  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore {
    if (_firestore == null) {
      _initSampleDemoData();
    }
  }

  void _initSampleDemoData() {
    final now = DateTime.now();
    _demoExpenses.addAll([
      ExpenseModel(
        id: 'demo-1',
        title: 'Grocery Supermarket',
        amount: 84.50,
        categoryId: 'groceries',
        date: now.subtract(const Duration(hours: 3)),
        note: 'Vegetables, milk, fruits, and bread',
        userId: 'demo_user_id',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      ExpenseModel(
        id: 'demo-2',
        title: 'Starbucks Coffee',
        amount: 6.75,
        categoryId: 'food',
        date: now.subtract(const Duration(days: 1)),
        note: 'Caramel Macchiato with team',
        userId: 'demo_user_id',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ExpenseModel(
        id: 'demo-3',
        title: 'Electricity & Water Bill',
        amount: 120.00,
        categoryId: 'bills',
        date: now.subtract(const Duration(days: 2)),
        note: 'Monthly utility bill paid online',
        userId: 'demo_user_id',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ExpenseModel(
        id: 'demo-4',
        title: 'Uber Ride to Office',
        amount: 18.25,
        categoryId: 'transport',
        date: now.subtract(const Duration(days: 3)),
        note: 'Morning commute',
        userId: 'demo_user_id',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ExpenseModel(
        id: 'demo-5',
        title: 'Flutter Course on Udemy',
        amount: 14.99,
        categoryId: 'education',
        date: now.subtract(const Duration(days: 5)),
        note: 'Advanced Flutter & Firebase course',
        userId: 'demo_user_id',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
    _demoStreamController.add(List.from(_demoExpenses));
  }

  // Get user-scoped expenses collection reference
  CollectionReference<Map<String, dynamic>> _userExpensesRef(String userId) {
    return _firestore!.collection('users').doc(userId).collection('expenses');
  }

  // Real-time Stream of expenses for the given user
  Stream<List<ExpenseModel>> getExpensesStream(String userId) {
    if (_firestore == null) {
      return _demoStreamController.stream;
    }

    try {
      return _userExpensesRef(userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ExpenseModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      debugPrint('FirestoreService.getExpensesStream error: $e');
      rethrow;
    }
  }

  // Add new expense
  Future<String> addExpense(ExpenseModel expense) async {
    if (_firestore == null) {
      final newExpense = expense.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _demoExpenses.insert(0, newExpense);
      _demoStreamController.add(List.from(_demoExpenses));
      return newExpense.id;
    }

    try {
      final docRef = await _userExpensesRef(expense.userId).add(expense.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('FirestoreService.addExpense error: $e');
      rethrow;
    }
  }

  // Edit / Update existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    if (_firestore == null) {
      final index = _demoExpenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _demoExpenses[index] = expense;
        _demoStreamController.add(List.from(_demoExpenses));
      }
      return;
    }

    try {
      await _userExpensesRef(expense.userId)
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      debugPrint('FirestoreService.updateExpense error: $e');
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    if (_firestore == null) {
      _demoExpenses.removeWhere((e) => e.id == expenseId);
      _demoStreamController.add(List.from(_demoExpenses));
      return;
    }

    try {
      await _userExpensesRef(userId).doc(expenseId).delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteExpense error: $e');
      rethrow;
    }
  }

  void dispose() {
    _demoStreamController.close();
  }
}
