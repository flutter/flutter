class SessionLog {
  const SessionLog({
    required this.workoutTemplateId,
    required this.startedAt,
    required this.completedAt,
    required this.setsByExercise,
  });

  final String workoutTemplateId;
  final DateTime startedAt;
  final DateTime completedAt;
  final Map<String, int> setsByExercise;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'workoutTemplateId': workoutTemplateId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'setsByExercise': setsByExercise,
    };
  }

  static SessionLog fromJson(Map<String, dynamic> json) {
    return SessionLog(
      workoutTemplateId: json['workoutTemplateId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      setsByExercise: (json['setsByExercise'] as Map<String, dynamic>).map(
        (String key, dynamic value) => MapEntry<String, int>(key, value as int),
      ),
    );
  }
}
