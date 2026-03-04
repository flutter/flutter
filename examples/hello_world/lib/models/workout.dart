class Workout {
  const Workout({
    required this.title,
    required this.focus,
    required this.durationMinutes,
    required this.exercises,
    required this.scheduledLabel,
  });

  final String title;
  final String focus;
  final int durationMinutes;
  final List<String> exercises;
  final String scheduledLabel;
}
