import 'package:flutter/material.dart';
import '../models/workout.dart';


import '../models/client_profile.dart';

class AddWorkoutScreen extends StatefulWidget {
  final Function(Workout) onWorkoutAdded;
  final List<ClientProfile> clients;

  const AddWorkoutScreen({super.key, required this.onWorkoutAdded, required this.clients});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}


class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _exerciseNameController;
  late TextEditingController _setsController;
  late TextEditingController _repRangeController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  late TextEditingController _distanceController;

  // HIIT fields
  int _hiitRounds = 1;
  int _hiitRestSeconds = 30;

  // Circuit fields
  int _circuitStations = 2;
  int _circuitTimePerStation = 30;
  int _circuitRestSeconds = 30;

  final List<Exercise> _exercises = [];
  DateTime _selectedDate = DateTime.now();
  String _workoutType = 'strength'; // strength, cardio, hiit, circuit
  bool _isCardioExercise = false;

  ClientProfile? _selectedClient;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _exerciseNameController = TextEditingController();
    _setsController = TextEditingController();
    _repRangeController = TextEditingController();
    _weightController = TextEditingController();
    _notesController = TextEditingController();
    _durationController = TextEditingController();
    _distanceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exerciseNameController.dispose();
    _setsController.dispose();
    _repRangeController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  String? _normalizeRepRange(String rawInput) {
    final match = RegExp(
      r'^(\d{1,3})\s*-\s*(\d{1,3})$',
    ).firstMatch(rawInput.trim());
    if (match == null) {
      return null;
    }
    final lower = int.tryParse(match.group(1)!);
    final upper = int.tryParse(match.group(2)!);
    if (lower == null || upper == null || lower > upper) {
      return null;
    }
    return '$lower-$upper';
  }

  void _addExercise() {
    if (_exerciseNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter exercise name')),
      );
      return;
    }

    if (_isCardioExercise) {
      // Validate cardio fields
      if (_durationController.text.isEmpty &&
          _distanceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter duration or distance')),
        );
        return;
      }

      final exercise = Exercise(
        name: _exerciseNameController.text,
        type: 'cardio',
        sets: 1,
        reps: 1,
        weight: 0,
        durationMinutes: _durationController.text.isEmpty
            ? null
            : int.parse(_durationController.text),
        distanceKm: _distanceController.text.isEmpty
            ? null
            : double.parse(_distanceController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      setState(() {
        _exercises.add(exercise);
        _exerciseNameController.clear();
        _durationController.clear();
        _distanceController.clear();
        _notesController.clear();
      });
    } else {
      // Validate strength training fields
      if (_setsController.text.isEmpty ||
          _repRangeController.text.isEmpty ||
          _weightController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all exercise fields')),
        );
        return;
      }

      final normalizedRepRange = _normalizeRepRange(_repRangeController.text);
      if (normalizedRepRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rep range must look like 8-12')),
        );
        return;
      }

      final parsedReps = Exercise.repsFromRange(normalizedRepRange);
      if (parsedReps == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid rep range')),
        );
        return;
      }

      final exercise = Exercise(
        name: _exerciseNameController.text,
        type: 'strength',
        sets: int.parse(_setsController.text),
        reps: parsedReps,
        repRange: normalizedRepRange,
        weight: double.parse(_weightController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      setState(() {
        _exercises.add(exercise);
        _exerciseNameController.clear();
        _setsController.clear();
        _repRangeController.clear();
        _weightController.clear();
        _notesController.clear();
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _submitWorkout() {
    if (_nameController.text.isEmpty || _exercises.isEmpty || _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter workout name, add exercises, and select a client'),
        ),
      );
      return;
    }

    final workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      date: _selectedDate,
      exercises: List.from(_exercises),
      type: _workoutType,
      clientName: _selectedClient!.name,
      clientUsername: _selectedClient!.username,
    );

    widget.onWorkoutAdded(workout);
    _nameController.clear();
    setState(() {
      _exercises.clear();
      _selectedDate = DateTime.now();
      _workoutType = 'strength';
      _selectedClient = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Workout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ClientProfile>(
            initialValue: _selectedClient,
            decoration: const InputDecoration(
              labelText: 'Select Client',
              border: OutlineInputBorder(),
            ),
            items: widget.clients
                .map((client) => DropdownMenuItem(
                      value: client,
                      child: Text(client.name.isNotEmpty ? client.name : client.username),
                    ))
                .toList(),
            onChanged: (client) {
              setState(() {
                _selectedClient = client;
              });
            },
            validator: (value) => value == null ? 'Please select a client' : null,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Workout Name',
                    hintText: 'e.g., Chest Day',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${_selectedDate.toString().split(' ')[0]}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Workout Type:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _workoutType,
                      items: const [
                        DropdownMenuItem(value: 'strength', child: Text('Strength')),
                        DropdownMenuItem(value: 'cardio', child: Text('Cardio')),
                        DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
                        DropdownMenuItem(value: 'circuit', child: Text('Circuit')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _workoutType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (_workoutType == 'hiit') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _hiitRounds.toString(),
                          decoration: const InputDecoration(labelText: 'Rounds'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() => _hiitRounds = int.tryParse(val) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _hiitRestSeconds.toString(),
                          decoration: const InputDecoration(labelText: 'Rest (sec)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() => _hiitRestSeconds = int.tryParse(val) ?? 30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Add exercises for each round below.'),
                ],
                if (_workoutType == 'circuit') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _circuitStations.toString(),
                          decoration: const InputDecoration(labelText: 'Stations'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() => _circuitStations = int.tryParse(val) ?? 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _circuitTimePerStation.toString(),
                          decoration: const InputDecoration(labelText: 'Time per station (sec)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() => _circuitTimePerStation = int.tryParse(val) ?? 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _circuitRestSeconds.toString(),
                          decoration: const InputDecoration(labelText: 'Rest (sec)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() => _circuitRestSeconds = int.tryParse(val) ?? 30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Add exercises for each station below.'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Add Exercises', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Exercise Type:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Strength'),
                            icon: Icon(Icons.fitness_center),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Cardio'),
                            icon: Icon(Icons.directions_run),
                          ),
                        ],
                        selected: {_isCardioExercise},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isCardioExercise = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _exerciseNameController,
                    decoration: InputDecoration(
                      labelText: 'Exercise Name',
                      hintText: _isCardioExercise
                          ? 'e.g., Running'
                          : 'e.g., Bench Press',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isCardioExercise)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final shouldStackFields = constraints.maxWidth < 700;

                        if (shouldStackFields) {
                          return Column(
                            children: [
                              TextField(
                                controller: _setsController,
                                decoration: InputDecoration(
                                  labelText: 'Sets',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _repRangeController,
                                decoration: InputDecoration(
                                  labelText: 'Rep Range',
                                  hintText: 'e.g., 8-12',
                                  helperText: 'Guide: Strength 3-6, Hypertrophy 8-12, Endurance 12-20',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _setsController,
                                decoration: InputDecoration(
                                  labelText: 'Sets',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _repRangeController,
                                decoration: InputDecoration(
                                  labelText: 'Rep Range',
                                  hintText: 'e.g., 8-12',
                                  helperText: 'Guide: Strength 3-6, Hypertrophy 8-12, Endurance 12-20',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            decoration: InputDecoration(
                              labelText: 'Duration (min)',
                              hintText: 'Optional',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _distanceController,
                            decoration: InputDecoration(
                              labelText: 'Distance (km)',
                              hintText: 'Optional',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_exercises.isNotEmpty) ...[
            Text(
              'Exercises Added (${_exercises.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._exercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final exercise = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    exercise.isCardio
                        ? Icons.directions_run
                        : Icons.fitness_center,
                    color: exercise.isCardio ? Colors.orange : Colors.blue,
                  ),
                  title: Text(exercise.name),
                  subtitle: Text(
                    exercise.isCardio
                        ? '${exercise.durationMinutes != null ? "${exercise.durationMinutes} min" : ""}'
                              '${exercise.durationMinutes != null && exercise.distanceKm != null ? " • " : ""}'
                              '${exercise.distanceKm != null ? "${exercise.distanceKm} km" : ""}'
                    : '${exercise.sets}x${exercise.plannedRepsLabel} @ ${exercise.weight} kg',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeExercise(idx),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitWorkout,
                child: const Text('Save Workout'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
