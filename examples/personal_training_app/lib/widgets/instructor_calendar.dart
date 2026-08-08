import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/rest_day.dart';
import '../models/client_profile.dart';
import '../widgets/training_calendar.dart';

class InstructorCalendar extends StatefulWidget {
  final List<Workout> workouts;
  final List<RestDay> restDays;
  final List<ClientProfile> clients;

  const InstructorCalendar({
    super.key,
    required this.workouts,
    required this.restDays,
    required this.clients,
  });

  @override
  State<InstructorCalendar> createState() => _InstructorCalendarState();
}

class _InstructorCalendarState extends State<InstructorCalendar> {
  String? selectedClientUsername;

  String _canonicalClientValue(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('micheal', 'michael')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  ClientProfile? _selectedClientProfile() {
    if (selectedClientUsername == null) return null;
    for (final client in widget.clients) {
      if (client.username == selectedClientUsername) {
        return client;
      }
    }
    return null;
  }

  bool _matchesSelectedClientWorkout(Workout workout, ClientProfile selected) {
    final workoutUsername = _canonicalClientValue(workout.clientUsername);
    final workoutClientName = _canonicalClientValue(workout.clientName);
    final selectedUsername = _canonicalClientValue(selected.username);
    final selectedName = _canonicalClientValue(selected.name);

    return workoutUsername == selectedUsername ||
        workoutClientName == selectedUsername ||
        (selectedName.isNotEmpty && workoutClientName == selectedName);
  }

  @override
  Widget build(BuildContext context) {
    final selectedClient = _selectedClientProfile();
    final filteredWorkouts = selectedClient == null
        ? widget.workouts
        : widget.workouts
              .where((w) => _matchesSelectedClientWorkout(w, selectedClient))
              .toList();
    final filteredRestDays = selectedClient == null
        ? widget.restDays
        : widget.restDays
              .where((r) => r.clientName == selectedClient.username)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  const Text(
                    'Client Calendar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: selectedClientUsername,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Clients'),
                      ),
                      ...widget.clients.map(
                        (c) => DropdownMenuItem(
                          value: c.username,
                          child: Text(c.name.isNotEmpty ? c.name : c.username),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedClientUsername = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    label: Text(
                      selectedClient == null
                          ? 'Showing: All Clients'
                          : 'Showing: ${selectedClient.name.isNotEmpty ? selectedClient.name : selectedClient.username}',
                    ),
                    backgroundColor: const Color(0xFFDBEAFE),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrainingCalendar(
              workouts: filteredWorkouts,
              restDays: filteredRestDays.map((r) => r.date).toList(),
              isInstructor: true,
            ),
          ),
        ),
      ],
    );
  }
}
