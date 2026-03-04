class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.experience,
  });

  final String name;
  final int age;
  final int heightCm;
  final double weightKg;
  final String goal;
  final String experience;
}
