import '../data/mock_data.dart';
import '../models/coach_message.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/workout_stats.dart';

class TrainingService {
  const TrainingService();

  UserProfile getUserProfile() => mockUserProfile;

  Workout getTodayWorkout() => mockTodayWorkout;

  Workout getNextWorkout() => mockNextWorkout;

  List<String> getRecentExercises() => List<String>.from(mockRecentExercises);

  WorkoutStats getStats() => mockStats;

  List<CoachMessage> getCoachMessages() => List<CoachMessage>.from(mockCoachMessages);
}
