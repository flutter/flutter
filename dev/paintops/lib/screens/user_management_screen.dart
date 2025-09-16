import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_management_provider.dart';
import '../widgets/user_management/user_list.dart';
import '../widgets/user_management/add_user_dialog.dart';
import '../utils/responsive_layout.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final provider = Provider.of<UserManagementProvider>(context, listen: false);
    provider.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<UserManagementProvider>(context, listen: false);
              provider.refreshUsers();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Users', icon: Icon(Icons.people)),
            Tab(text: 'Active', icon: Icon(Icons.person)),
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
                _buildAllUsersTab(),
                _buildActiveUsersTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
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
          hintText: 'Search users by name, email, or role...',
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

  Widget _buildAllUsersTab() {
    return Consumer<UserManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refreshUsers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final users = _searchQuery.isEmpty 
            ? provider.users 
            : provider.searchUsers(_searchQuery);

        return UserList(
          users: users,
          onUserTap: _showUserDetails,
          onStatusToggle: _toggleUserStatus,
          onDeleteUser: _confirmDeleteUser,
        );
      },
    );
  }

  Widget _buildActiveUsersTab() {
    return Consumer<UserManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = _searchQuery.isEmpty 
            ? provider.activeUsers 
            : provider.searchUsers(_searchQuery).where((u) => u.isActive).toList();

        return UserList(
          users: users,
          onUserTap: _showUserDetails,
          onStatusToggle: _toggleUserStatus,
          onDeleteUser: _confirmDeleteUser,
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<UserManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = provider.userMetrics;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildMetricsGrid(metrics, provider),
              
              const SizedBox(height: 24),
              
              Text(
                'Role Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildRoleCards(provider),
              
              const SizedBox(height: 24),
              
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildRecentActivity(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(Map<String, int> metrics, UserManagementProvider provider) {
    final metricCards = [
      {'title': 'Total Users', 'value': metrics['totalUsers'] ?? 0, 'color': 0xFF2196F3},
      {'title': 'Active Users', 'value': metrics['activeUsers'] ?? 0, 'color': 0xFF4CAF50},
      {'title': 'Inactive Users', 'value': metrics['inactiveUsers'] ?? 0, 'color': 0xFFF44336},
      {'title': 'Average Rate', 'value': '\$${provider.averageHourlyRate.toStringAsFixed(2)}', 'color': 0xFF9C27B0},
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
      itemCount: metricCards.length,
      itemBuilder: (context, index) {
        final card = metricCards[index];
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
                  _getMetricIcon(card['title'] as String),
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

  IconData _getMetricIcon(String title) {
    switch (title) {
      case 'Total Users':
        return Icons.people;
      case 'Active Users':
        return Icons.person;
      case 'Inactive Users':
        return Icons.person_off;
      case 'Average Rate':
        return Icons.attach_money;
      default:
        return Icons.analytics;
    }
  }

  Widget _buildRoleCards(UserManagementProvider provider) {
    final roles = [
      {'role': 'CEOs', 'count': provider.ceos.length, 'color': 0xFF9C27B0, 'icon': Icons.business_center},
      {'role': 'Supervisors', 'count': provider.supervisors.length, 'color': 0xFF2196F3, 'icon': Icons.supervisor_account},
      {'role': 'Painters', 'count': provider.painters.length, 'color': 0xFF4CAF50, 'icon': Icons.palette},
    ];

    return Row(
      children: roles.map((role) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(role['color'] as int).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(role['color'] as int).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  role['icon'] as IconData,
                  color: Color(role['color'] as int),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  (role['count'] as int).toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(role['color'] as int),
                  ),
                ),
                Text(
                  role['role'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity(UserManagementProvider provider) {
    final newHires = provider.getNewHires();
    
    if (newHires.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No new hires in the last 30 days'),
        ),
      );
    }

    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: newHires.length,
        itemBuilder: (context, index) {
          final user = newHires[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF37474F),
              child: Text(
                user.initials,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.fullName),
            subtitle: Text('${user.role.displayName} • Hired ${user.hireDate != null ? '${DateTime.now().difference(user.hireDate!).inDays} days ago' : 'Recently'}'),
            trailing: const Icon(Icons.new_releases, color: Colors.green),
          );
        },
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onUserAdded: () => _loadUsers(),
      ),
    );
  }

  void _showUserDetails(user) {
    // TODO: Implement user details dialog
    print('Show user details for: ${user.fullName}');
  }

  Future<void> _toggleUserStatus(user) async {
    final provider = Provider.of<UserManagementProvider>(context, listen: false);
    final success = await provider.updateUserStatus(user.id, !user.isActive);
    
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update user status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteUser(user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<UserManagementProvider>(context, listen: false);
      final success = await provider.deleteUser(user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'User deleted successfully' 
                : 'Failed to delete user'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
