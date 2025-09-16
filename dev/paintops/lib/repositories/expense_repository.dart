import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ExpenseModel>> getExpenses({String? projectId}) async {
    try {
      var query = _supabase
          .from('expenses')
          .select('''
            *,
            projects (
              name
            )
          ''');

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((expense) {
        return ExpenseModel(
          id: expense['id'] ?? '',
          projectId: expense['project_id'] ?? '',
          projectName: expense['projects']?['name'] ?? 'Unknown Project',
          supplier: expense['supplier'] ?? '',
          amount: (expense['amount'] ?? 0).toDouble(),
          category: _parseExpenseCategory(expense['category']),
          description: expense['description'] ?? '',
          date: DateTime.tryParse(expense['date'] ?? '') ?? DateTime.now(),
          isApproved: expense['is_approved'] ?? false,
          approvedBy: expense['approved_by'],
          approvedAt: expense['approved_at'] != null 
              ? DateTime.tryParse(expense['approved_at']) 
              : null,
          receiptImageUrl: expense['receipt_image_url'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expenses: $e');
      }
      throw Exception('Failed to load expenses: $e');
    }
  }

  Future<List<ExpenseModel>> getExpensesForDateRange(DateTime startDate, DateTime endDate, {String? projectId}) async {
    try {
      var query = _supabase
          .from('expenses')
          .select('''
            *,
            projects (
              name
            )
          ''')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((expense) {
        return ExpenseModel(
          id: expense['id'] ?? '',
          projectId: expense['project_id'] ?? '',
          projectName: expense['projects']?['name'] ?? 'Unknown Project',
          supplier: expense['supplier'] ?? '',
          amount: (expense['amount'] ?? 0).toDouble(),
          category: _parseExpenseCategory(expense['category']),
          description: expense['description'] ?? '',
          date: DateTime.tryParse(expense['date'] ?? '') ?? DateTime.now(),
          isApproved: expense['is_approved'] ?? false,
          approvedBy: expense['approved_by'],
          approvedAt: expense['approved_at'] != null 
              ? DateTime.tryParse(expense['approved_at']) 
              : null,
          receiptImageUrl: expense['receipt_image_url'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expenses for date range: $e');
      }
      return [];
    }
  }

  Future<bool> submitExpense(ExpenseModel expense) async {
    try {
      final data = {
        'project_id': expense.projectId,
        'supplier': expense.supplier,
        'amount': expense.amount,
        'category': expense.category.name,
        'description': expense.description,
        'date': expense.date.toIso8601String().split('T')[0],
        'is_approved': false,
        'receipt_image_url': expense.receiptImageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('expenses').insert(data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting expense: $e');
      }
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    try {
      final data = {
        'project_id': expense.projectId,
        'supplier': expense.supplier,
        'amount': expense.amount,
        'category': expense.category.name,
        'description': expense.description,
        'date': expense.date.toIso8601String().split('T')[0],
        'receipt_image_url': expense.receiptImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('expenses')
          .update(data)
          .eq('id', expense.id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating expense: $e');
      }
      return false;
    }
  }

  Future<bool> approveExpense(String expenseId, String approvedBy) async {
    try {
      await _supabase
          .from('expenses')
          .update({
            'is_approved': true,
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving expense: $e');
      }
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting expense: $e');
      }
      return false;
    }
  }

  Future<Map<String, double>> getExpenseSummary() async {
    try {
      final expenses = await getExpenses();
      final approvedExpenses = expenses.where((e) => e.isApproved);
      final pendingExpenses = expenses.where((e) => !e.isApproved);
      final monthlyExpenses = expenses.where((e) => 
          e.date.isAfter(DateTime.now().subtract(const Duration(days: 30))));

      final totalApproved = approvedExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalPending = pendingExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final monthlyTotal = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final avgAmount = expenses.isNotEmpty ? (expenses.fold(0.0, (sum, e) => sum + e.amount) / expenses.length).toDouble() : 0.0;

      final categoryTotals = <String, double>{};
      for (final category in ExpenseCategory.values) {
        categoryTotals['expensesByCategory_${category.name}'] = 
            approvedExpenses.where((e) => e.category == category).fold(0.0, (sum, e) => sum + e.amount);
      }

      return {
        'totalExpenses': totalApproved,
        'pendingExpenses': totalPending,
        'totalApprovedExpenses': totalApproved,
        'totalPendingExpenses': totalPending,
        'avgExpenseAmount': avgAmount,
        'monthlyExpenses': monthlyTotal,
        ...categoryTotals,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expense summary: $e');
      }
      return {
        'totalExpenses': 0,
        'pendingExpenses': 0,
        'totalApprovedExpenses': 0,
        'totalPendingExpenses': 0,
        'avgExpenseAmount': 0,
        'monthlyExpenses': 0,
      };
    }
  }

  Future<Map<String, int>> getExpenseMetrics() async {
    try {
      final expenses = await getExpenses();
      
      final pendingExpenses = expenses.where((e) => !e.isApproved).length;
      final approvedExpenses = expenses.where((e) => e.isApproved).length;
      final thisWeekExpenses = expenses.where((e) => 
          e.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).length;
      final thisMonthExpenses = expenses.where((e) => 
          e.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))
      ).length;
      
      return {
        'totalExpenses': expenses.length,
        'pendingExpenseApprovals': pendingExpenses,
        'approvedExpenses': approvedExpenses,
        'thisWeekExpenses': thisWeekExpenses,
        'thisMonthExpenses': thisMonthExpenses,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expense metrics: $e');
      }
      return {
        'totalExpenses': 0,
        'pendingExpenseApprovals': 0,
        'approvedExpenses': 0,
        'thisWeekExpenses': 0,
        'thisMonthExpenses': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    try {
      final expenses = await getExpenses();
      final approvedExpenses = expenses.where((e) => e.isApproved);
      
      final categoryData = <Map<String, dynamic>>[];
      
      for (final category in ExpenseCategory.values) {
        final categoryExpenses = approvedExpenses.where((e) => e.category == category);
        final total = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final count = categoryExpenses.length;
        
        categoryData.add({
          'category': category.displayName,
          'total': total,
          'count': count,
          'color': category.color,
          'icon': category.icon,
        });
      }
      
      return categoryData;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expenses by category: $e');
      }
      return [];
    }
  }

  Future<String?> uploadReceiptImage(String expenseId, List<int> imageBytes, String fileName) async {
    try {
      final filePath = 'receipts/$expenseId/$fileName';
      
      // Platform-specific file handling
      Uint8List processedBytes;
      if (kIsWeb) {
        // Web-specific processing
        processedBytes = await _processImageForWeb(Uint8List.fromList(imageBytes));
      } else {
        // Mobile-specific processing
        processedBytes = await _processImageForMobile(Uint8List.fromList(imageBytes));
      }
      
      await _supabase.storage
          .from('receipts')
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: kIsWeb ? 'auto' : null, // Let web auto-detect, mobile can be null
            ),
          );

      final imageUrl = _supabase.storage
          .from('receipts')
          .getPublicUrl(filePath);

      // Update expense with receipt image URL
      await _supabase
          .from('expenses')
          .update({'receipt_image_url': imageUrl})
          .eq('id', expenseId);

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading receipt image: $e');
      }
      return null;
    }
  }

  // Platform-specific image processing
  Future<Uint8List> _processImageForWeb(Uint8List imageBytes) async {
    // Web-specific image processing
    // Could add compression, format conversion, etc.
    return imageBytes;
  }

  Future<Uint8List> _processImageForMobile(Uint8List imageBytes) async {
    // Mobile-specific image processing
    // Could add different compression settings, EXIF removal, etc.
    return imageBytes;
  }

  // Enhanced error handling for different platforms
  String _getPlatformSpecificError(dynamic error) {
    if (kIsWeb) {
      if (error.toString().contains('413')) {
        return 'File too large. Please select a smaller image.';
      } else if (error.toString().contains('415')) {
        return 'Unsupported file format. Please use JPG or PNG.';
      }
    }
    return 'Upload failed. Please try again.';
  }

  ExpenseCategory _parseExpenseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'materials':
        return ExpenseCategory.materials;
      case 'equipment':
        return ExpenseCategory.equipment;
      case 'transportation':
        return ExpenseCategory.transportation;
      case 'subcontractor':
        return ExpenseCategory.subcontractor;
      case 'permits':
        return ExpenseCategory.permits;
      case 'other':
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.materials;
    }
  }
}

extension ExpenseCategoryExtension on ExpenseCategory {
  IconData get icon {
    switch (this) {
      case ExpenseCategory.materials:
        return Icons.palette;
      case ExpenseCategory.equipment:
        return Icons.build;
      case ExpenseCategory.transportation:
        return Icons.local_shipping;
      case ExpenseCategory.subcontractor:
        return Icons.people;
      case ExpenseCategory.permits:
        return Icons.description;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}
