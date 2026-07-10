import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'firebase_service.dart';

/// Reads step count data from the device health platform (Google Health Connect
/// on Android, Apple HealthKit on iOS) and syncs it to Firebase.
class StepCountService {
  static final _health = Health();

  static const int dailyStepGoal = 10000;

  static final List<HealthDataType> _readTypes = [HealthDataType.STEPS];
  static final List<HealthDataAccess> _readPermissions = [
    HealthDataAccess.READ
  ];

  /// Request permission to read steps from the health platform.
  /// Returns true if permission was granted, false otherwise (or on web).
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      await _health.configure();
      final authorized = await _health.requestAuthorization(
        _readTypes,
        permissions: _readPermissions,
      );
      return authorized;
    } catch (e) {
      debugPrint('StepCountService.requestPermissions error: $e');
      return false;
    }
  }

  /// Check if step-reading permissions have already been granted.
  static Future<bool> hasPermissions() async {
    if (kIsWeb) return false;
    try {
      final result = await _health.hasPermissions(
        _readTypes,
        permissions: _readPermissions,
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Fetch the total step count for today from the health platform.
  /// Returns null if unavailable or on web.
  static Future<int?> fetchTodaySteps() async {
    if (kIsWeb) return null;
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      return await _health.getTotalStepsInInterval(midnight, now);
    } catch (e) {
      debugPrint('StepCountService.fetchTodaySteps error: $e');
      return null;
    }
  }

  /// Fetch step counts for the past [days] days (including today).
  /// Returns a map of ISO date strings (YYYY-MM-DD) → step count.
  static Future<Map<String, int>> fetchRecentSteps({int days = 7}) async {
    if (kIsWeb) return {};
    try {
      final now = DateTime.now();
      final result = <String, int>{};
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = i == 0
            ? now
            : DateTime(date.year, date.month, date.day, 23, 59, 59);
        final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd);
        if (steps != null && steps > 0) {
          final key = _dateKey(date);
          result[key] = steps;
        }
      }
      return result;
    } catch (e) {
      debugPrint('StepCountService.fetchRecentSteps error: $e');
      return {};
    }
  }

  /// Sync today's steps to Firebase for the given [username].
  /// Returns the synced step count, or null on failure.
  static Future<int?> syncTodayStepsToFirebase(String username) async {
    final steps = await fetchTodaySteps();
    if (steps != null) {
      final today = DateTime.now();
      await FirebaseService.saveStepCount(username, today, steps);
    }
    return steps;
  }

  /// Sync the past [days] days of step history to Firebase.
  static Future<void> syncRecentStepsToFirebase(
    String username, {
    int days = 7,
  }) async {
    final stepsMap = await fetchRecentSteps(days: days);
    for (final entry in stepsMap.entries) {
      final date = DateTime.parse(entry.key);
      await FirebaseService.saveStepCount(username, date, entry.value);
    }
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String todayKey() => _dateKey(DateTime.now());
}
