// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_training_app/models/workout.dart';

void main() {
  test('Workout copyWith preserves and updates fields', () {
    final original = Workout(
      id: 'w1',
      name: 'Session A',
      date: DateTime(2026, 1, 1),
      exercises: [
        Exercise(name: 'Squat', type: 'strength', sets: 3, reps: 8, weight: 60),
      ],
      clientUsername: 'alex',
    );

    final updated = original.copyWith(name: 'Session B', isCompleted: true);

    expect(updated.id, equals('w1'));
    expect(updated.name, equals('Session B'));
    expect(updated.clientUsername, equals('alex'));
    expect(updated.isCompleted, isTrue);
  });

  test('Exercise JSON roundtrip keeps core fields', () {
    final exercise = Exercise(
      name: 'Bike',
      type: 'cardio',
      durationMinutes: 20,
      distanceKm: 5.5,
      calories: 180,
    );

    final json = exercise.toJson();
    final decoded = Exercise.fromJson(json);

    expect(decoded.name, equals('Bike'));
    expect(decoded.type, equals('cardio'));
    expect(decoded.durationMinutes, equals(20));
    expect(decoded.distanceKm, equals(5.5));
  });

  test('Exercise repRange is preserved and parsed', () {
    final exercise = Exercise(
      name: 'Bench Press',
      type: 'strength',
      sets: 4,
      reps: 8,
      repRange: '8-10',
      weight: 80,
    );

    final json = exercise.toJson();
    final decoded = Exercise.fromJson(json);
    final fallbackDecoded = Exercise.fromJson({
      'name': 'Incline Press',
      'type': 'strength',
      'sets': 3,
      'repRange': '10-12',
      'weight': 65,
    });

    expect(decoded.repRange, equals('8-10'));
    expect(decoded.reps, equals(8));
    expect(fallbackDecoded.reps, equals(10));
    expect(fallbackDecoded.plannedRepsLabel, equals('10-12'));
  });
}
