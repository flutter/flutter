import 'dart:convert';
import 'dart:io';

import '../models/workout_session.dart';
import 'workout_history_repository.dart';

class _FileWorkoutHistoryRepository implements WorkoutHistoryRepository {
  static const String _fileName = 'trainflow_workout_history_v1.json';

  File get _storageFile => File('${Directory.systemTemp.path}/$_fileName');

  @override
  Future<List<WorkoutSession>> readAll() async {
    if (!await _storageFile.exists()) {
      return const <WorkoutSession>[];
    }

    try {
      final String raw = await _storageFile.readAsString();
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <WorkoutSession>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(WorkoutSession.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <WorkoutSession>[];
    }
  }

  @override
  Future<void> writeAll(List<WorkoutSession> sessions) async {
    final List<Map<String, dynamic>> payload = sessions
        .map((WorkoutSession session) => session.toJson())
        .toList(growable: false);
    await _storageFile.writeAsString(jsonEncode(payload), flush: true);
  }
}

WorkoutHistoryRepository createWorkoutHistoryRepositoryImpl() {
  return _FileWorkoutHistoryRepository();
}
