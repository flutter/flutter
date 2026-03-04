class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
  });

  final String id;
  final String name;
  final String primaryMuscle;

  Exercise copyWith({
    String? id,
    String? name,
    String? primaryMuscle,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
    );
  }
}
