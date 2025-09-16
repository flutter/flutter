import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';

class LeadRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<LeadModel>> getLeads({LeadStatus? status, String? assignedTo}) async {
    try {
      var query = _supabase
          .from('leads')
          .select();

      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (assignedTo != null) {
        query = query.eq('assigned_to', assignedTo);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((lead) {
        return LeadModel.fromJson(lead);
      }).toList();
    } catch (e) {
      print('Error loading leads: $e');
      throw Exception('Failed to load leads: $e');
    }
  }

  Future<LeadModel?> getLead(String id) async {
    try {
      final response = await _supabase
          .from('leads')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return LeadModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error loading lead: $e');
      return null;
    }
  }

  Future<bool> createLead(LeadModel lead) async {
    try {
      final data = lead.toJson();
      data.remove('id'); // Let Supabase generate the ID
      data['created_at'] = DateTime.now().toIso8601String();

      await _supabase.from('leads').insert(data);
      return true;
    } catch (e) {
      print('Error creating lead: $e');
      return false;
    }
  }

  Future<bool> updateLead(LeadModel lead) async {
    try {
      final data = lead.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('leads')
          .update(data)
          .eq('id', lead.id);
      
      return true;
    } catch (e) {
      print('Error updating lead: $e');
      return false;
    }
  }

  Future<bool> updateLeadStatus(String leadId, LeadStatus status) async {
    try {
      final updateData = {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (status != LeadStatus.newLead) {
        updateData['contacted_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('leads')
          .update(updateData)
          .eq('id', leadId);
      
      return true;
    } catch (e) {
      print('Error updating lead status: $e');
      return false;
    }
  }

  Future<bool> assignLead(String leadId, String assignedTo) async {
    try {
      await _supabase
          .from('leads')
          .update({
            'assigned_to': assignedTo,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leadId);
      
      return true;
    } catch (e) {
      print('Error assigning lead: $e');
      return false;
    }
  }

  Future<bool> updateLeadEstimate(String leadId, double estimatedValue, String? notes) async {
    try {
      await _supabase
          .from('leads')
          .update({
            'estimated_value': estimatedValue,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leadId);
      
      return true;
    } catch (e) {
      print('Error updating lead estimate: $e');
      return false;
    }
  }

  Future<bool> deleteLead(String leadId) async {
    try {
      await _supabase
          .from('leads')
          .delete()
          .eq('id', leadId);
      
      return true;
    } catch (e) {
      print('Error deleting lead: $e');
      return false;
    }
  }

  Future<Map<String, int>> getLeadMetrics() async {
    try {
      final leads = await getLeads();
      
      final newLeads = leads.where((l) => l.status == LeadStatus.newLead).length;
      final contacted = leads.where((l) => l.status == LeadStatus.contacted).length;
      final quoted = leads.where((l) => l.status == LeadStatus.quoted).length;
      final won = leads.where((l) => l.status == LeadStatus.won).length;
      final lost = leads.where((l) => l.status == LeadStatus.lost).length;
      final thisWeek = leads.where((l) => 
          l.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
      final thisMonth = leads.where((l) => 
          l.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;
      final staleLeads = leads.where((l) => l.isStale).length;
      
      return {
        'total': leads.length,
        'new': newLeads,
        'contacted': contacted,
        'quoted': quoted,
        'won': won,
        'lost': lost,
        'thisWeek': thisWeek,
        'thisMonth': thisMonth,
        'staleLeads': staleLeads,
        'conversionRate': leads.isNotEmpty ? ((won / leads.length) * 100).round() : 0,
      };
    } catch (e) {
      print('Error loading lead metrics: $e');
      return {
        'total': 0,
        'new': 0,
        'contacted': 0,
        'quoted': 0,
        'won': 0,
        'lost': 0,
        'thisWeek': 0,
        'thisMonth': 0,
        'staleLeads': 0,
        'conversionRate': 0,
      };
    }
  }

  Future<Map<String, double>> getLeadFinancialMetrics() async {
    try {
      final leads = await getLeads();
      
      final totalEstimatedValue = leads
          .where((l) => l.estimatedValue != null)
          .fold(0.0, (sum, l) => sum + l.estimatedValue!);
      
      final wonValue = leads
          .where((l) => l.status == LeadStatus.won && l.estimatedValue != null)
          .fold(0.0, (sum, l) => sum + l.estimatedValue!);
      
      final quotedValue = leads
          .where((l) => l.status == LeadStatus.quoted && l.estimatedValue != null)
          .fold(0.0, (sum, l) => sum + l.estimatedValue!);
      
      final avgLeadValue = leads.where((l) => l.estimatedValue != null).isNotEmpty
          ? totalEstimatedValue / leads.where((l) => l.estimatedValue != null).length
          : 0.0;
      
      return {
        'totalEstimatedValue': totalEstimatedValue,
        'wonValue': wonValue,
        'quotedValue': quotedValue,
        'avgLeadValue': avgLeadValue,
      };
    } catch (e) {
      print('Error loading lead financial metrics: $e');
      return {
        'totalEstimatedValue': 0.0,
        'wonValue': 0.0,
        'quotedValue': 0.0,
        'avgLeadValue': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getLeadsByTimeline() async {
    try {
      final leads = await getLeads();
      
      final timelineData = <String, int>{};
      for (final lead in leads) {
        timelineData[lead.timeline] = (timelineData[lead.timeline] ?? 0) + 1;
      }
      
      return timelineData.entries.map((entry) => {
        'timeline': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      print('Error loading leads by timeline: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLeadsByProjectType() async {
    try {
      final leads = await getLeads();
      
      final projectTypeData = <String, int>{};
      for (final lead in leads) {
        projectTypeData[lead.projectType] = (projectTypeData[lead.projectType] ?? 0) + 1;
      }
      
      return projectTypeData.entries.map((entry) => {
        'projectType': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      print('Error loading leads by project type: $e');
      return [];
    }
  }
}
