import 'package:flutter/foundation.dart';
import '../repositories/project_repository.dart';
import '../repositories/timesheet_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/lead_repository.dart';

class ReportingProvider extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TimesheetRepository _timesheetRepository;
  final ExpenseRepository _expenseRepository;
  final LeadRepository _leadRepository;
  
  ReportingProvider(
    this._projectRepository,
    this._timesheetRepository,
    this._expenseRepository,
    this._leadRepository,
  );

  Map<String, double> _financialSummary = {};
  Map<String, int> _operationalMetrics = {};
  List<Map<String, dynamic>> _expensesByCategory = [];
  List<Map<String, dynamic>> _workerProductivity = [];
  List<Map<String, dynamic>> _leadsByTimeline = [];
  List<Map<String, dynamic>> _leadsByProjectType = [];
  Map<String, double> _leadFinancialMetrics = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _currentPeriodStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _currentPeriodEnd = DateTime.now();

  // Getters
  Map<String, double> get financialSummary => _financialSummary;
  Map<String, int> get operationalMetrics => _operationalMetrics;
  List<Map<String, dynamic>> get expensesByCategory => _expensesByCategory;
  List<Map<String, dynamic>> get workerProductivity => _workerProductivity;
  List<Map<String, dynamic>> get leadsByTimeline => _leadsByTimeline;
  List<Map<String, dynamic>> get leadsByProjectType => _leadsByProjectType;
  Map<String, double> get leadFinancialMetrics => _leadFinancialMetrics;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get currentPeriodStart => _currentPeriodStart;
  DateTime get currentPeriodEnd => _currentPeriodEnd;

  Future<void> loadReportingData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadFinancialData(),
        _loadOperationalData(),
        _loadExpenseAnalytics(),
        _loadProductivityData(),
        _loadLeadAnalytics(),
      ]);
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load reporting data. Please try again.';
      if (kDebugMode) {
        print('Error loading reporting data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFinancialData() async {
    try {
      final projectFinancials = await _projectRepository.getFinancialSummary();
      final expenseFinancials = await _expenseRepository.getExpenseSummary();
      final leadFinancials = await _leadRepository.getLeadFinancialMetrics();
      
      _financialSummary = {
        ...projectFinancials,
        ...expenseFinancials,
      };
      
      _leadFinancialMetrics = leadFinancials;
    } catch (e) {
      print('Error loading financial data: $e');
    }
  }

  Future<void> _loadOperationalData() async {
    try {
      final projectMetrics = await _projectRepository.getOperationalMetrics();
      final timesheetMetrics = await _timesheetRepository.getTimesheetMetrics();
      final expenseMetrics = await _expenseRepository.getExpenseMetrics();
      final leadMetrics = await _leadRepository.getLeadMetrics();
      
      _operationalMetrics = {
        ...projectMetrics,
        ...timesheetMetrics,
        ...expenseMetrics,
        ...leadMetrics,
      };
    } catch (e) {
      print('Error loading operational data: $e');
    }
  }

  Future<void> _loadExpenseAnalytics() async {
    try {
      _expensesByCategory = await _expenseRepository.getExpensesByCategory();
    } catch (e) {
      print('Error loading expense analytics: $e');
    }
  }

  Future<void> _loadProductivityData() async {
    try {
      _workerProductivity = await _timesheetRepository.getWorkerProductivity(
        _currentPeriodStart,
        _currentPeriodEnd,
      );
    } catch (e) {
      print('Error loading productivity data: $e');
    }
  }

  Future<void> _loadLeadAnalytics() async {
    try {
      _leadsByTimeline = await _leadRepository.getLeadsByTimeline();
      _leadsByProjectType = await _leadRepository.getLeadsByProjectType();
    } catch (e) {
      print('Error loading lead analytics: $e');
    }
  }

  void updatePeriod(DateTime startDate, DateTime endDate) {
    _currentPeriodStart = startDate;
    _currentPeriodEnd = endDate;
    loadReportingData(forceRefresh: true);
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    _currentPeriodStart = DateTime(now.year, now.month, 1);
    _currentPeriodEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    loadReportingData(forceRefresh: true);
  }

  void setCurrentQuarter() {
    final now = DateTime.now();
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    _currentPeriodStart = DateTime(now.year, quarterMonth, 1);
    _currentPeriodEnd = DateTime(now.year, quarterMonth + 3, 1).subtract(const Duration(days: 1));
    loadReportingData(forceRefresh: true);
  }

  void setCurrentYear() {
    final now = DateTime.now();
    _currentPeriodStart = DateTime(now.year, 1, 1);
    _currentPeriodEnd = DateTime(now.year, 12, 31);
    loadReportingData(forceRefresh: true);
  }

  void setLast30Days() {
    final now = DateTime.now();
    _currentPeriodStart = now.subtract(const Duration(days: 30));
    _currentPeriodEnd = now;
    loadReportingData(forceRefresh: true);
  }

  void setLast90Days() {
    final now = DateTime.now();
    _currentPeriodStart = now.subtract(const Duration(days: 90));
    _currentPeriodEnd = now;
    loadReportingData(forceRefresh: true);
  }

  // Analytics calculations
  double get totalRevenue => _financialSummary['totalBudget'] ?? 0.0;
  double get totalExpenses => _financialSummary['totalExpenses'] ?? 0.0;
  double get netProfit => totalRevenue - totalExpenses;
  double get profitMargin => totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

  double get pendingExpenseValue => _financialSummary['pendingExpenses'] ?? 0.0;
  double get approvedExpenseValue => _financialSummary['totalApprovedExpenses'] ?? 0.0;

  int get totalProjects => _operationalMetrics['totalProjects'] ?? 0;
  int get activeProjects => _operationalMetrics['activeProjects'] ?? 0;
  int get completedProjects => _operationalMetrics['completedProjects'] ?? 0;
  double get projectCompletionRate => totalProjects > 0 ? (completedProjects / totalProjects) * 100 : 0.0;

  int get totalTimesheets => _operationalMetrics['totalTimesheets'] ?? 0;
  int get pendingTimesheets => _operationalMetrics['pendingTimesheetApprovals'] ?? 0;
  int get totalHours => _operationalMetrics['totalHours'] ?? 0;

  int get totalLeads => _operationalMetrics['total'] ?? 0;
  int get newLeads => _operationalMetrics['new'] ?? 0;
  int get wonLeads => _operationalMetrics['won'] ?? 0;
  double get leadConversionRate => _operationalMetrics['conversionRate']?.toDouble() ?? 0.0;

  double get avgLeadValue => _leadFinancialMetrics['avgLeadValue'] ?? 0.0;
  double get potentialRevenue => _leadFinancialMetrics['quotedValue'] ?? 0.0;

  // Chart data preparation
  List<Map<String, dynamic>> get revenueVsExpensesData {
    return [
      {'category': 'Revenue', 'value': totalRevenue, 'color': 0xFF4CAF50},
      {'category': 'Expenses', 'value': totalExpenses, 'color': 0xFFF44336},
      {'category': 'Net Profit', 'value': netProfit, 'color': 0xFF2196F3},
    ];
  }

  List<Map<String, dynamic>> get projectStatusData {
    return [
      {'status': 'Active', 'count': activeProjects, 'color': 0xFF4CAF50},
      {'status': 'Completed', 'count': completedProjects, 'color': 0xFF2196F3},
      {'status': 'Planning', 'count': _operationalMetrics['planningProjects'] ?? 0, 'color': 0xFFFF9800},
      {'status': 'On Hold', 'count': _operationalMetrics['onHoldProjects'] ?? 0, 'color': 0xFF9C27B0},
    ];
  }

  List<Map<String, dynamic>> get leadStatusData {
    return [
      {'status': 'New', 'count': newLeads, 'color': 0xFF2196F3},
      {'status': 'Contacted', 'count': _operationalMetrics['contacted'] ?? 0, 'color': 0xFFFF9800},
      {'status': 'Quoted', 'count': _operationalMetrics['quoted'] ?? 0, 'color': 0xFF9C27B0},
      {'status': 'Won', 'count': wonLeads, 'color': 0xFF4CAF50},
      {'status': 'Lost', 'count': _operationalMetrics['lost'] ?? 0, 'color': 0xFFF44336},
    ];
  }

  // Monthly trend data (placeholder - would need historical data)
  List<Map<String, dynamic>> get monthlyRevenueData {
    // This would typically come from historical data
    // For now, return sample data structure
    return [
      {'month': 'Jan', 'revenue': totalRevenue * 0.8, 'expenses': totalExpenses * 0.7},
      {'month': 'Feb', 'revenue': totalRevenue * 0.9, 'expenses': totalExpenses * 0.8},
      {'month': 'Mar', 'revenue': totalRevenue * 1.1, 'expenses': totalExpenses * 0.9},
      {'month': 'Apr', 'revenue': totalRevenue, 'expenses': totalExpenses},
    ];
  }

  // Key performance indicators
  Map<String, dynamic> get kpis {
    return {
      'Revenue Growth': '${profitMargin.toStringAsFixed(1)}%',
      'Project Completion': '${projectCompletionRate.toStringAsFixed(1)}%',
      'Lead Conversion': '${leadConversionRate.toStringAsFixed(1)}%',
      'Active Projects': activeProjects.toString(),
      'Pending Approvals': (pendingTimesheets + (_operationalMetrics['pendingExpenseApprovals'] ?? 0)).toString(),
      'Total Hours': totalHours.toString(),
    };
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await loadReportingData(forceRefresh: true);
  }

  String get periodDisplayName {
    final formatter = RegExp(r'^\d{4}-\d{2}-\d{2}');
    final startStr = _currentPeriodStart.toIso8601String().substring(0, 10);
    final endStr = _currentPeriodEnd.toIso8601String().substring(0, 10);
    return '$startStr to $endStr';
  }
}
