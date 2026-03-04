import '../models/workout_session.dart';
import 'workout_history_repository.dart';

class _MemoryWorkoutHistoryRepository implements WorkoutHistoryRepository {
  List<WorkoutSession> _sessions = const <WorkoutSession>[];

  @override
  Future<List<WorkoutSession>> readAll() async {
    return List<WorkoutSession>.from(_sessions);
  }

  @override
  Future<void> writeAll(List<WorkoutSession> sessions) async {
    _sessions = List<WorkoutSession>.from(sessions);
  }
}

WorkoutHistoryRepository createWorkoutHistoryRepositoryImpl() {
  return _MemoryWorkoutHistoryRepository();
}
