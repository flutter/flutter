import 'dart:convert';

import '../utils/storage_helper.dart';

class ExerciseDemo {
  final String id;
  final String name;
  final String category; // 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'
  final String youtubeUrl;
  final String equipment;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final List<String> muscleGroups;
  final bool isCustom; // Track if this is a custom exercise

  ExerciseDemo({
    required this.id,
    required this.name,
    required this.category,
    required this.youtubeUrl,
    required this.equipment,
    required this.difficulty,
    required this.muscleGroups,
    this.isCustom = false,
  });

  ExerciseDemo copyWith({
    String? id,
    String? name,
    String? category,
    String? youtubeUrl,
    String? equipment,
    String? difficulty,
    List<String>? muscleGroups,
    bool? isCustom,
  }) {
    return ExerciseDemo(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'youtubeUrl': youtubeUrl,
      'equipment': equipment,
      'difficulty': difficulty,
      'muscleGroups': muscleGroups,
      'isCustom': isCustom,
    };
  }

  factory ExerciseDemo.fromJson(Map<String, dynamic> json) {
    return ExerciseDemo(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      youtubeUrl: json['youtubeUrl'] as String,
      equipment: json['equipment'] as String,
      difficulty: json['difficulty'] as String,
      muscleGroups: List<String>.from(json['muscleGroups'] as List),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

const String _exerciseLibraryStorageKey = 'exercise_library_data_v1';

final List<ExerciseDemo> _defaultExerciseLibrary = [
  ExerciseDemo(
    id: '1',
    name: 'Bench Press',
    category: 'Chest',
    youtubeUrl: 'https://www.youtube.com/watch?v=4T9UQ4FBVXA',
    equipment: 'Barbell, Bench',
    difficulty: 'Intermediate',
    muscleGroups: ['Chest', 'Triceps', 'Shoulders'],
  ),
  ExerciseDemo(
    id: '2',
    name: 'Deadlift',
    category: 'Back',
    youtubeUrl: 'https://www.youtube.com/watch?v=r4MzxtBKyNE',
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    muscleGroups: ['Back', 'Glutes', 'Hamstrings', 'Quadriceps'],
  ),
  ExerciseDemo(
    id: '3',
    name: 'Squat',
    category: 'Legs',
    youtubeUrl: 'https://www.youtube.com/watch?v=ultWZbUMPL8',
    equipment: 'Barbell, Rack',
    difficulty: 'Intermediate',
    muscleGroups: ['Quadriceps', 'Hamstrings', 'Glutes'],
  ),
  ExerciseDemo(
    id: '4',
    name: 'Pull-ups',
    category: 'Back',
    youtubeUrl: 'https://www.youtube.com/watch?v=eGo4IYlbE5g',
    equipment: 'Pull-up bar',
    difficulty: 'Advanced',
    muscleGroups: ['Back', 'Biceps', 'Forearms'],
  ),
  ExerciseDemo(
    id: '5',
    name: 'Dumbbell Curl',
    category: 'Arms',
    youtubeUrl: 'https://www.youtube.com/watch?v=ykJmreCEZK0',
    equipment: 'Dumbbells',
    difficulty: 'Beginner',
    muscleGroups: ['Biceps', 'Forearms'],
  ),
  ExerciseDemo(
    id: '6',
    name: 'Plank',
    category: 'Core',
    youtubeUrl: 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
    equipment: 'None',
    difficulty: 'Beginner',
    muscleGroups: ['Core', 'Shoulders', 'Back'],
  ),
  ExerciseDemo(
    id: '7',
    name: 'Shoulder Press',
    category: 'Shoulders',
    youtubeUrl: 'https://www.youtube.com/watch?v=2yjwXTZQDDI',
    equipment: 'Dumbbells or Barbell',
    difficulty: 'Intermediate',
    muscleGroups: ['Shoulders', 'Triceps', 'Upper Chest'],
  ),
  ExerciseDemo(
    id: '8',
    name: 'Leg Press',
    category: 'Legs',
    youtubeUrl: 'https://www.youtube.com/watch?v=IZxyjW7MIAI',
    equipment: 'Leg Press Machine',
    difficulty: 'Beginner',
    muscleGroups: ['Quadriceps', 'Hamstrings', 'Glutes'],
  ),
  ExerciseDemo(
    id: '9',
    name: 'Barbell Row',
    category: 'Back',
    youtubeUrl: 'https://www.youtube.com/watch?v=Sj5NS8BaXkA',
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    muscleGroups: ['Back', 'Biceps', 'Rear Shoulders'],
  ),
  ExerciseDemo(
    id: '10',
    name: 'Tricep Dip',
    category: 'Arms',
    youtubeUrl: 'https://www.youtube.com/watch?v=msDneV88VI8',
    equipment: 'Bench or Dip Station',
    difficulty: 'Intermediate',
    muscleGroups: ['Triceps', 'Chest', 'Shoulders'],
  ),
];

final List<ExerciseDemo> exerciseLibrary = List<ExerciseDemo>.from(
  _defaultExerciseLibrary,
);

Future<void> loadExerciseLibraryFromStorage() async {
  try {
    final savedJson =
        await StorageHelper.getString(_exerciseLibraryStorageKey) ?? '';
    if (savedJson.isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedJson) as List<dynamic>;
    final loaded = decoded
        .map((item) => ExerciseDemo.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    if (loaded.isNotEmpty) {
      exerciseLibrary
        ..clear()
        ..addAll(loaded);
    }
  } catch (e) {
    print('⚠️ Error loading exercise library from storage: $e');
  }
}

Future<bool> saveExerciseLibraryToStorage() async {
  try {
    final encoded = jsonEncode(exerciseLibrary.map((e) => e.toJson()).toList());
    return await StorageHelper.setString(_exerciseLibraryStorageKey, encoded);
  } catch (e) {
    print('⚠️ Error saving exercise library to storage: $e');
    return false;
  }
}
