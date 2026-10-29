import 'package:flutter/material.dart';

enum ProductSafety { aman, waspada, bahaya }

enum HistoryFilter { semua, dikonsumsi, bahaya, waspada, aman }

class ActivityProduct {
  final String brand;
  final String title;
  final String time;
  final String location;
  final ProductSafety safety;
  final IconData icon;
  final int calories;
  final int sugar;
  final int fiber;
  final int protein;
  final int sodium;
  final DateTime date;
  final String? warning;
  bool isConsumed;

  ActivityProduct({
    required this.brand,
    required this.title,
    required this.time,
    required this.location,
    required this.safety,
    required this.icon,
    required this.calories,
    required this.sugar,
    required this.fiber,
    required this.protein,
    required this.sodium,
    required this.date,
    required this.isConsumed,
    this.warning,
  });
}