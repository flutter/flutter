import '../../workout/domain/workout_template.dart';

class Program {
  const Program({
    required this.id,
    required this.name,
    required this.currentWeek,
    required this.totalWeeks,
    required this.workouts,
  });

  final String id;
  final String name;
  final int currentWeek;
  final int totalWeeks;
  final List<WorkoutTemplate> workouts;

  Program copyWith({
    String? id,
    String? name,
    int? currentWeek,
    int? totalWeeks,
    List<WorkoutTemplate>? workouts,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      workouts: workouts ?? this.workouts,
    );
  }
}
