import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;
  final String userId;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note ?? '',
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return ExpenseModel(
      id: documentId,
      title: map['title'] as String? ?? 'Untitled',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] as String? ?? 'other',
      date: parseDate(map['date']),
      note: (map['note'] as String?)?.isNotEmpty == true ? map['note'] as String : null,
      userId: map['userId'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    String? userId,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
