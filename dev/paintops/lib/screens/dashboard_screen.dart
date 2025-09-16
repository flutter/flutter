import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/operations_provider.dart';
import '../widgets/navigation/app_drawer.dart';
import '../widgets/dashboard/metrics_cards.dart';
import '../widgets/timesheet/timesheet_panel.dart';
import '../widgets/projects/project_management.dart';
import '../widgets/expenses/expense_management.dart';
import '../widgets/timesheet/log_time_form.dart';
import '../utils/responsive_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final operationsProvider = Provider.of<OperationsProvider>(context, listen: false);
    operationsProvider.loadProjects();
    operationsProvider.loadTimesheets();
    operationsProvider.loadExpenses();
    operationsProvider.loadFinancialSummary();
    operationsProvider.loadOperationalMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final operationsProvider = Provider.of<OperationsProvider>(context);
    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.business,
                size: ResponsiveLayout.getIconSize(context, base: 24),
                color: const Color(0xFF263238),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PaintOps',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (operationsProvider.hasAnyError)
            IconButton(
              icon: const Icon(Icons.error_outline, color: Colors.orange),
              onPressed: () => _showErrorDialog(operationsProvider),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    backgroundColor: Colors.transparent,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.fullName.split(' ').map((n) => n[0]).take(2).join(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                if (!ResponsiveLayout.isMobileLayout(context)) ...{
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user.role.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                },
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _selectedIndex = index),
          indicatorColor: const Color(0xFFB0BEC5),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(
              icon: Icon(
                Icons.dashboard,
                size: ResponsiveLayout.getIconSize(context, base: 20),
              ),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(
                Icons.access_time,
                size: ResponsiveLayout.getIconSize(context, base: 20),
              ),
              text: 'Timesheets',
            ),
            Tab(
              icon: Icon(
                Icons.work,
                size: ResponsiveLayout.getIconSize(context, base: 20),
              ),
              text: 'Projects',
            ),
            Tab(
              icon: Icon(
                Icons.attach_money,
                size: ResponsiveLayout.getIconSize(context, base: 20),
              ),
              text: 'Expenses',
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const TimesheetPanel(),
          const ProjectManagement(),
          const ExpenseManagement(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFECEFF1),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          final provider = Provider.of<OperationsProvider>(context, listen: false);
          await provider.refreshAllData();
        },
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              MetricsCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    
    switch (_selectedIndex) {
      case 1: // Timesheets
        if (authProvider.canSubmitTimesheets()) {
          return FloatingActionButton.extended(
            onPressed: () => _showLogTimeForm(),
            icon: const Icon(Icons.add_alarm),
            label: const Text('Log Time'),
            backgroundColor: const Color(0xFF37474F),
            foregroundColor: Colors.white,
            elevation: 8,
          );
        }
        break;
      case 3: // Expenses
        if (authProvider.canSubmitExpenses()) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddExpenseDialog(),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Add Expense'),
            backgroundColor: const Color(0xFF37474F),
            foregroundColor: Colors.white,
            elevation: 8,
          );
        }
        break;
    }
    return null;
  }

  void _showLogTimeForm() {
    showDialog(
      context: context,
      builder: (context) => const LogTimeForm(),
      barrierDismissible: false,
    );
  }

  void _showAddExpenseDialog() {
    final provider = Provider.of<OperationsProvider>(context, listen: false);
    // Get the ExpenseManagement widget to show the add expense dialog
    final expenseManagement = ExpenseManagement();
    expenseManagement.showAddExpenseDialog(context);
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('$feature Coming Soon'),
        content: Text('$feature functionality is being developed and will be available in the next update.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(OperationsProvider provider) {
    final errors = <String>[];
    if (provider.projectError != null) errors.add('Projects: ${provider.projectError}');
    if (provider.timesheetError != null) errors.add('Timesheets: ${provider.timesheetError}');
    if (provider.expenseError != null) errors.add('Expenses: ${provider.expenseError}');
    if (provider.metricsError != null) errors.add('Metrics: ${provider.metricsError}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Connection Issues'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Some data could not be loaded:'),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $error', style: const TextStyle(fontSize: 14)),
            )),
            const SizedBox(height: 16),
            const Text('Pull down on any tab to refresh, or tap Retry below.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.clearAllErrors();
            },
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.refreshAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
