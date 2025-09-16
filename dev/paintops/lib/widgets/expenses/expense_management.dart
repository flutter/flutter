import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/operations_provider.dart';
import '../../models/expense_model.dart';
import '../../utils/responsive_layout.dart';
import 'add_expense_dialog.dart';

class ExpenseManagement extends StatefulWidget {
  const ExpenseManagement({super.key});

  void showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );
  }

  @override
  State<ExpenseManagement> createState() => _ExpenseManagementState();
}

class _ExpenseManagementState extends State<ExpenseManagement> {
  String? _selectedProjectFilter;
  ExpenseCategory? _selectedCategoryFilter;
  String _searchQuery = '';
  bool _showOnlyPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OperationsProvider>(context, listen: false);
      provider.loadExpenses();
      provider.loadProjects(); // For project filter dropdown
    });
  }

  @override
  Widget build(BuildContext context) {
    final operationsProvider = Provider.of<OperationsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

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
      child: Column(
        children: [
          _buildHeader(authProvider, operationsProvider),
          _buildFilters(operationsProvider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => operationsProvider.retryLoadExpenses(),
              child: _buildExpensesList(operationsProvider, authProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider, OperationsProvider provider) {
    return Container(
      margin: ResponsiveLayout.getPadding(context),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: ResponsiveLayout.getIconSize(context, base: 36),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Management',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 24),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      authProvider.canApproveExpenses()
                          ? 'Track and approve project expenses'
                          : 'Submit and track your project expenses',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.isLoadingExpenses)
                const CircularProgressIndicator()
              else if (provider.expenseError != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFFEF4444)),
                  onPressed: provider.retryLoadExpenses,
                ),
            ],
          ),
          
          if (authProvider.canApproveExpenses() && provider.pendingExpenses.isNotEmpty) ...{
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF2F2), Color(0xFFFDE8E8)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: Colors.white,
                      size: ResponsiveLayout.getIconSize(context, base: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${provider.pendingExpenses.length} expenses awaiting approval (\$${provider.totalPendingExpenseAmount.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildFilters(OperationsProvider provider) {
    return Container(
      margin: ResponsiveLayout.getPadding(context).copyWith(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search expenses by supplier or description...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 20),

          // Filter chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Project filter
              if (provider.projects.isNotEmpty)
                FilterChip(
                  label: Text(_selectedProjectFilter ?? 'All Projects'),
                  selected: _selectedProjectFilter != null,
                  onSelected: (selected) => _showProjectFilterDialog(provider),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF37474F).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF37474F),
                ),

              // Category filter
              FilterChip(
                label: Text(_selectedCategoryFilter?.displayName ?? 'All Categories'),
                selected: _selectedCategoryFilter != null,
                onSelected: (selected) => _showCategoryFilterDialog(),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                checkmarkColor: const Color(0xFF8B5CF6),
              ),

              // Pending only filter
              FilterChip(
                label: const Text('Pending Only'),
                selected: _showOnlyPending,
                onSelected: (selected) => setState(() => _showOnlyPending = selected),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFEF4444).withOpacity(0.1),
                checkmarkColor: const Color(0xFFEF4444),
              ),

              // Clear filters
              if (_hasActiveFilters())
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: _clearFilters,
                  backgroundColor: const Color(0xFFF8F9FA),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(OperationsProvider provider, AuthProvider authProvider) {
    if (provider.isLoadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.expenseError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveLayout.getIconSize(context, base: 64),
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              provider.expenseError!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF78909C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.retryLoadExpenses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37474F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final filteredExpenses = _getFilteredExpenses(provider);

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: ResponsiveLayout.getIconSize(context, base: 64),
              color: const Color(0xFF78909C),
            ),
            SizedBox(height: ResponsiveLayout.getSpacing(context)),
            Text(
              _hasActiveFilters() ? 'No expenses match your filters' : 'No expenses found',
              style: TextStyle(
                fontSize: ResponsiveLayout.getFontSize(context, base: 18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF37474F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters() 
                  ? 'Try adjusting your search criteria'
                  : 'Start adding expenses to track project costs',
              style: TextStyle(
                fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                color: const Color(0xFF78909C),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveLayout.getPadding(context),
      itemCount: filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = filteredExpenses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildExpenseCard(expense, authProvider, provider),
        );
      },
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense, AuthProvider authProvider, OperationsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expense.isApproved 
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      expense.category.color,
                      expense.category.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: expense.category.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  expense.category.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.supplier ?? 'Unknown Supplier',
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 18),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF37474F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: expense.isApproved 
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (expense.isApproved 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444)).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            expense.isApproved ? 'Approved' : 'Pending',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: expense.category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            expense.category.displayName,
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                              color: expense.category.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, yyyy').format(expense.date),
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                            color: const Color(0xFF78909C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF37474F),
                    ),
                  ),
                  if (authProvider.canApproveExpenses() && !expense.isApproved)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _approveExpense(expense, authProvider, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(90, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Project name
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.work_outline,
                  size: 18,
                  color: const Color(0xFF78909C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.projectName,
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                      color: const Color(0xFF37474F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (expense.description != null && expense.description!.isNotEmpty) ...{
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                expense.description!,
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                  color: const Color(0xFF37474F),
                  height: 1.5,
                ),
              ),
            ),
          },

          if (expense.isApproved && expense.approvedBy != null) ...{
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Approved by ${expense.approvedBy}',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                      color: const Color(0xFF065F46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (expense.approvedAt != null) ...{
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMM d').format(expense.approvedAt!),
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 11),
                        color: const Color(0xFF065F46).withOpacity(0.7),
                      ),
                    ),
                  },
                ],
              ),
            ),
          },
        ],
      ),
    );
  }

  List<ExpenseModel> _getFilteredExpenses(OperationsProvider provider) {
    var expenses = List<ExpenseModel>.from(provider.expenses);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      expenses = expenses.where((expense) {
        final searchLower = _searchQuery.toLowerCase();
        return (expense.supplier?.toLowerCase().contains(searchLower) ?? false) ||
               (expense.description?.toLowerCase().contains(searchLower) ?? false) ||
               expense.projectName.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply project filter
    if (_selectedProjectFilter != null) {
      expenses = expenses.where((expense) => expense.projectName == _selectedProjectFilter).toList();
    }

    // Apply category filter
    if (_selectedCategoryFilter != null) {
      expenses = expenses.where((expense) => expense.category == _selectedCategoryFilter).toList();
    }

    // Apply pending filter
    if (_showOnlyPending) {
      expenses = expenses.where((expense) => !expense.isApproved).toList();
    }

    return expenses;
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
           _selectedProjectFilter != null ||
           _selectedCategoryFilter != null ||
           _showOnlyPending;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedProjectFilter = null;
      _selectedCategoryFilter = null;
      _showOnlyPending = false;
    });
  }

  void _showProjectFilterDialog(OperationsProvider provider) {
    final projectNames = provider.projects.map((p) => p.name).toSet().toList()..sort();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Filter by Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Projects'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedProjectFilter,
                onChanged: (value) {
                  setState(() => _selectedProjectFilter = value);
                  Navigator.of(context).pop();
                },
              ),
            ),
            ...projectNames.map((name) => ListTile(
              title: Text(name),
              leading: Radio<String?>(
                value: name,
                groupValue: _selectedProjectFilter,
                onChanged: (value) {
                  setState(() => _selectedProjectFilter = value);
                  Navigator.of(context).pop();
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Categories'),
              leading: Radio<ExpenseCategory?>(
                value: null,
                groupValue: _selectedCategoryFilter,
                onChanged: (value) {
                  setState(() => _selectedCategoryFilter = value);
                  Navigator.of(context).pop();
                },
              ),
            ),
            ...ExpenseCategory.values.map((category) => ListTile(
              title: Text(category.displayName),
              leading: Radio<ExpenseCategory?>(
                value: category,
                groupValue: _selectedCategoryFilter,
                onChanged: (value) {
                  setState(() => _selectedCategoryFilter = value);
                  Navigator.of(context).pop();
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _approveExpense(ExpenseModel expense, AuthProvider authProvider, OperationsProvider provider) async {
    final success = await provider.approveExpense(
      expense.id,
      authProvider.currentUser!.fullName,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Expense approved successfully'
                : 'Failed to approve expense',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
