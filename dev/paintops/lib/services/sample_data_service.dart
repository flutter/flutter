import 'dart:math';
import '../models/project_model.dart';
import '../models/timesheet_model.dart';
import '../models/expense_model.dart';

class SampleDataService {
  static final Random _random = Random();

  // Perth-specific locations and streets
  static const List<String> perthLocations = [
    'Kings Park',
    'Fremantle',
    'Subiaco',
    'Cottesloe',
    'Perth CBD',
    'Northbridge',
    'Mount Lawley',
    'Scarborough',
    'Joondalup',
    'Rockingham',
    'Mandurah',
    'Midland',
    'Armadale',
    'Cannington',
    'Morley',
  ];

  static const List<String> perthStreets = [
    'Hay Street',
    'Murray Street',
    'St Georges Terrace',
    'William Street',
    'Barrack Street',
    'King Street',
    'Adelaide Terrace',
    'Wellington Street',
    'Beaufort Street',
    'Oxford Street',
    'Rokeby Road',
    'Canning Highway',
    'Great Eastern Highway',
    'Stirling Highway',
    'Wanneroo Road',
  ];

  // Australian painter names
  static const List<String> painterNames = [
    'Jack Thompson',
    'Emma Wilson',
    'Liam Anderson',
    'Sophie Clarke',
    'Noah Mitchell',
    'Isabella Brown',
    'Oliver Davis',
    'Mia Taylor',
    'William Johnson',
    'Charlotte White',
    'James Martin',
    'Amelia Garcia',
    'Benjamin Lee',
    'Harper Rodriguez',
    'Lucas Walker',
  ];

  // Australian painting suppliers and brands
  static const List<String> suppliers = [
    'Bunnings Warehouse',
    'Dulux Australia',
    'British Paints',
    'Taubmans',
    'Resene Paints',
    'Feast Watson',
    'Porter\'s Paints',
    'Wattyl Paints',
    'Haymes Paint',
    'Solver Paints',
    'Masters Home Improvement',
    'Paint Spot',
    'Trade Tools & Hardware',
    'Perth Paint Centre',
    'City Paint Supplies',
  ];

  // Client company names for Perth area
  static const List<String> clientNames = [
    'Perth Property Group',
    'Swan River Developments',
    'Fremantle Holdings Pty Ltd',
    'Kings Park Real Estate',
    'Cottesloe Commercial Properties',
    'Subiaco Business Centre',
    'Perth CBD Management',
    'Western Australia Housing',
    'Scarborough Beach Resort',
    'Joondalup Shopping Centre',
    'Rockingham Industrial Park',
    'Mount Lawley Residences',
    'Perth City Council',
    'Northbridge Cultural Centre',
    'Midland Gate Shopping Centre',
  ];

  static List<ProjectModel> generateSampleProjects() {
    final List<ProjectModel> projects = [];
    
    for (int i = 0; i < 12; i++) {
      final location = perthLocations[_random.nextInt(perthLocations.length)];
      final street = perthStreets[_random.nextInt(perthStreets.length)];
      final clientName = clientNames[_random.nextInt(clientNames.length)];
      final projectTypes = ['Interior Painting', 'Exterior Painting', 'Commercial Painting', 'Residential Renovation'];
      final projectType = projectTypes[_random.nextInt(projectTypes.length)];
      
      final startDate = DateTime.now().subtract(Duration(days: _random.nextInt(180) + 30));
      final duration = _random.nextInt(60) + 14; // 14-74 days
      final endDate = startDate.add(Duration(days: duration));
      
      final budget = 5000 + _random.nextInt(45000).toDouble(); // $5,000 - $50,000
      final actualCosts = budget * (0.7 + _random.nextDouble() * 0.6); // 70-130% of budget
      
      projects.add(ProjectModel(
        id: 'project_${i + 1}',
        name: '$projectType - $location',
        clientName: clientName,
        clientEmail: '${clientName.toLowerCase().replaceAll(' ', '').replaceAll('\'', '')}@example.com',
        status: _getRandomProjectStatus(),
        budgetAmount: budget,
        actualCosts: actualCosts,
        startDate: startDate,
        endDate: endDate,
        description: 'Professional $projectType project located at ${_random.nextInt(999) + 1} $street, $location. '
                    'Includes preparation, priming, and application of high-quality paint systems.',
        imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=800&h=600&fit=crop',
      ));
    }
    
    return projects;
  }

  static List<TimesheetModel> generateSampleTimesheets(List<ProjectModel> projects) {
    final List<TimesheetModel> timesheets = [];
    
    for (final project in projects.take(8)) {
      // Generate 3-5 timesheets per project
      final timesheetCount = 3 + _random.nextInt(3);
      
      for (int i = 0; i < timesheetCount; i++) {
        final workerName = painterNames[_random.nextInt(painterNames.length)];
        final workDate = project.startDate.add(Duration(days: i * 2 + _random.nextInt(3)));
        final startHour = 7 + _random.nextInt(3); // 7-9 AM start
        final workDuration = 6 + _random.nextInt(4); // 6-9 hours
        
        final startTime = DateTime(workDate.year, workDate.month, workDate.day, startHour, 0);
        final endTime = startTime.add(Duration(hours: workDuration));
        
        final descriptions = [
          'Surface preparation and priming',
          'First coat application',
          'Second coat application',
          'Detail work and touch-ups',
          'Clean-up and site preparation',
          'Quality inspection and corrections',
        ];
        
        timesheets.add(TimesheetModel(
          id: 'timesheet_${project.id}_$i',
          projectId: project.id,
          projectName: project.name,
          workerId: 'worker_${workerName.hashCode}',
          workerName: workerName,
          startTime: startTime,
          endTime: endTime,
          description: descriptions[_random.nextInt(descriptions.length)],
          isApproved: _random.nextBool(),
          approvedBy: _random.nextBool() ? 'Sarah Mitchell' : null,
          approvedAt: _random.nextBool() ? workDate.add(Duration(days: 1)) : null,
        ));
      }
    }
    
    return timesheets;
  }

  static List<ExpenseModel> generateSampleExpenses(List<ProjectModel> projects) {
    final List<ExpenseModel> expenses = [];
    
    for (final project in projects.take(10)) {
      // Generate 2-4 expenses per project
      final expenseCount = 2 + _random.nextInt(3);
      
      for (int i = 0; i < expenseCount; i++) {
        final supplier = suppliers[_random.nextInt(suppliers.length)];
        final category = ExpenseCategory.values[_random.nextInt(ExpenseCategory.values.length)];
        final expenseDate = project.startDate.add(Duration(days: _random.nextInt(30)));
        
        double amount;
        String description;
        
        switch (category) {
          case ExpenseCategory.materials:
            amount = 150 + _random.nextInt(800).toDouble();
            description = 'Paint, brushes, rollers, and application materials';
            break;
          case ExpenseCategory.equipment:
            amount = 200 + _random.nextInt(1200).toDouble();
            description = 'Spray equipment, ladders, and power tools rental';
            break;
          case ExpenseCategory.transportation:
            amount = 50 + _random.nextInt(300).toDouble();
            description = 'Vehicle fuel and transportation costs';
            break;
          case ExpenseCategory.subcontractor:
            amount = 500 + _random.nextInt(2000).toDouble();
            description = 'Specialized coating application services';
            break;
          case ExpenseCategory.permits:
            amount = 100 + _random.nextInt(500).toDouble();
            description = 'Council permits and inspection fees';
            break;
          case ExpenseCategory.other:
            amount = 80 + _random.nextInt(400).toDouble();
            description = 'Miscellaneous project expenses';
            break;
        }
        
        expenses.add(ExpenseModel(
          id: 'expense_${project.id}_$i',
          projectId: project.id,
          projectName: project.name,
          supplier: supplier,
          amount: amount,
          category: category,
          description: description,
          date: expenseDate,
          isApproved: _random.nextBool(),
          approvedBy: _random.nextBool() ? 'Michael Roberts' : null,
          approvedAt: _random.nextBool() ? expenseDate.add(Duration(days: 1)) : null,
          receiptImageUrl: _random.nextBool() ? 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&h=300&fit=crop' : null,
        ));
      }
    }
    
    return expenses;
  }

  static ProjectStatus _getRandomProjectStatus() {
    final statuses = [
      ProjectStatus.planning,
      ProjectStatus.inProgress,
      ProjectStatus.inProgress, // More in-progress projects
      ProjectStatus.inProgress,
      ProjectStatus.completed,
      ProjectStatus.onHold,
    ];
    return statuses[_random.nextInt(statuses.length)];
  }

  // Method to get all sample data at once
  static Map<String, dynamic> getAllSampleData() {
    final projects = generateSampleProjects();
    final timesheets = generateSampleTimesheets(projects);
    final expenses = generateSampleExpenses(projects);
    
    return {
      'projects': projects,
      'timesheets': timesheets,
      'expenses': expenses,
    };
  }
}
