class WorkoutStats {
  const WorkoutStats({
    required this.weeklySessions,
    required this.totalMinutesThisWeek,
    required this.latestPr,
    required this.totalVolumeKg,
    required this.avgWorkoutMinutes,
    required this.mostTrainedExercise,
    required this.weightTrend,
    required this.strengthTrend,
  });

  final int weeklySessions;
  final int totalMinutesThisWeek;
  final String latestPr;
  final int totalVolumeKg;
  final int avgWorkoutMinutes;
  final String mostTrainedExercise;
  final List<double> weightTrend;
  final List<double> strengthTrend;
}
