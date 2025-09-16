import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/operations_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project_model.dart';
import '../../utils/responsive_layout.dart';
import 'package:intl/intl.dart';

class ProjectManagement extends StatefulWidget {
  const ProjectManagement({super.key});

  @override
  State<ProjectManagement> createState() => _ProjectManagementState();
}

class _ProjectManagementState extends State<ProjectManagement> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OperationsProvider>(context, listen: false);
      provider.loadProjects();
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
      child: SingleChildScrollView(
        padding: ResponsiveLayout.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
            
            if (operationsProvider.isLoadingProjects)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (operationsProvider.projects.isEmpty)
              _buildEmptyState()
            else
              _buildProjectsList(operationsProvider, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF263238)],
              ),
              borderRadius: BorderRadius.circular(16),
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
                  'Project Management',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track progress, budgets, and timelines',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(OperationsProvider provider, AuthProvider authProvider) {
    final projects = provider.projects;
    
    return Column(
      children: [
        if (ResponsiveLayout.isMobileLayout(context))
          _buildProjectListMobile(projects, authProvider)
        else
          _buildProjectGrid(projects, authProvider),
      ],
    );
  }

  Widget _buildProjectListMobile(List<ProjectModel> projects, AuthProvider authProvider) {
    return Column(
      children: projects.map((project) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: _buildProjectCard(project, authProvider),
        );
      }).toList(),
    );
  }

  Widget _buildProjectGrid(List<ProjectModel> projects, AuthProvider authProvider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isDesktopLayout(context) ? 2 : 1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: ResponsiveLayout.isDesktopLayout(context) ? 1.3 : 0.8,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _buildProjectCard(projects[index], authProvider);
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project, AuthProvider authProvider) {
    return Container(
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
          // Project image
          if (project.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: project.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF8F9FA),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF8F9FA),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Color(0xFF78909C),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
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
                          colors: [
                            project.status.color,
                            project.status.color.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: project.status.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        project.status.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Client info
                if (project.clientName != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 18,
                          color: const Color(0xFF78909C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.clientName!,
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

                const SizedBox(height: 16),

                // Project dates
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                              color: const Color(0xFF78909C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(project.startDate),
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF37474F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (project.endDate != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                                color: const Color(0xFF78909C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, yyyy').format(project.endDate!),
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                                fontWeight: FontWeight.bold,
                                color: project.isOverdue 
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF37474F),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (authProvider.canViewFinancials()) ...{
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Financial info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                                color: const Color(0xFF78909C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${project.budgetAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF37474F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actual Cost',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                                color: const Color(0xFF78909C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${project.actualCosts.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                                fontWeight: FontWeight.bold,
                                color: project.isOnBudget 
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Margin',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                                color: const Color(0xFF78909C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${project.profitMargin.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                                fontWeight: FontWeight.bold,
                                color: project.profitMargin >= 0 
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                },

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF37474F), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () => _showProjectDetails(project),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF37474F),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    
                    if (authProvider.canManageProjects()) ...{
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF37474F), Color(0xFF263238)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF37474F).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _showEditProjectDialog(project),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    },
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
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
          Icon(
            Icons.work_outline,
            size: ResponsiveLayout.getIconSize(context, base: 64),
            color: const Color(0xFF78909C),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          Text(
            'No Projects Available',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Projects will appear here once they are created',
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

  void _showProjectDetails(ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isMobileLayout(context) ? double.infinity : 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              if (project.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: project.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF8F9FA),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF8F9FA),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF37474F),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  project.status.color,
                                  project.status.color.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              project.status.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (project.description != null && project.description!.isNotEmpty) ...{
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            project.description!,
                            style: const TextStyle(
                              color: Color(0xFF37474F),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      },

                      if (project.clientName != null) ...{
                        const Text(
                          'Client Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.clientName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                              if (project.clientEmail != null) ...{
                                const SizedBox(height: 4),
                                Text(
                                  project.clientEmail!,
                                  style: const TextStyle(
                                    color: Color(0xFF78909C),
                                  ),
                                ),
                              },
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      },

                      // Project timeline and financial details...
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF37474F),
                          side: const BorderSide(color: Color(0xFF37474F)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showEditProjectDialog(project);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37474F),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Edit Project'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProjectDialog(ProjectModel project) {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(text: project.description);
    final budgetController = TextEditingController(text: project.budgetAmount.toString());
    ProjectStatus selectedStatus = project.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Edit Project'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) => DropdownButtonFormField<ProjectStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Project Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ProjectStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update project with new values
              final updatedProject = project.copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                budgetAmount: double.tryParse(budgetController.text) ?? project.budgetAmount,
                status: selectedStatus,
              );
              
              // Update in repository
              final provider = Provider.of<OperationsProvider>(context, listen: false);
              // Here you would call provider.updateProject(updatedProject)
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Project updated successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
