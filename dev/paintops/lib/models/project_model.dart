import 'package:flutter/material.dart';

enum ProjectStatus {
  planning,
  inProgress,
  onHold,
  completed,
  cancelled,
}

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return const Color(0xFF9C27B0);
      case ProjectStatus.inProgress:
        return const Color(0xFF2196F3);
      case ProjectStatus.onHold:
        return const Color(0xFFFF9800);
      case ProjectStatus.completed:
        return const Color(0xFF4CAF50);
      case ProjectStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String? clientName;
  final String? clientEmail;
  final ProjectStatus status;
  final double budgetAmount;
  final double actualCosts;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;
  final String? imageUrl;

  ProjectModel({
    required this.id,
    required this.name,
    this.clientName,
    this.clientEmail,
    required this.status,
    required this.budgetAmount,
    required this.actualCosts,
    required this.startDate,
    this.endDate,
    this.description,
    this.imageUrl,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      clientName: json['client_name'],
      clientEmail: json['client_email'],
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'planning'),
        orElse: () => ProjectStatus.planning,
      ),
      budgetAmount: (json['budget_amount'] ?? 0).toDouble(),
      actualCosts: (json['actual_costs'] ?? 0).toDouble(),
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'client_name': clientName,
      'client_email': clientEmail,
      'status': status.name,
      'budget_amount': budgetAmount,
      'actual_costs': actualCosts,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'description': description,
      'image_url': imageUrl,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? clientName,
    String? clientEmail,
    ProjectStatus? status,
    double? budgetAmount,
    double? actualCosts,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? imageUrl,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      status: status ?? this.status,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      actualCosts: actualCosts ?? this.actualCosts,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Computed properties
  double get profitMargin {
    if (budgetAmount == 0) return 0;
    return ((budgetAmount - actualCosts) / budgetAmount) * 100;
  }

  bool get isOnBudget => actualCosts <= budgetAmount;

  bool get isOverdue {
    if (endDate == null || status == ProjectStatus.completed) return false;
    return DateTime.now().isAfter(endDate!);
  }

  Duration? get duration {
    if (endDate == null) return null;
    return endDate!.difference(startDate);
  }

  int get daysRemaining {
    if (endDate == null || status == ProjectStatus.completed) return 0;
    final remaining = endDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  double get progressPercentage {
    if (budgetAmount == 0) return 0;
    final progress = (actualCosts / budgetAmount) * 100;
    return progress > 100 ? 100 : progress;
  }
}
