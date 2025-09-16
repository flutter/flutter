import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../models/timesheet_model.dart';
import '../models/expense_model.dart';
import '../repositories/project_repository.dart';
import '../repositories/timesheet_repository.dart';
import '../repositories/expense_repository.dart';

class OperationsProvider extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TimesheetRepository _timesheetRepository;
  final ExpenseRepository _expenseRepository;
  
  OperationsProvider(
    this._projectRepository,
    this._timesheetRepository,
    this._expenseRepository,
  );
  
  List<ProjectModel> _projects = [];
  List<TimesheetModel> _timesheets = [];
  List<ExpenseModel> _expenses = [];
  Map<String, double> _financialSummary = {};
  Map<String, int> _operationalMetrics = {};
  
  bool _isLoadingProjects = false;
  bool _isLoadingTimesheets = false;
  bool _isLoadingExpenses = false;
  bool _isLoadingMetrics = false;

  String? _projectError;
  String? _timesheetError;
  String? _expenseError;
  String? _metricsError;

  // Getters
  List<ProjectModel> get projects => _projects;
  List<TimesheetModel> get timesheets => _timesheets;
  List<ExpenseModel> get expenses => _expenses;
  Map<String, double> get financialSummary => _financialSummary;
  Map<String, int> get operationalMetrics => _operationalMetrics;
  
  bool get isLoadingProjects => _isLoadingProjects;
  bool get isLoadingTimesheets => _isLoadingTimesheets;
  bool get isLoadingExpenses => _isLoadingExpenses;
  bool get isLoadingMetrics => _isLoadingMetrics;

  String? get projectError => _projectError;
  String? get timesheetError => _timesheetError;
  String? get expenseError => _expenseError;
  String? get metricsError => _metricsError;

  bool get hasAnyError => _projectError != null || _timesheetError != null || 
                         _expenseError != null || _metricsError != null;

  // Project methods
  Future<void> loadProjects({bool forceRefresh = false}) async {
    if (_isLoadingProjects && !forceRefresh) return;
    
    _isLoadingProjects = true;
    _projectError = null;
    notifyListeners();

    try {
      _projects = await _projectRepository.getProjects();
      _projectError = null;
    } catch (e) {
      _projectError = 'Failed to load projects. Please try again.';
      if (kDebugMode) {
        print('Error loading projects: $e');
      }
    } finally {
      _isLoadingProjects = false;
      notifyListeners();
    }
  }

  Future<void> retryLoadProjects() async {
    await loadProjects(forceRefresh: true);
  }

  // Timesheet methods
  Future<void> loadTimesheets({String? projectId, String? workerId, bool forceRefresh = false}) async {
    if (_isLoadingTimesheets && !forceRefresh) return;
    
    _isLoadingTimesheets = true;
    _timesheetError = null;
    notifyListeners();

    try {
      _timesheets = await _timesheetRepository.getTimesheets(
        projectId: projectId,
        workerId: workerId,
      );
      _timesheetError = null;
    } catch (e) {
      _timesheetError = 'Failed to load timesheets. Please try again.';
      if (kDebugMode) {
        print('Error loading timesheets: $e');
      }
    } finally {
      _isLoadingTimesheets = false;
      notifyListeners();
    }
  }

  Future<bool> submitTimesheet(TimesheetModel timesheet) async {
    try {
      final success = await _timesheetRepository.submitTimesheet(timesheet);
      if (success) {
        // Refresh timesheets to get the latest data from database
        await loadTimesheets(forceRefresh: true);
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting timesheet: $e');
      }
      return false;
    }
  }

  Future<bool> approveTimesheet(String timesheetId, String approvedBy) async {
    try {
      final success = await _timesheetRepository.approveTimesheet(timesheetId, approvedBy);
      if (success) {
        final index = _timesheets.indexWhere((t) => t.id == timesheetId);
        if (index != -1) {
          _timesheets[index] = _timesheets[index].copyWith(
            isApproved: true,
            approvedBy: approvedBy,
            approvedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving timesheet: $e');
      }
      return false;
    }
  }

  Future<void> retryLoadTimesheets() async {
    await loadTimesheets(forceRefresh: true);
  }

  // Expense methods
  Future<void> loadExpenses({String? projectId, bool forceRefresh = false}) async {
    if (_isLoadingExpenses && !forceRefresh) return;
    
    _isLoadingExpenses = true;
    _expenseError = null;
    notifyListeners();

    try {
      _expenses = await _expenseRepository.getExpenses(projectId: projectId);
      _expenseError = null;
    } catch (e) {
      _expenseError = 'Failed to load expenses. Please try again.';
      if (kDebugMode) {
        print('Error loading expenses: $e');
      }
    } finally {
      _isLoadingExpenses = false;
      notifyListeners();
    }
  }

  Future<bool> submitExpense(ExpenseModel expense) async {
    try {
      final success = await _expenseRepository.submitExpense(expense);
      if (success) {
        // Refresh expenses to get the latest data from database
        await loadExpenses(forceRefresh: true);
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting expense: $e');
      }
      return false;
    }
  }

  Future<bool> approveExpense(String expenseId, String approvedBy) async {
    try {
      final success = await _expenseRepository.approveExpense(expenseId, approvedBy);
      if (success) {
        final index = _expenses.indexWhere((e) => e.id == expenseId);
        if (index != -1) {
          _expenses[index] = _expenses[index].copyWith(
            isApproved: true,
            approvedBy: approvedBy,
            approvedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving expense: $e');
      }
      return false;
    }
  }

  Future<void> retryLoadExpenses() async {
    await loadExpenses(forceRefresh: true);
  }

  // Analytics methods
  Future<void> loadFinancialSummary({bool forceRefresh = false}) async {
    if (_isLoadingMetrics && !forceRefresh) return;
    
    _isLoadingMetrics = true;
    _metricsError = null;
    notifyListeners();

    try {
      final projectSummary = await _projectRepository.getFinancialSummary();
      final expenseSummary = await _expenseRepository.getExpenseSummary();
      
      _financialSummary = {
        ...projectSummary,
        ...expenseSummary,
      };
      _metricsError = null;
    } catch (e) {
      _metricsError = 'Failed to load financial data. Please try again.';
      if (kDebugMode) {
        print('Error loading financial summary: $e');
      }
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  Future<void> loadOperationalMetrics({bool forceRefresh = false}) async {
    try {
      final projectMetrics = await _projectRepository.getOperationalMetrics();
      final timesheetMetrics = await _timesheetRepository.getTimesheetMetrics();
      final expenseMetrics = await _expenseRepository.getExpenseMetrics();
      
      _operationalMetrics = {
        ...projectMetrics,
        ...timesheetMetrics,
        ...expenseMetrics,
      };
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading operational metrics: $e');
      }
    }
  }

  Future<void> retryLoadMetrics() async {
    await loadFinancialSummary(forceRefresh: true);
    await loadOperationalMetrics(forceRefresh: true);
  }

  // Utility methods
  List<TimesheetModel> get pendingTimesheets => 
      _timesheets.where((t) => !t.isApproved).toList();

  List<ExpenseModel> get pendingExpenses => 
      _expenses.where((e) => !e.isApproved).toList();

  int get totalPendingApprovals => 
      pendingTimesheets.length + pendingExpenses.length;

  double get totalPendingExpenseAmount => 
      pendingExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

  List<ProjectModel> get activeProjects => 
      _projects.where((p) => p.status == ProjectStatus.inProgress).toList();

  List<ProjectModel> get overdueProjects => 
      _projects.where((p) => p.isOverdue).toList();

  // Filtering methods for expenses
  List<ExpenseModel> getExpensesByCategory(ExpenseCategory category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  List<ExpenseModel> getExpensesByProject(String projectId) {
    return _expenses.where((e) => e.projectId == projectId).toList();
  }

  List<ExpenseModel> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _expenses.where((e) => 
        e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        e.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  // Clear error methods
  void clearProjectError() {
    _projectError = null;
    notifyListeners();
  }

  void clearTimesheetError() {
    _timesheetError = null;
    notifyListeners();
  }

  void clearExpenseError() {
    _expenseError = null;
    notifyListeners();
  }

  void clearMetricsError() {
    _metricsError = null;
    notifyListeners();
  }

  void clearAllErrors() {
    _projectError = null;
    _timesheetError = null;
    _expenseError = null;
    _metricsError = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadProjects(forceRefresh: true),
      loadTimesheets(forceRefresh: true),
      loadExpenses(forceRefresh: true),
      loadFinancialSummary(forceRefresh: true),
      loadOperationalMetrics(forceRefresh: true),
    ]);
  }
}
