import 'package:flutter/foundation.dart';
import '../models/lead_model.dart';
import '../repositories/lead_repository.dart';
import '../services/email_service.dart';
import '../services/notification_service.dart';

class LeadProvider extends ChangeNotifier {
  final LeadRepository _leadRepository;
  final EmailService _emailService = EmailService();
  final NotificationService _notificationService = NotificationService();
  
  LeadProvider(this._leadRepository);

  List<LeadModel> _leads = [];
  Map<String, int> _leadMetrics = {};
  Map<String, double> _leadFinancialMetrics = {};
  List<Map<String, dynamic>> _leadsByTimeline = [];
  List<Map<String, dynamic>> _leadsByProjectType = [];
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<LeadModel> get leads => _leads;
  Map<String, int> get leadMetrics => _leadMetrics;
  Map<String, double> get leadFinancialMetrics => _leadFinancialMetrics;
  List<Map<String, dynamic>> get leadsByTimeline => _leadsByTimeline;
  List<Map<String, dynamic>> get leadsByProjectType => _leadsByProjectType;
  
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<LeadModel> get newLeads => _leads.where((l) => l.status == LeadStatus.newLead).toList();
  List<LeadModel> get staleLeads => _leads.where((l) => l.isStale).toList();
  List<LeadModel> get urgentLeads => _leads.where((l) => l.urgencyLevel == 'Urgent').toList();

  Future<void> loadLeads({LeadStatus? status, bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _leads = await _leadRepository.getLeads(status: status);
      await _loadLeadAnalytics();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load leads. Please try again.';
      if (kDebugMode) {
        print('Error loading leads: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLeadAnalytics() async {
    try {
      final futures = await Future.wait([
        _leadRepository.getLeadMetrics(),
        _leadRepository.getLeadFinancialMetrics(),
        _leadRepository.getLeadsByTimeline(),
        _leadRepository.getLeadsByProjectType(),
      ]);

      _leadMetrics = futures[0] as Map<String, int>;
      _leadFinancialMetrics = futures[1] as Map<String, double>;
      _leadsByTimeline = futures[2] as List<Map<String, dynamic>>;
      _leadsByProjectType = futures[3] as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error loading lead analytics: $e');
    }
  }

  Future<bool> submitLead(LeadModel lead) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _leadRepository.createLead(lead);
      
      if (success) {
        // Send email notification
        await _emailService.sendNewLeadNotification(lead);
        
        // Send push notification
        await _notificationService.notifyNewLead(lead.name, lead.projectType);
        
        // Refresh leads list
        await loadLeads(forceRefresh: true);
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Failed to submit lead. Please try again.';
      if (kDebugMode) {
        print('Error submitting lead: $e');
      }
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateLeadStatus(String leadId, LeadStatus status) async {
    try {
      final success = await _leadRepository.updateLeadStatus(leadId, status);
      
      if (success) {
        final index = _leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          _leads[index] = _leads[index].copyWith(
            status: status,
            contactedAt: status != LeadStatus.newLead ? DateTime.now() : null,
          );
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating lead status: $e');
      }
      return false;
    }
  }

  Future<bool> assignLead(String leadId, String assignedTo) async {
    try {
      final success = await _leadRepository.assignLead(leadId, assignedTo);
      
      if (success) {
        final index = _leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          _leads[index] = _leads[index].copyWith(assignedTo: assignedTo);
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error assigning lead: $e');
      }
      return false;
    }
  }

  Future<bool> updateLeadEstimate(String leadId, double estimatedValue, String? notes) async {
    try {
      final success = await _leadRepository.updateLeadEstimate(leadId, estimatedValue, notes);
      
      if (success) {
        final index = _leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          _leads[index] = _leads[index].copyWith(
            estimatedValue: estimatedValue,
            notes: notes,
          );
          notifyListeners();
        }
        
        // Send quote email if lead has email
        final lead = _leads[index];
        if (lead.email != null && lead.email!.isNotEmpty) {
          await _emailService.sendQuoteResponseEmail(
            lead.email!,
            lead.name,
            estimatedValue,
          );
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating lead estimate: $e');
      }
      return false;
    }
  }

  Future<bool> deleteLead(String leadId) async {
    try {
      final success = await _leadRepository.deleteLead(leadId);
      
      if (success) {
        _leads.removeWhere((l) => l.id == leadId);
        await _loadLeadAnalytics();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting lead: $e');
      }
      return false;
    }
  }

  Future<LeadModel?> getLead(String leadId) async {
    try {
      return await _leadRepository.getLead(leadId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting lead: $e');
      }
      return null;
    }
  }

  List<LeadModel> getLeadsByStatus(LeadStatus status) {
    return _leads.where((l) => l.status == status).toList();
  }

  List<LeadModel> getLeadsByProjectType(String projectType) {
    return _leads.where((l) => l.projectType == projectType).toList();
  }

  List<LeadModel> getLeadsByUrgency(String urgencyLevel) {
    return _leads.where((l) => l.urgencyLevel == urgencyLevel).toList();
  }

  List<LeadModel> searchLeads(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _leads.where((lead) =>
        lead.name.toLowerCase().contains(lowercaseQuery) ||
        lead.phone.toLowerCase().contains(lowercaseQuery) ||
        lead.address.toLowerCase().contains(lowercaseQuery) ||
        (lead.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        lead.projectType.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  void sortLeadsByDate({bool ascending = false}) {
    _leads.sort((a, b) => ascending 
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void sortLeadsByStatus() {
    _leads.sort((a, b) => a.status.name.compareTo(b.status.name));
    notifyListeners();
  }

  void sortLeadsByUrgency() {
    const urgencyOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
    _leads.sort((a, b) => 
        (urgencyOrder[a.urgencyLevel] ?? 4).compareTo(urgencyOrder[b.urgencyLevel] ?? 4));
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshLeads() async {
    await loadLeads(forceRefresh: true);
  }

  // Analytics methods
  double get averageLeadValue {
    final leadsWithValues = _leads.where((l) => l.estimatedValue != null);
    if (leadsWithValues.isEmpty) return 0.0;
    
    final totalValue = leadsWithValues.fold(0.0, (sum, lead) => sum + lead.estimatedValue!);
    return totalValue / leadsWithValues.length;
  }

  double get conversionRate {
    if (_leads.isEmpty) return 0.0;
    final wonLeads = _leads.where((l) => l.status == LeadStatus.won).length;
    return (wonLeads / _leads.length) * 100;
  }

  Map<String, int> get leadStatusDistribution {
    final distribution = <String, int>{};
    for (final status in LeadStatus.values) {
      distribution[status.displayName] = _leads.where((l) => l.status == status).length;
    }
    return distribution;
  }

  List<LeadModel> getRecentLeads({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _leads.where((l) => l.createdAt.isAfter(cutoffDate)).toList();
  }
}
