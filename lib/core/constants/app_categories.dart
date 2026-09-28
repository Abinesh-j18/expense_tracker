import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class AppCategories {
  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF6D00),
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transportation',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF2979FF),
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFE040FB),
    ),
    CategoryModel(
      id: 'bills',
      name: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFF5252),
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFF7C4DFF),
    ),
    CategoryModel(
      id: 'groceries',
      name: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      color: Color(0xFF00BFA5),
    ),
    CategoryModel(
      id: 'health',
      name: 'Health & Fitness',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF4081),
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF00B0FF),
    ),
    CategoryModel(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFFFFAB00),
    ),
    CategoryModel(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF78909C),
    ),
  ];

  static CategoryModel getById(String id) {
    return categories.firstWhere(
      (cat) => cat.id.toLowerCase() == id.toLowerCase(),
      orElse: () => categories.last,
    );
  }
}
