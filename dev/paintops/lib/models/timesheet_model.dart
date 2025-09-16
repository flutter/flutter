import 'package:intl/intl.dart';

class TimesheetModel {
  final String id;
  final String projectId;
  final String projectName;
  final String workerId;
  final String workerName;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  TimesheetModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.workerId,
    required this.workerName,
    required this.startTime,
    required this.endTime,
    this.description,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  });

  factory TimesheetModel.fromJson(Map<String, dynamic> json) {
    return TimesheetModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      projectName: json['project_name'] ?? '',
      workerId: json['worker_id'] ?? '',
      workerName: json['worker_name'] ?? '',
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now(),
      description: json['description'],
      isApproved: json['is_approved'] ?? false,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.tryParse(json['approved_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'worker_id': workerId,
      'worker_name': workerName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'description': description,
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  Duration get duration => endTime.difference(startTime);
  double get hoursWorked => duration.inMinutes / 60.0;
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get formattedDate => DateFormat('MMM d, yyyy').format(startTime);
  String get formattedTimeRange {
    return '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
  }

  TimesheetModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? workerId,
    String? workerName,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return TimesheetModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
