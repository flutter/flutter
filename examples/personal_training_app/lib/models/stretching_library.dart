import 'dart:convert';

import '../utils/storage_helper.dart';

class StretchingExercise {
  final String id;
  final String name;
  final String category;
  final String duration;
  final String youtubeUrl;
  final String description;
  final String difficulty;
  final bool isCustom;

  StretchingExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.duration,
    required this.youtubeUrl,
    required this.description,
    required this.difficulty,
    this.isCustom = false,
  });

  StretchingExercise copyWith({
    String? id,
    String? name,
    String? category,
    String? duration,
    String? youtubeUrl,
    String? description,
    String? difficulty,
    bool? isCustom,
  }) {
    return StretchingExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'duration': duration,
      'youtubeUrl': youtubeUrl,
      'description': description,
      'difficulty': difficulty,
      'isCustom': isCustom,
    };
  }

  factory StretchingExercise.fromJson(Map<String, dynamic> json) {
    return StretchingExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      duration: json['duration'] as String,
      youtubeUrl: json['youtubeUrl'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

const String _stretchingLibraryStorageKey = 'stretching_library_data_v1';

final List<StretchingExercise> _defaultStretchingLibrary = [
  StretchingExercise(
    id: '1',
    name: 'Hamstring Stretch',
    category: 'Lower Body',
    duration: '30 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=1DXcWRFg8KY',
    description: 'Stretch your hamstrings while seated or standing',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '2',
    name: 'Chest Stretch',
    category: 'Upper Body',
    duration: '30 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=u8xLFaHqPrg',
    description: 'Open up your chest and shoulders',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '3',
    name: 'Hip Flexor Stretch',
    category: 'Lower Body',
    duration: '45 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=YQmpO9VT2X4',
    description: 'Release tight hip flexors from sitting',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '4',
    name: 'Quad Stretch',
    category: 'Lower Body',
    duration: '30 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=VbXM-FHBCfE',
    description: 'Stretch the front of your thighs',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '5',
    name: 'Shoulder Stretch',
    category: 'Upper Body',
    duration: '30 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=2eutBBj2I3M',
    description: 'Release tension in shoulders and upper back',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '6',
    name: 'Cat-Cow Stretch',
    category: 'Full Body',
    duration: '60 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=kqnua4rHVVA',
    description: 'Mobilize your spine with this yoga-inspired movement',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '7',
    name: 'Calf Stretch',
    category: 'Lower Body',
    duration: '30 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=3Z3f1VFLzdk',
    description: 'Stretch your calves against a wall',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '8',
    name: 'Triceps Stretch',
    category: 'Upper Body',
    duration: '30 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=cCCYm2UT1w0',
    description: 'Stretch the back of your arms',
    difficulty: 'Beginner',
  ),
  StretchingExercise(
    id: '9',
    name: 'Butterfly Stretch',
    category: 'Lower Body',
    duration: '45 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=8p6FtlqpAYg',
    description: 'Open up your hips and inner thighs',
    difficulty: 'Intermediate',
  ),
  StretchingExercise(
    id: '10',
    name: 'Full Body Stretch',
    category: 'Full Body',
    duration: '60 seconds',
    youtubeUrl: 'https://www.youtube.com/watch?v=g_tea8ZNk5A',
    description: 'Complete stretching routine for your whole body',
    difficulty: 'Beginner',
  ),
];

final List<StretchingExercise> stretchingLibrary =
    List<StretchingExercise>.from(_defaultStretchingLibrary);

Future<void> loadStretchingLibraryFromStorage() async {
  try {
    final savedJson =
        await StorageHelper.getString(_stretchingLibraryStorageKey) ?? '';
    if (savedJson.isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedJson) as List<dynamic>;
    final loaded = decoded
        .map(
          (item) =>
              StretchingExercise.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    if (loaded.isNotEmpty) {
      stretchingLibrary
        ..clear()
        ..addAll(loaded);
    }
  } catch (e) {
    print('⚠️ Error loading stretching library from storage: $e');
  }
}

Future<bool> saveStretchingLibraryToStorage() async {
  try {
    final encoded = jsonEncode(
      stretchingLibrary.map((e) => e.toJson()).toList(),
    );
    return await StorageHelper.setString(_stretchingLibraryStorageKey, encoded);
  } catch (e) {
    print('⚠️ Error saving stretching library to storage: $e');
    return false;
  }
}
