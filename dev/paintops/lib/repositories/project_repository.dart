import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('''
            *,
            clients (
              name,
              email
            )
          ''')
          .order('created_at', ascending: false);

      return (response as List).map((project) {
        return ProjectModel(
          id: project['id'] ?? '',
          name: project['name'] ?? '',
          clientName: project['clients']?['name'] ?? 'Unknown Client',
          clientEmail: project['clients']?['email'] ?? '',
          status: _parseProjectStatus(project['status']),
          budgetAmount: (project['budget_amount'] ?? 0.0).toDouble(),
          actualCosts: (project['actual_costs'] ?? 0.0).toDouble(),
          startDate: DateTime.tryParse(project['start_date'] ?? '') ?? DateTime.now(),
          endDate: DateTime.tryParse(project['end_date'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
          description: project['description'] ?? '',
          imageUrl: project['image_url'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading projects: $e');
      }
      throw Exception('Failed to load projects: $e');
    }
  }

  Future<ProjectModel?> getProject(String id) async {
    try {
      final response = await _supabase
          .from('projects')
          .select('''
            *,
            clients (
              name,
              email
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return ProjectModel(
          id: response['id'] ?? '',
          name: response['name'] ?? '',
          clientName: response['clients']?['name'] ?? 'Unknown Client',
          clientEmail: response['clients']?['email'] ?? '',
          status: _parseProjectStatus(response['status']),
          budgetAmount: (response['budget_amount'] ?? 0.0).toDouble(),
          actualCosts: (response['actual_costs'] ?? 0.0).toDouble(),
          startDate: DateTime.tryParse(response['start_date'] ?? '') ?? DateTime.now(),
          endDate: DateTime.tryParse(response['end_date'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
          description: response['description'] ?? '',
          imageUrl: response['image_url'],
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading project: $e');
      }
      return null;
    }
  }

  Future<bool> createProject(ProjectModel project, {String? clientName, String? clientEmail}) async {
    try {
      String? clientId;

      // Create or find client if provided
      if (clientName != null && clientName.isNotEmpty) {
        // Check if client exists
        final existingClient = await _supabase
            .from('clients')
            .select()
            .eq('name', clientName)
            .maybeSingle();

        if (existingClient != null) {
          clientId = existingClient['id'];
        } else {
          // Create new client
          final clientData = {
            'name': clientName,
            'email': clientEmail,
            'created_at': DateTime.now().toIso8601String(),
          };
          final clientResponse = await _supabase
              .from('clients')
              .insert(clientData)
              .select()
              .single();
          clientId = clientResponse['id'];
        }
      }

      final data = {
        'name': project.name,
        'client_id': clientId,
        'description': project.description,
        'status': project.status.name.toLowerCase(),
        'budget_amount': project.budgetAmount,
        'actual_costs': project.actualCosts,
        'start_date': project.startDate.toIso8601String().split('T')[0],
        'end_date': project.endDate?.toIso8601String().split('T')[0],
        'image_url': project.imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('projects').insert(data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating project: $e');
      }
      return false;
    }
  }

  Future<bool> updateProject(ProjectModel project, {String? clientName, String? clientEmail}) async {
    try {
      String? clientId;

      // Update or create client if provided
      if (clientName != null && clientName.isNotEmpty) {
        final existingClient = await _supabase
            .from('clients')
            .select()
            .eq('name', clientName)
            .maybeSingle();

        if (existingClient != null) {
          clientId = existingClient['id'];
          // Update client email if provided
          if (clientEmail != null && clientEmail != existingClient['email']) {
            await _supabase
                .from('clients')
                .update({'email': clientEmail})
                .eq('id', clientId!);
          }
        } else {
          // Create new client
          final clientData = {
            'name': clientName,
            'email': clientEmail,
            'created_at': DateTime.now().toIso8601String(),
          };
          final clientResponse = await _supabase
              .from('clients')
              .insert(clientData)
              .select()
              .single();
          clientId = clientResponse['id'];
        }
      }

      final data = {
        'name': project.name,
        'client_id': clientId,
        'description': project.description,
        'status': project.status.name.toLowerCase(),
        'budget_amount': project.budgetAmount,
        'actual_costs': project.actualCosts,
        'start_date': project.startDate.toIso8601String().split('T')[0],
        'end_date': project.endDate?.toIso8601String().split('T')[0],
        'image_url': project.imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('projects')
          .update(data)
          .eq('id', project.id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating project: $e');
      }
      return false;
    }
  }

  Future<bool> updateProjectCosts(String projectId, double actualCosts) async {
    try {
      await _supabase
          .from('projects')
          .update({
            'actual_costs': actualCosts,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', projectId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating project costs: $e');
      }
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      await _supabase
          .from('projects')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting project: $e');
      }
      return false;
    }
  }

  Future<Map<String, double>> getFinancialSummary() async {
    try {
      final projects = await getProjects();
      
      final totalBudget = projects.fold(0.0, (sum, project) => sum + project.budgetAmount);
      final totalActualCosts = projects.fold(0.0, (sum, project) => sum + project.actualCosts);
      final activeProjectsBudget = projects
          .where((p) => p.status == ProjectStatus.inProgress)
          .fold(0.0, (sum, project) => sum + project.budgetAmount);
      final completedProjectsRevenue = projects
          .where((p) => p.status == ProjectStatus.completed)
          .fold(0.0, (sum, project) => sum + project.budgetAmount);
      
      final profitMargin = totalBudget > 0 ? ((totalBudget - totalActualCosts) / totalBudget) * 100 : 0.0;
      
      return {
        'totalBudget': totalBudget,
        'totalActualCosts': totalActualCosts,
        'profitMargin': profitMargin.toDouble(),
        'activeProjectsBudget': activeProjectsBudget,
        'completedProjectsRevenue': completedProjectsRevenue,
        'projectCount': projects.length.toDouble(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading financial summary: $e');
      }
      return {
        'totalBudget': 0,
        'totalActualCosts': 0,
        'profitMargin': 0,
        'activeProjectsBudget': 0,
        'completedProjectsRevenue': 0,
        'projectCount': 0,
      };
    }
  }

  Future<Map<String, int>> getOperationalMetrics() async {
    try {
      final projects = await getProjects();
      final now = DateTime.now();
      
      final activeProjects = projects.where((p) => p.status == ProjectStatus.inProgress).length;
      final completedProjects = projects.where((p) => p.status == ProjectStatus.completed).length;
      final overdueProjects = projects.where((p) => 
          p.endDate != null && 
          p.endDate!.isBefore(now) && 
          p.status != ProjectStatus.completed
      ).length;
      final planningProjects = projects.where((p) => p.status == ProjectStatus.planning).length;
      final onHoldProjects = projects.where((p) => p.status == ProjectStatus.onHold).length;
      
      return {
        'totalProjects': projects.length,
        'activeProjects': activeProjects,
        'completedProjects': completedProjects,
        'overdueProjects': overdueProjects,
        'planningProjects': planningProjects,
        'onHoldProjects': onHoldProjects,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading operational metrics: $e');
      }
      return {
        'totalProjects': 0,
        'activeProjects': 0,
        'completedProjects': 0,
        'overdueProjects': 0,
        'planningProjects': 0,
        'onHoldProjects': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsForCalendar() async {
    try {
      final projects = await _supabase
          .from('projects')
          .select('id, name, start_date, end_date, status')
          .not('start_date', 'is', null);

      return List<Map<String, dynamic>>.from(projects);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading projects for calendar: $e');
      }
      return [];
    }
  }

  Future<String?> uploadProjectImage(String projectId, List<int> imageBytes, String fileName) async {
    try {
      final filePath = 'projects/$projectId/$fileName';
      
      if (kIsWeb) {
        // Web-specific image upload handling
        await _supabase.storage
            .from('project-images')
            .uploadBinary(
              filePath,
              Uint8List.fromList(imageBytes),
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: 'auto', // Let Supabase detect content type
              ),
            );
      } else {
        // Mobile-specific image upload handling
        await _supabase.storage
            .from('project-images')
            .uploadBinary(
              filePath,
              Uint8List.fromList(imageBytes),
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      }

      final imageUrl = _supabase.storage
          .from('project-images')
          .getPublicUrl(filePath);

      // Update project with image URL
      await _supabase
          .from('projects')
          .update({'image_url': imageUrl})
          .eq('id', projectId);

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading project image: $e');
      }
      return null;
    }
  }

  // Platform-specific image handling helpers
  Future<List<int>?> _processImageForPlatform(List<int> imageBytes) async {
    if (kIsWeb) {
      // Web-specific image processing
      // Could add image compression or validation here
      return imageBytes;
    } else {
      // Mobile-specific image processing
      // Could add different compression settings for mobile
      return imageBytes;
    }
  }

  ProjectStatus _parseProjectStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
      case 'in-progress':
      case 'active':
        return ProjectStatus.inProgress;
      case 'completed':
        return ProjectStatus.completed;
      case 'onhold':
      case 'on_hold':
      case 'on-hold':
        return ProjectStatus.onHold;
      case 'planning':
        return ProjectStatus.planning;
      default:
        return ProjectStatus.planning;
    }
  }
}
