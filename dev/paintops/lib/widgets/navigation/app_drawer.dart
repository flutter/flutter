import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/responsive_layout.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser!;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF37474F),
              Color(0xFF263238),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(user),
            Expanded(
              child: _buildMenuItems(context, authProvider),
            ),
            _buildFooter(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              backgroundColor: Colors.transparent,
              child: user.profileImageUrl == null
                  ? Text(
                      user.fullName.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              user.role.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, AuthProvider authProvider) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildMenuItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          onTap: () => Navigator.of(context).pop(),
        ),
        _buildMenuItem(
          icon: Icons.access_time,
          title: 'Timesheets',
          onTap: () => Navigator.of(context).pop(),
        ),
        _buildMenuItem(
          icon: Icons.work,
          title: 'Projects',
          onTap: () => Navigator.of(context).pop(),
        ),
        _buildMenuItem(
          icon: Icons.attach_money,
          title: 'Expenses',
          onTap: () => Navigator.of(context).pop(),
        ),
        const Divider(color: Colors.white24, height: 32),
        _buildMenuItem(
          icon: Icons.web,
          title: 'Landing Page',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/landing');
          },
        ),
        if (authProvider.canManageProjects()) ...{
          _buildMenuItem(
            icon: Icons.admin_panel_settings,
            title: 'Landing Admin',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/landing-admin');
            },
          ),
        },
        if (authProvider.canViewFinancials()) ...{
          const Divider(color: Colors.white24, height: 32),
          _buildMenuItem(
            icon: Icons.analytics,
            title: 'Financial Reports',
            onTap: () => _showComingSoon(context, 'Financial Reports'),
          ),
          _buildMenuItem(
            icon: Icons.assessment,
            title: 'Performance Metrics',
            onTap: () => _showComingSoon(context, 'Performance Metrics'),
          ),
        },
        if (authProvider.canManageProjects()) ...{
          const Divider(color: Colors.white24, height: 32),
          _buildMenuItem(
            icon: Icons.people,
            title: 'Team Management',
            onTap: () => _showComingSoon(context, 'Team Management'),
          ),
          _buildMenuItem(
            icon: Icons.inventory,
            title: 'Inventory',
            onTap: () => _showComingSoon(context, 'Inventory Management'),
          ),
        },
        const Divider(color: Colors.white24, height: 32),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () => _showComingSoon(context, 'Settings'),
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () => _showComingSoon(context, 'Help & Support'),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFB0BEC5).withOpacity(0.2),
                const Color(0xFF78909C).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFB0BEC5),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(color: Colors.white24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showLogoutDialog(context, authProvider);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'PaintOps v1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('$feature Coming Soon'),
        content: Text('$feature functionality is being developed and will be available in future updates.'),
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

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
