import 'package:flutter/material.dart';

class LeadModel {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String address;
  final String projectType;
  final String timeline;
  final String? message;
  final LeadStatus status;
  final DateTime? contactedAt;
  final String? assignedTo;
  final double? estimatedValue;
  final String? notes;
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.address,
    required this.projectType,
    required this.timeline,
    this.message,
    required this.status,
    this.contactedAt,
    this.assignedTo,
    this.estimatedValue,
    this.notes,
    required this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      projectType: json['project_type'] ?? '',
      timeline: json['timeline'] ?? '',
      message: json['message'],
      status: _parseLeadStatus(json['status']),
      contactedAt: json['contacted_at'] != null ? DateTime.tryParse(json['contacted_at']) : null,
      assignedTo: json['assigned_to'],
      estimatedValue: json['estimated_value'] != null ? (json['estimated_value'] as num).toDouble() : null,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'project_type': projectType,
      'timeline': timeline,
      'message': message,
      'status': status.name,
      'contacted_at': contactedAt?.toIso8601String(),
      'assigned_to': assignedTo,
      'estimated_value': estimatedValue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LeadModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? projectType,
    String? timeline,
    String? message,
    LeadStatus? status,
    DateTime? contactedAt,
    String? assignedTo,
    double? estimatedValue,
    String? notes,
    DateTime? createdAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      projectType: projectType ?? this.projectType,
      timeline: timeline ?? this.timeline,
      message: message ?? this.message,
      status: status ?? this.status,
      contactedAt: contactedAt ?? this.contactedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static LeadStatus _parseLeadStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'newlead':
      case 'new':
        return LeadStatus.newLead;
      case 'contacted':
        return LeadStatus.contacted;
      case 'quoted':
        return LeadStatus.quoted;
      case 'scheduled':
        return LeadStatus.scheduled;
      case 'won':
        return LeadStatus.won;
      case 'lost':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }

  String get formattedEstimatedValue {
    if (estimatedValue != null) {
      return '\$${estimatedValue!.toStringAsFixed(2)}';
    }
    return 'Not estimated';
  }

  String get daysSinceCreated {
    final days = DateTime.now().difference(createdAt).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  bool get isStale => DateTime.now().difference(createdAt).inDays > 7 && status == LeadStatus.newLead;

  String get urgencyLevel {
    switch (timeline.toLowerCase()) {
      case 'asap':
        return 'Urgent';
      case 'within 1 month':
        return 'High';
      case 'within 3 months':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Color get urgencyColor {
    switch (urgencyLevel) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }
}

enum LeadStatus {
  newLead('New Lead', Colors.blue, Icons.fiber_new),
  contacted('Contacted', Colors.orange, Icons.phone),
  quoted('Quoted', Colors.purple, Icons.request_quote),
  scheduled('Scheduled', Colors.indigo, Icons.schedule),
  won('Won', Colors.green, Icons.check_circle),
  lost('Lost', Colors.red, Icons.cancel);

  const LeadStatus(this.displayName, this.color, this.icon);
  
  final String displayName;
  final Color color;
  final IconData icon;
}
