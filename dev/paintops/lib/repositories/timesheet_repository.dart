import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timesheet_model.dart';

class TimesheetRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TimesheetModel>> getTimesheets({String? projectId, String? workerId}) async {
    try {
      var query = _supabase
          .from('timesheets')
          .select('''
            *,
            projects (
              name
            ),
            profiles (
              full_name
            )
          ''');

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      if (workerId != null) {
        query = query.eq('worker_id', workerId);
      }

      final response = await query.order('start_time', ascending: false);

      return (response as List).map((timesheet) {
        return TimesheetModel(
          id: timesheet['id'] ?? '',
          projectId: timesheet['project_id'] ?? '',
          projectName: timesheet['projects']?['name'] ?? 'Unknown Project',
          workerId: timesheet['worker_id'] ?? '',
          workerName: timesheet['profiles']?['full_name'] ?? 'Unknown Worker',
          startTime: DateTime.tryParse(timesheet['start_time'] ?? '') ?? DateTime.now(),
          endTime: DateTime.tryParse(timesheet['end_time'] ?? '') ?? DateTime.now(),
          description: timesheet['description'] ?? '',
          isApproved: timesheet['is_approved'] ?? false,
          approvedBy: timesheet['approved_by'],
          approvedAt: timesheet['approved_at'] != null 
              ? DateTime.tryParse(timesheet['approved_at']) 
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error loading timesheets: $e');
      throw Exception('Failed to load timesheets: $e');
    }
  }

  Future<List<TimesheetModel>> getTimesheetsForDateRange(DateTime startDate, DateTime endDate, {String? workerId}) async {
    try {
      var query = _supabase
          .from('timesheets')
          .select('''
            *,
            projects (
              name
            ),
            profiles (
              full_name
            )
          ''')
          .gte('start_time', startDate.toIso8601String())
          .lte('start_time', endDate.toIso8601String());

      if (workerId != null) {
        query = query.eq('worker_id', workerId);
      }

      final response = await query.order('start_time', ascending: true);

      return (response as List).map((timesheet) {
        return TimesheetModel(
          id: timesheet['id'] ?? '',
          projectId: timesheet['project_id'] ?? '',
          projectName: timesheet['projects']?['name'] ?? 'Unknown Project',
          workerId: timesheet['worker_id'] ?? '',
          workerName: timesheet['profiles']?['full_name'] ?? 'Unknown Worker',
          startTime: DateTime.tryParse(timesheet['start_time'] ?? '') ?? DateTime.now(),
          endTime: DateTime.tryParse(timesheet['end_time'] ?? '') ?? DateTime.now(),
          description: timesheet['description'] ?? '',
          isApproved: timesheet['is_approved'] ?? false,
          approvedBy: timesheet['approved_by'],
          approvedAt: timesheet['approved_at'] != null 
              ? DateTime.tryParse(timesheet['approved_at']) 
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error loading timesheets for date range: $e');
      throw Exception('Failed to load timesheets for date range: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTimesheetsGroupedByDate(DateTime startDate, DateTime endDate, {String? workerId}) async {
    try {
      final timesheets = await getTimesheetsForDateRange(startDate, endDate, workerId: workerId);
      
      final Map<String, List<TimesheetModel>> groupedTimesheets = {};
      
      for (final timesheet in timesheets) {
        final dateKey = timesheet.startTime.toIso8601String().split('T')[0];
        if (!groupedTimesheets.containsKey(dateKey)) {
          groupedTimesheets[dateKey] = [];
        }
        groupedTimesheets[dateKey]!.add(timesheet);
      }
      
      return groupedTimesheets.entries.map((entry) => {
        'date': entry.key,
        'timesheets': entry.value,
        'totalHours': entry.value.fold(0.0, (sum, ts) => sum + ts.duration.inMinutes / 60.0),
      }).toList();
    } catch (e) {
      print('Error loading grouped timesheets: $e');
      return [];
    }
  }

  Future<bool> submitTimesheet(TimesheetModel timesheet) async {
    try {
      final data = {
        'project_id': timesheet.projectId,
        'worker_id': timesheet.workerId,
        'start_time': timesheet.startTime.toIso8601String(),
        'end_time': timesheet.endTime.toIso8601String(),
        'description': timesheet.description,
        'is_approved': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('timesheets').insert(data);
      return true;
    } catch (e) {
      print('Error submitting timesheet: $e');
      return false;
    }
  }

  Future<bool> updateTimesheet(TimesheetModel timesheet) async {
    try {
      final data = {
        'project_id': timesheet.projectId,
        'worker_id': timesheet.workerId,
        'start_time': timesheet.startTime.toIso8601String(),
        'end_time': timesheet.endTime.toIso8601String(),
        'description': timesheet.description,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('timesheets')
          .update(data)
          .eq('id', timesheet.id);
      
      return true;
    } catch (e) {
      print('Error updating timesheet: $e');
      return false;
    }
  }

  Future<bool> approveTimesheet(String timesheetId, String approvedBy) async {
    try {
      await _supabase
          .from('timesheets')
          .update({
            'is_approved': true,
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', timesheetId);
      
      return true;
    } catch (e) {
      print('Error approving timesheet: $e');
      return false;
    }
  }

  Future<bool> deleteTimesheet(String timesheetId) async {
    try {
      await _supabase
          .from('timesheets')
          .delete()
          .eq('id', timesheetId);
      
      return true;
    } catch (e) {
      print('Error deleting timesheet: $e');
      return false;
    }
  }

  Future<Map<String, int>> getTimesheetMetrics({String? workerId}) async {
    try {
      final timesheets = await getTimesheets(workerId: workerId);
      
      final pendingApprovals = timesheets.where((t) => !t.isApproved).length;
      final approvedTimesheets = timesheets.where((t) => t.isApproved).length;
      final totalHours = timesheets.fold(0, (sum, timesheet) => sum + timesheet.duration.inHours);
      final thisWeekTimesheets = timesheets.where((t) => 
          t.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).length;
      final thisMonthTimesheets = timesheets.where((t) => 
          t.startTime.isAfter(DateTime.now().subtract(const Duration(days: 30)))
      ).length;
      
      return {
        'totalTimesheets': timesheets.length,
        'pendingTimesheetApprovals': pendingApprovals,
        'approvedTimesheets': approvedTimesheets,
        'totalHours': totalHours,
        'thisWeekTimesheets': thisWeekTimesheets,
        'thisMonthTimesheets': thisMonthTimesheets,
      };
    } catch (e) {
      print('Error loading timesheet metrics: $e');
      return {
        'totalTimesheets': 0,
        'pendingTimesheetApprovals': 0,
        'approvedTimesheets': 0,
        'totalHours': 0,
        'thisWeekTimesheets': 0,
        'thisMonthTimesheets': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerProductivity(DateTime startDate, DateTime endDate) async {
    try {
      final timesheets = await getTimesheetsForDateRange(startDate, endDate);
      
      final Map<String, Map<String, dynamic>> workerStats = {};
      
      for (final timesheet in timesheets) {
        if (!workerStats.containsKey(timesheet.workerId)) {
          workerStats[timesheet.workerId] = {
            'workerId': timesheet.workerId,
            'workerName': timesheet.workerName,
            'totalHours': 0.0,
            'totalTimesheets': 0,
            'approvedHours': 0.0,
            'pendingHours': 0.0,
          };
        }
        
        final hours = timesheet.duration.inMinutes / 60.0;
        workerStats[timesheet.workerId]!['totalHours'] += hours;
        workerStats[timesheet.workerId]!['totalTimesheets']++;
        
        if (timesheet.isApproved) {
          workerStats[timesheet.workerId]!['approvedHours'] += hours;
        } else {
          workerStats[timesheet.workerId]!['pendingHours'] += hours;
        }
      }
      
      return workerStats.values.toList();
    } catch (e) {
      print('Error loading worker productivity: $e');
      return [];
    }
  }
}
