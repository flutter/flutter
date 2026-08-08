import 'rest_day.dart';

class ClientProfile {
  String username; // Client's username for login
  String email; // Client's email address
  String name;
  int? age;
  double? heightCm; // Height in centimeters
  double? weightKg; // Weight in kilograms
  String fitnessGoals; // e.g., "Build muscle, Lose weight"
  String smartGoals; // SMART goals for focused progression
  String trainingExperience; // e.g., "Beginner", "Intermediate", "Advanced"
  String trainingLocation; // "Home" or "Gym"
  String hobbiesInterests;
  String injuriesLimitations;
  String? profilePictureUrl; // URL or path to profile picture
  bool isSuspended; // Account suspension status
  Map<String, double> strengthPRs; // Map of exercise name to PR weight in kg
  Map<String, double> bodyMeasurementsCm; // e.g., waist/chest/hips in cm
  List<DateTime> illnessDays; // List of dates when client was ill
  List<RestDay>? restDays; // List of rest days for the client
  final List<ClientNotification> notifications;
  List<String> badges; // List of badge/achievement IDs
  int workoutStreak; // Current workout streak (days)
  int maxWorkoutStreak; // Longest streak

  ClientProfile({
    required this.username,
    required this.email,
    required this.name,
    this.age,
    this.heightCm,
    this.weightKg,
    this.fitnessGoals = '',
    this.smartGoals = '',
    this.trainingExperience = 'Beginner',
    this.trainingLocation = 'Gym',
    this.hobbiesInterests = '',
    this.injuriesLimitations = '',
    this.profilePictureUrl,
    this.isSuspended = false,
    Map<String, double>? strengthPRs,
    Map<String, double>? bodyMeasurementsCm,
    List<DateTime>? illnessDays,
    this.restDays,
    this.notifications = const [],
    this.badges = const [],
    this.workoutStreak = 0,
    this.maxWorkoutStreak = 0,
  }) : strengthPRs = strengthPRs ?? {},
       bodyMeasurementsCm = bodyMeasurementsCm ?? {},
       illnessDays = illnessDays ?? [];

  ClientProfile copyWith({
    String? username,
    String? email,
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? fitnessGoals,
    String? smartGoals,
    String? trainingExperience,
    String? trainingLocation,
    String? hobbiesInterests,
    String? injuriesLimitations,
    String? profilePictureUrl,
    bool? isSuspended,
    Map<String, double>? strengthPRs,
    Map<String, double>? bodyMeasurementsCm,
    List<DateTime>? illnessDays,
    List<RestDay>? restDays,
    List<ClientNotification>? notifications,
    List<String>? badges,
    int? workoutStreak,
    int? maxWorkoutStreak,
  }) {
    return ClientProfile(
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      smartGoals: smartGoals ?? this.smartGoals,
      trainingExperience: trainingExperience ?? this.trainingExperience,
      trainingLocation: trainingLocation ?? this.trainingLocation,
      hobbiesInterests: hobbiesInterests ?? this.hobbiesInterests,
      injuriesLimitations: injuriesLimitations ?? this.injuriesLimitations,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isSuspended: isSuspended ?? this.isSuspended,
      strengthPRs: strengthPRs ?? this.strengthPRs,
      bodyMeasurementsCm: bodyMeasurementsCm ?? this.bodyMeasurementsCm,
      illnessDays: illnessDays ?? this.illnessDays,
      restDays: restDays ?? this.restDays,
      notifications: notifications ?? this.notifications,
      badges: badges ?? this.badges,
      workoutStreak: workoutStreak ?? this.workoutStreak,
      maxWorkoutStreak: maxWorkoutStreak ?? this.maxWorkoutStreak,
    );
  }

  factory ClientProfile.fromMap(
    Map<String, dynamic> map, {
    String? fallbackUsername,
  }) {
    Map<String, double> parseDoubleMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
    }

    List<DateTime> parseDateList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((value) => DateTime.tryParse(value.toString()))
          .whereType<DateTime>()
          .toList();
    }

    List<RestDay> parseRestDays(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map>().map((value) {
        final data = Map<String, dynamic>.from(value);
        return RestDay(
          id: data['id']?.toString() ?? '',
          date:
              DateTime.tryParse(data['date']?.toString() ?? '') ??
              DateTime.now(),
          clientName: data['clientName']?.toString() ?? '',
          notes: data['notes']?.toString(),
        );
      }).toList();
    }

    List<ClientNotification> parseNotifications(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map>().map((value) {
        final data = Map<String, dynamic>.from(value);
        final replies = (data['replies'] as List?)
            ?.whereType<Map>()
            .map(
              (reply) => NotificationReply(
                user: reply['user']?.toString() ?? '',
                message: reply['message']?.toString() ?? '',
                date:
                    DateTime.tryParse(reply['date']?.toString() ?? '') ??
                    DateTime.now(),
              ),
            )
            .toList();
        return ClientNotification(
          id: data['id']?.toString() ?? '',
          title: data['title']?.toString() ?? '',
          message: data['message']?.toString() ?? '',
          date:
              DateTime.tryParse(data['date']?.toString() ?? '') ??
              DateTime.now(),
          acknowledged: data['acknowledged'] == true,
          type: data['type']?.toString() ?? 'message',
          celebration: data['celebration'] == true,
          mediaUrl: data['mediaUrl']?.toString(),
          reactions: (data['reactions'] as List?)
              ?.map((item) => item.toString())
              .toList(),
          replies: replies,
        );
      }).toList();
    }

    final profilePicture = map['profilePictureUrl']?.toString();
    return ClientProfile(
      username: map['username']?.toString() ?? fallbackUsername ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      age: (map['age'] as num?)?.toInt(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      fitnessGoals: map['fitnessGoals']?.toString() ?? '',
      smartGoals: map['smartGoals']?.toString() ?? '',
      trainingExperience: map['trainingExperience']?.toString() ?? '',
      trainingLocation: map['trainingLocation']?.toString() ?? '',
      hobbiesInterests: map['hobbiesInterests']?.toString() ?? '',
      injuriesLimitations: map['injuriesLimitations']?.toString() ?? '',
      profilePictureUrl: profilePicture == null || profilePicture.isEmpty
          ? null
          : profilePicture,
      isSuspended: map['isSuspended'] == true,
      strengthPRs: parseDoubleMap(map['strengthPRs']),
      bodyMeasurementsCm: parseDoubleMap(map['bodyMeasurementsCm']),
      illnessDays: parseDateList(map['illnessDays']),
      restDays: parseRestDays(map['restDays']),
      notifications: parseNotifications(map['notifications']),
      badges:
          (map['badges'] as List?)?.map((item) => item.toString()).toList() ??
          const [],
      workoutStreak: (map['workoutStreak'] as num?)?.toInt() ?? 0,
      maxWorkoutStreak: (map['maxWorkoutStreak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'name': name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'fitnessGoals': fitnessGoals,
      'smartGoals': smartGoals,
      'trainingExperience': trainingExperience,
      'trainingLocation': trainingLocation,
      'hobbiesInterests': hobbiesInterests,
      'injuriesLimitations': injuriesLimitations,
      'profilePictureUrl': profilePictureUrl,
      'isSuspended': isSuspended,
      'strengthPRs': strengthPRs,
      'bodyMeasurementsCm': bodyMeasurementsCm,
      'illnessDays': illnessDays.map((date) => date.toIso8601String()).toList(),
      'restDays': restDays
          ?.map(
            (restDay) => {
              'id': restDay.id,
              'date': restDay.date.toIso8601String(),
              'clientName': restDay.clientName,
              'notes': restDay.notes,
            },
          )
          .toList(),
      'notifications': notifications
          .map(
            (notification) => {
              'id': notification.id,
              'title': notification.title,
              'message': notification.message,
              'date': notification.date.toIso8601String(),
              'acknowledged': notification.acknowledged,
              'type': notification.type,
              'celebration': notification.celebration,
              'mediaUrl': notification.mediaUrl,
              'reactions': notification.reactions,
              'replies': notification.replies
                  ?.map(
                    (reply) => {
                      'user': reply.user,
                      'message': reply.message,
                      'date': reply.date.toIso8601String(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'badges': badges,
      'workoutStreak': workoutStreak,
      'maxWorkoutStreak': maxWorkoutStreak,
    };
  }
}

class ClientNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool acknowledged;
  final String type; // e.g., 'review', 'message', 'announcement'
  final bool celebration; // true if this notification should trigger confetti
  final String? mediaUrl; // Optional image/GIF URL
  final List<String>?
  reactions; // List of emoji reactions (usernames or ids can be added for per-user reactions)
  final List<NotificationReply>? replies; // List of replies

  ClientNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.acknowledged = false,
    this.type = 'message',
    this.celebration = false,
    this.mediaUrl,
    this.reactions,
    this.replies,
  });
}

class NotificationReply {
  final String user;
  final String message;
  final DateTime date;

  NotificationReply({
    required this.user,
    required this.message,
    required this.date,
  });
}
