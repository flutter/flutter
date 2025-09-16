import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/operations_provider.dart';
import '../../utils/responsive_layout.dart';

class MetricsCards extends StatefulWidget {
  const MetricsCards({super.key});

  @override
  State<MetricsCards> createState() => _MetricsCardsState();
}

class _MetricsCardsState extends State<MetricsCards>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final operationsProvider = Provider.of<OperationsProvider>(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${authProvider.currentUser?.fullName ?? 'User'}',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 28),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your operations today',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                    color: const Color(0xFF78909C),
                  ),
                ),
                SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
                
                if (authProvider.canViewFinancials()) ...{
                  _buildFinancialMetrics(context, operationsProvider),
                  SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
                },
                
                _buildOperationalMetrics(context, operationsProvider),
                SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
                
                if (authProvider.canApproveTimesheets() || authProvider.canApproveExpenses()) ...{
                  _buildApprovalMetrics(context, operationsProvider),
                  SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
                },
                
                _buildProjectStatus(context, operationsProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialMetrics(BuildContext context, OperationsProvider provider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: ResponsiveLayout.getIconSize(context, base: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Financial Overview',
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 22),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF37474F),
                        ),
                      ),
                      if (provider.isLoadingMetrics) ...{
                        const Spacer(),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      },
                    ],
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  
                  if (provider.metricsError != null)
                    _buildErrorCard(provider.metricsError!, provider.retryLoadMetrics)
                  else if (ResponsiveLayout.isMobileLayout(context))
                    _buildFinancialCardsMobile(context, provider)
                  else
                    _buildFinancialCardsDesktop(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(String error, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF2F2), Color(0xFFFDE8E8)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: const Color(0xFFEF4444),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCardsMobile(BuildContext context, OperationsProvider provider) {
    final summary = provider.financialSummary;
    
    return Column(
      children: [
        _buildFinancialCard(
          context,
          'Total Budget',
          '\$${(summary['totalBudget'] ?? 0).toStringAsFixed(0)}',
          Icons.account_balance_wallet,
          const Color(0xFF37474F),
        ),
        const SizedBox(height: 16),
        _buildFinancialCard(
          context,
          'Actual Costs',
          '\$${(summary['totalActualCosts'] ?? 0).toStringAsFixed(0)}',
          Icons.trending_up,
          const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        _buildFinancialCard(
          context,
          'Total Expenses',
          '\$${(summary['totalExpenses'] ?? 0).toStringAsFixed(0)}',
          Icons.receipt_long,
          const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 16),
        _buildFinancialCard(
          context,
          'Profit Margin',
          '${(summary['profitMargin'] ?? 0).toStringAsFixed(1)}%',
          Icons.analytics,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildFinancialCardsDesktop(BuildContext context, OperationsProvider provider) {
    final summary = provider.financialSummary;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                context,
                'Total Budget',
                '\$${(summary['totalBudget'] ?? 0).toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                const Color(0xFF37474F),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFinancialCard(
                context,
                'Actual Costs',
                '\$${(summary['totalActualCosts'] ?? 0).toStringAsFixed(0)}',
                Icons.trending_up,
                const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                context,
                'Total Expenses',
                '\$${(summary['totalExpenses'] ?? 0).toStringAsFixed(0)}',
                Icons.receipt_long,
                const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFinancialCard(
                context,
                'Profit Margin',
                '${(summary['profitMargin'] ?? 0).toStringAsFixed(1)}%',
                Icons.analytics,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animValue),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: ResponsiveLayout.getIconSize(context, base: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                          color: const Color(0xFF78909C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationalMetrics(BuildContext context, OperationsProvider provider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF37474F), Color(0xFF263238)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF37474F).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.work,
                          color: Colors.white,
                          size: ResponsiveLayout.getIconSize(context, base: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Operations Summary',
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 22),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  
                  if (ResponsiveLayout.isMobileLayout(context))
                    _buildOperationalCardsMobile(context, provider)
                  else
                    _buildOperationalCardsDesktop(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationalCardsMobile(BuildContext context, OperationsProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Active Projects',
                '${provider.activeProjects.length}',
                Icons.construction,
                const Color(0xFF37474F),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                context,
                'Completed',
                '${provider.projects.where((p) => p.status.name == 'completed').length}',
                Icons.check_circle,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          context,
          'Pending Approvals',
          '${provider.totalPendingApprovals}',
          Icons.pending,
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildOperationalCardsDesktop(BuildContext context, OperationsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Active Projects',
            '${provider.activeProjects.length}',
            Icons.construction,
            const Color(0xFF37474F),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            context,
            'Completed',
            '${provider.projects.where((p) => p.status.name == 'completed').length}',
            Icons.check_circle,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            context,
            'Pending Approvals',
            '${provider.totalPendingApprovals}',
            Icons.pending,
            const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: ResponsiveLayout.getIconSize(context, base: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 28),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                    color: const Color(0xFF78909C),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovalMetrics(BuildContext context, OperationsProvider provider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.pending_actions,
                          color: Colors.white,
                          size: ResponsiveLayout.getIconSize(context, base: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 22),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildApprovalCard(
                          context,
                          'Timesheets',
                          '${provider.pendingTimesheets.length}',
                          Icons.access_time,
                          const Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildApprovalCard(
                          context,
                          'Expenses',
                          '${provider.pendingExpenses.length}',
                          Icons.receipt,
                          const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovalCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: ResponsiveLayout.getIconSize(context, base: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                    color: const Color(0xFF78909C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStatus(BuildContext context, OperationsProvider provider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.pie_chart,
                          color: Colors.white,
                          size: ResponsiveLayout.getIconSize(context, base: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Project Distribution',
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 22),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  
                  if (provider.isLoadingProjects)
                    Container(
                      height: 200,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.projectError != null)
                    _buildErrorCard(provider.projectError!, provider.retryLoadProjects)
                  else if (provider.projects.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(provider),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No projects available',
                          style: TextStyle(
                            color: Color(0xFF78909C),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(OperationsProvider provider) {
    final projects = provider.projects;
    final statusCounts = <String, int>{};
    
    for (final project in projects) {
      statusCounts[project.status.name] = (statusCounts[project.status.name] ?? 0) + 1;
    }
    
    return statusCounts.entries.map((entry) {
      final status = entry.key;
      final count = entry.value;
      final percentage = (count / projects.length) * 100;
      
      Color color;
      switch (status) {
        case 'planning':
          color = const Color(0xFF9C27B0);
          break;
        case 'inProgress':
          color = const Color(0xFF37474F);
          break;
        case 'onHold':
          color = const Color(0xFFFF9800);
          break;
        case 'completed':
          color = const Color(0xFF10B981);
          break;
        case 'cancelled':
          color = const Color(0xFFEF4444);
          break;
        default:
          color = const Color(0xFF78909C);
      }
      
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
