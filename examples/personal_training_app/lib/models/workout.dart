// Top-level Comment class

// Top-level Comment class
class Comment {
  final String user;
  final String message;
  final DateTime date;
  final String? mediaUrl;

  Comment({
    required this.user,
    required this.message,
    required this.date,
    this.mediaUrl,
  });
}

class Workout {
  final String id;
  final String name;
  final DateTime date;
  final List<Exercise> exercises;
  final String? warmUp;
  final String? coolDown;
  final String? notes;
  final String? feedback; // Client's feedback after completing workout
  final String? instructorReview; // Instructor's review notes
  final String clientName;
  final String clientUsername;
  final bool isCompleted;
  final bool isReviewedByInstructor;
  final bool isReviewAcknowledged; // Whether client has acknowledged the review
  final String type; // e.g., strength, cardio, hiit, circuit, flexibility
  final List<String>? mediaUrls; // List of image/video URLs
  final List<Comment>? comments; // Feedback/comments from instructor/client
  final int? calories;
  final int? durationMinutes; // Total duration for the workout

  Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    this.warmUp,
    this.coolDown,
    this.notes,
    this.feedback,
    this.instructorReview,
    this.clientName = 'Alex Johnson',
    this.clientUsername = '',
    this.isCompleted = false,
    this.isReviewedByInstructor = false,
    this.isReviewAcknowledged = false,
    this.type = 'strength',
    this.mediaUrls,
    this.comments,
    this.calories,
    this.durationMinutes,
  });

  int get totalSets => exercises
      .where((ex) => !ex.isCardio)
      .fold(0, (sum, ex) => sum + (ex.sets ?? 0));
  int get totalReps => exercises
      .where((ex) => !ex.isCardio)
      .fold(0, (sum, ex) => sum + ((ex.reps ?? 0) * (ex.sets ?? 0)));
  double get estimatedVolume => exercises
      .where((ex) => !ex.isCardio)
      .fold(
        0.0,
        (sum, ex) => sum + ((ex.weight ?? 0) * (ex.reps ?? 0) * (ex.sets ?? 0)),
      );

  // Cardio-specific analytics
  int get totalCardioMinutes => exercises
      .where((ex) => ex.isCardio && ex.durationMinutes != null)
      .fold(0, (sum, ex) => sum + (ex.durationMinutes ?? 0));
  double get totalCardioDistanceKm => exercises
      .where((ex) => ex.isCardio && ex.distanceKm != null)
      .fold(0.0, (sum, ex) => sum + (ex.distanceKm ?? 0));
  int get cardioExerciseCount => exercises.where((ex) => ex.isCardio).length;
  int get strengthExerciseCount => exercises.where((ex) => !ex.isCardio).length;

  Duration get duration => const Duration(minutes: 60); // Default estimate

  Workout copyWith({
    String? id,
    String? name,
    DateTime? date,
    List<Exercise>? exercises,
    String? warmUp,
    String? coolDown,
    String? notes,
    String? feedback,
    String? instructorReview,
    String? clientName,
    String? clientUsername,
    bool? isCompleted,
    bool? isReviewedByInstructor,
    bool? isReviewAcknowledged,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      warmUp: warmUp ?? this.warmUp,
      coolDown: coolDown ?? this.coolDown,
      notes: notes ?? this.notes,
      feedback: feedback ?? this.feedback,
      instructorReview: instructorReview ?? this.instructorReview,
      clientName: clientName ?? this.clientName,
      clientUsername: clientUsername ?? this.clientUsername,
      isCompleted: isCompleted ?? this.isCompleted,
      isReviewedByInstructor:
          isReviewedByInstructor ?? this.isReviewedByInstructor,
      isReviewAcknowledged: isReviewAcknowledged ?? this.isReviewAcknowledged,
    );
  }
}

class Exercise {
  static int? repsFromRange(String? range) {
    if (range == null) return null;
    final match = RegExp(r'^(\d{1,3})\s*-\s*(\d{1,3})$').firstMatch(
      range.trim(),
    );
    if (match == null) return null;
    final lower = int.tryParse(match.group(1)!);
    final upper = int.tryParse(match.group(2)!);
    if (lower == null || upper == null || lower > upper) return null;
    return lower;
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final rawSetWeights = json['setWeights'] as List?;
    final rawSetReps = json['setReps'] as List?;
    final rawType = json['type']?.toString();
    return Exercise(
      name: json['name'] ?? '',
      type: rawType ?? (json['isCardio'] == true ? 'cardio' : 'strength'),
      sets: json['sets'],
      reps: (json['reps'] as num?)?.toInt() ?? repsFromRange(json['repRange']?.toString()),
      repRange: json['repRange']?.toString(),
      weight: (json['weight'] is int)
          ? (json['weight'] as int).toDouble()
          : json['weight'],
      notes: json['notes'],
      restSeconds: json['restSeconds'],
      setWeights: rawSetWeights?.map((e) => (e as num).toDouble()).toList(),
      setReps: rawSetReps?.map((e) => (e as num).toInt()).toList(),
      setNotes: (json['setNotes'] as List?)?.map((e) => e.toString()).toList(),
      mediaUrls: (json['mediaUrls'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      prescribedSets: (json['prescribedSets'] as num?)?.toInt(),
      prescribedReps: (json['prescribedReps'] as num?)?.toInt(),
      prescribedWeight: (json['prescribedWeight'] as num?)?.toDouble(),
      durationMinutes: json['durationMinutes'],
      distanceKm: (json['distanceKm'] is int)
          ? (json['distanceKm'] as int).toDouble()
          : json['distanceKm'],
      calories: json['calories'],
      rounds: json['rounds'],
      intervalSeconds: json['intervalSeconds'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'sets': sets,
      'reps': reps,
      'repRange': repRange,
      'weight': weight,
      'notes': notes,
      'restSeconds': restSeconds,
      'setWeights': setWeights,
      'setReps': setReps,
      'setNotes': setNotes,
      'mediaUrls': mediaUrls,
      'prescribedSets': prescribedSets,
      'prescribedReps': prescribedReps,
      'prescribedWeight': prescribedWeight,
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      'calories': calories,
      'rounds': rounds,
      'intervalSeconds': intervalSeconds,
    };
  }

  final String name;
  final String type; // strength, cardio, hiit, circuit, flexibility, etc.
  final int? sets;
  final int? reps;
  final String? repRange;
  final double? weight; // in kg (default/recommended weight)
  final String? notes;
  final int? restSeconds;
  final List<double>? setWeights; // Actual weight used per set during workout
  final List<int>? setReps; // Actual reps completed per set during workout
  final List<String>? setNotes; // Notes per set
  final List<String>? mediaUrls; // Media for this exercise
  final int? prescribedSets;
  final int? prescribedReps;
  final double? prescribedWeight;

  // Cardio-specific fields
  final int? durationMinutes; // Duration for cardio/HIIT
  final double? distanceKm; // Distance for cardio (in kilometers)
  final int? calories;

  // HIIT/circuit/flexibility fields
  final int? rounds;
  final int? intervalSeconds;

  Exercise({
    required this.name,
    required this.type,
    this.sets,
    this.reps,
    this.repRange,
    this.weight,
    this.notes,
    this.restSeconds = 60,
    this.setWeights,
    this.setReps,
    this.setNotes,
    this.mediaUrls,
    this.prescribedSets,
    this.prescribedReps,
    this.prescribedWeight,
    this.durationMinutes,
    this.distanceKm,
    this.calories,
    this.rounds,
    this.intervalSeconds,
  });

  // Helper: true if this exercise is cardio type
  bool get isCardio => type.toLowerCase() == 'cardio';

  String get plannedRepsLabel {
    final trimmed = repRange?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return reps?.toString() ?? '-';
  }

  double get volumePerSet => isCardio ? 0 : ((weight ?? 0) * (reps ?? 0));
  double get totalVolume {
    if (isCardio) return 0;
    if (setWeights != null && setWeights!.isNotEmpty) {
      double total = 0;
      for (int index = 0; index < setWeights!.length; index++) {
        final recordedReps = setReps != null && index < setReps!.length
            ? setReps![index]
            : (reps ?? 0);
        total += setWeights![index] * recordedReps;
      }
      return total;
    }
    return (weight ?? 0) * (reps ?? 0) * (sets ?? 0);
  }

  Exercise copyWith({
    String? name,
    String? type,
    int? sets,
    int? reps,
    String? repRange,
    double? weight,
    String? notes,
    int? restSeconds,
    List<double>? setWeights,
    List<int>? setReps,
    List<String>? setNotes,
    List<String>? mediaUrls,
    int? prescribedSets,
    int? prescribedReps,
    double? prescribedWeight,
    int? durationMinutes,
    double? distanceKm,
    int? calories,
    int? rounds,
    int? intervalSeconds,
  }) {
    return Exercise(
      name: name ?? this.name,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      repRange: repRange ?? this.repRange,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      restSeconds: restSeconds ?? this.restSeconds,
      setWeights: setWeights ?? this.setWeights,
      setReps: setReps ?? this.setReps,
      setNotes: setNotes ?? this.setNotes,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      prescribedSets: prescribedSets ?? this.prescribedSets,
      prescribedReps: prescribedReps ?? this.prescribedReps,
      prescribedWeight: prescribedWeight ?? this.prescribedWeight,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      rounds: rounds ?? this.rounds,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    );
  }
}
