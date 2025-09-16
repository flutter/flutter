import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/operations_provider.dart';
import '../widgets/projects/enhanced_project_management.dart';
import '../utils/responsive_layout.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final provider = Provider.of<OperationsProvider>(context, listen: false);
    provider.loadProjects();
    provider.loadFinancialSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<OperationsProvider>(context, listen: false);
              provider.refreshAllData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: ResponsiveLayout.isMobileLayout(context),
          tabs: const [
            Tab(text: 'All Projects', icon: Icon(Icons.work)),
            Tab(text: 'Active', icon: Icon(Icons.play_arrow)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                EnhancedProjectManagement(searchQuery: _searchQuery),
                _buildActiveProjectsTab(),
                _buildCompletedProjectsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9ECEF)),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search projects by name, client, or status...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildActiveProjectsTab() {
    return Consumer<OperationsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingProjects) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeProjects = provider.activeProjects
            .where((project) => _searchQuery.isEmpty || 
                project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                project.clientName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (activeProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No active projects' : 'No active projects match your search',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeProjects.length,
          itemBuilder: (context, index) {
            final project = activeProjects[index];
            return _buildProjectCard(project, isActive: true);
          },
        );
      },
    );
  }

  Widget _buildCompletedProjectsTab() {
    return Consumer<OperationsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingProjects) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedProjects = provider.projects
            .where((p) => p.status.name == 'completed')
            .where((project) => _searchQuery.isEmpty || 
                project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                project.clientName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (completedProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No completed projects' : 'No completed projects match your search',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedProjects.length,
          itemBuilder: (context, index) {
            final project = completedProjects[index];
            return _buildProjectCard(project, isCompleted: true);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<OperationsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingProjects || provider.isLoadingMetrics) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = provider.operationalMetrics;
        final financials = provider.financialSummary;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildAnalyticsGrid(metrics, financials),
              
              const SizedBox(height: 24),
              
              Text(
                'Financial Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildFinancialCards(financials),
              
              const SizedBox(height: 24),
              
              Text(
                'Project Status Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildStatusCards(metrics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(project, {bool isActive = false, bool isCompleted = false}) {
    final progress = project.budgetAmount > 0 
        ? (project.actualCosts / project.budgetAmount) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.clientName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green.withOpacity(0.1)
                          : isActive 
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      project.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted 
                            ? Colors.green
                            : isActive 
                                ? Colors.blue
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '\$${project.budgetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spent',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '\$${project.actualCosts.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: progress > 100 ? Colors.red : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${progress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: progress > 100 ? Colors.red : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          color: progress > 100 ? Colors.red : Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (project.description.isNotEmpty) ...{
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid(Map<String, int> metrics, Map<String, double> financials) {
    final cards = [
      {
        'title': 'Total Projects',
        'value': metrics['totalProjects'] ?? 0,
        'color': 0xFF2196F3,
        'icon': Icons.work
      },
      {
        'title': 'Active',
        'value': metrics['activeProjects'] ?? 0,
        'color': 0xFF4CAF50,
        'icon': Icons.play_arrow
      },
      {
        'title': 'Completed',
        'value': metrics['completedProjects'] ?? 0,
        'color': 0xFF9C27B0,
        'icon': Icons.check_circle
      },
      {
        'title': 'Overdue',
        'value': metrics['overdueProjects'] ?? 0,
        'color': 0xFFF44336,
        'icon': Icons.warning
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isMobileLayout(context) ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(card['color'] as int).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  card['icon'] as IconData,
                  color: Color(card['color'] as int),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card['value'].toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                card['title'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialCards(Map<String, double> financials) {
    return Row(
      children: [
        Expanded(
          child: _buildFinancialCard(
            'Total Budget',
            '\$${(financials['totalBudget'] ?? 0).toStringAsFixed(2)}',
            Colors.blue,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFinancialCard(
            'Total Costs',
            '\$${(financials['totalActualCosts'] ?? 0).toStringAsFixed(2)}',
            Colors.orange,
            Icons.receipt_long,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFinancialCard(
            'Profit Margin',
            '${(financials['profitMargin'] ?? 0).toStringAsFixed(1)}%',
            (financials['profitMargin'] ?? 0) >= 0 ? Colors.green : Colors.red,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(Map<String, int> metrics) {
    final statuses = [
      {'status': 'Planning', 'count': metrics['planningProjects'] ?? 0, 'color': 0xFFFF9800, 'icon': Icons.schedule},
      {'status': 'In Progress', 'count': metrics['activeProjects'] ?? 0, 'color': 0xFF2196F3, 'icon': Icons.play_arrow},
      {'status': 'On Hold', 'count': metrics['onHoldProjects'] ?? 0, 'color': 0xFF9C27B0, 'icon': Icons.pause},
      {'status': 'Completed', 'count': metrics['completedProjects'] ?? 0, 'color': 0xFF4CAF50, 'icon': Icons.check_circle},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isMobileLayout(context) ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        return Container(
          decoration: BoxDecoration(
            color: Color(status['color'] as int).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(status['color'] as int).withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: Main
