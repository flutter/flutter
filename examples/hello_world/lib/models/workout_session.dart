class WorkoutSession {
  const WorkoutSession({
    required this.title,
    required this.focus,
    required this.startedAt,
    required this.completedAt,
    required this.durationMinutes,
    required this.totalSets,
    required this.exercises,
    this.exerciseLogs = const <Map<String, dynamic>>[],
  });

  final String title;
  final String focus;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationMinutes;
  final int totalSets;
  final List<String> exercises;
  final List<Map<String, dynamic>> exerciseLogs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'focus': focus,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalSets': totalSets,
      'exercises': exercises,
      'exerciseLogs': exerciseLogs,
    };
  }

  static WorkoutSession fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      title: json['title'] as String? ?? 'Workout',
      focus: json['focus'] as String? ?? 'General',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      totalSets: (json['totalSets'] as num?)?.toInt() ?? 0,
      exercises: ((json['exercises'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
        exerciseLogs: ((json['exerciseLogs'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
    );
  }
}
