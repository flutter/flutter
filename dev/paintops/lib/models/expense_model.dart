import 'package:flutter/material.dart';

class ExpenseModel {
  final String id;
  final String projectId;
  final String projectName;
  final String? supplier;
  final double amount;
  final ExpenseCategory category;
  final String? description;
  final DateTime date;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? receiptImageUrl;

  ExpenseModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.supplier,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.receiptImageUrl,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      projectName: json['project_name'] ?? '',
      supplier: json['supplier'],
      amount: (json['amount'] ?? 0).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == (json['category'] ?? 'materials'),
        orElse: () => ExpenseCategory.materials,
      ),
      description: json['description'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      isApproved: json['is_approved'] ?? false,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.tryParse(json['approved_at']) 
          : null,
      receiptImageUrl: json['receipt_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'supplier': supplier,
      'amount': amount,
      'category': category.name,
      'description': description,
      'date': date.toIso8601String(),
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'receipt_image_url': receiptImageUrl,
    };
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  
  ExpenseModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? supplier,
    double? amount,
    ExpenseCategory? category,
    String? description,
    DateTime? date,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? receiptImageUrl,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      supplier: supplier ?? this.supplier,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
    );
  }
}

enum ExpenseCategory {
  materials('Materials', 0xFF4CAF50, Icons.build),
  equipment('Equipment', 0xFF2196F3, Icons.construction),
  transportation('Transportation', 0xFFFF9800, Icons.local_shipping),
  subcontractor('Subcontractor', 0xFF9C27B0, Icons.people),
  permits('Permits', 0xFFF44336, Icons.description),
  other('Other', 0xFF607D8B, Icons.more_horiz);

  const ExpenseCategory(this.displayName, this.colorValue, this.icon);
  
  final String displayName;
  final int colorValue;
  final IconData icon;
  
  Color get color => Color(colorValue);
}
