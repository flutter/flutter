import '../models/workout_session.dart';

import 'workout_history_repository_stub.dart'
    if (dart.library.io) 'workout_history_repository_io.dart';

abstract class WorkoutHistoryRepository {
  Future<List<WorkoutSession>> readAll();
  Future<void> writeAll(List<WorkoutSession> sessions);
}

WorkoutHistoryRepository createWorkoutHistoryRepository() => createWorkoutHistoryRepositoryImpl();
