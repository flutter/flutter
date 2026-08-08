import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout.dart';
import '../models/client_profile.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  final ClientProfile? clientProfile;
  final Function(Map<String, double>)? onPRsUpdated;

  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.clientProfile,
    this.onPRsUpdated,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = true;
  int _currentExerciseIndex = 0;
  final List<bool> _completedSets = [];
  final Map<int, List<double>> _exerciseWeights =
      {}; // exerciseIndex -> list of weights per set
  final Map<int, List<int>> _exerciseReps =
      {}; // exerciseIndex -> list of reps per set

  @override
  void initState() {
    super.initState();
    // Initialize completed sets tracking
    for (var exercise in widget.workout.exercises) {
      final sets = exercise.sets ?? 0;
      for (int i = 0; i < sets; i++) {
        _completedSets.add(false);
      }
    }
    // Initialize per-set weights with default weights
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      final sets = exercise.sets ?? 0;
      _exerciseWeights[i] = List.generate(sets, (_) => exercise.weight ?? 0.0);
      _exerciseReps[i] = List.generate(
        sets,
        (_) => exercise.reps ?? Exercise.repsFromRange(exercise.repRange) ?? 0,
      );
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int _getSetIndexForExercise(int exerciseIndex) {
    int index = 0;
    for (int i = 0; i < exerciseIndex; i++) {
      index += widget.workout.exercises[i].sets ?? 0;
    }
    return index;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    final setStartIndex = _getSetIndexForExercise(_currentExerciseIndex);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenHeight < 750;
    final isNarrow = screenWidth < 390;

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _showExitDialog(context);
          },
        ),
        title: Text(
          widget.workout.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isCompact ? 12 : 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatTime(_elapsedSeconds),
                      style: TextStyle(
                        fontSize: isCompact ? 40 : 56,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: isCompact ? 28 : 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: EdgeInsets.fromLTRB(16, isCompact ? 10 : 16, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercise ${_currentExerciseIndex + 1} of ${widget.workout.exercises.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value:
                        (_currentExerciseIndex + 1) /
                        widget.workout.exercises.length,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),

            // Current Exercise Card
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Card(
                  color: const Color(0xFF374151),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 28 : 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Name
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: isCompact ? 32 : 38,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                        if (widget.workout.warmUp != null &&
                            widget.workout.warmUp!.isNotEmpty) ...[
                          SizedBox(height: isCompact ? 12 : 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 16,
                                      color: Color(0xFFFDE68A),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Warm-up',
                                      style: TextStyle(
                                        color: Color(0xFFFDE68A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.workout.warmUp!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (widget.workout.coolDown != null &&
                            widget.workout.coolDown!.isNotEmpty) ...[
                          SizedBox(height: isCompact ? 10 : 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.self_improvement,
                                      size: 16,
                                      color: Color(0xFFA7F3D0),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Cool-down',
                                      style: TextStyle(
                                        color: Color(0xFFA7F3D0),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.workout.coolDown!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: isCompact ? 16 : 24),

                        // Exercise Details
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: exercise.isCardio
                              ? [
                                  if (exercise.durationMinutes != null)
                                    _buildInfoChip(
                                      icon: Icons.timer,
                                      label: '${exercise.durationMinutes} min',
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  if (exercise.distanceKm != null)
                                    _buildInfoChip(
                                      icon: Icons.straighten,
                                      label: '${exercise.distanceKm} km',
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                  _buildInfoChip(
                                    icon: Icons.directions_run,
                                    label: 'Cardio',
                                    color: const Color(0xFFEC4899),
                                  ),
                                ]
                              : [
                                  _buildInfoChip(
                                    icon: Icons.fitness_center,
                                    label: '${exercise.weight} kg',
                                    color: const Color(0xFF3B82F6),
                                  ),
                                  _buildInfoChip(
                                    icon: Icons.repeat,
                                    label: '${exercise.plannedRepsLabel} reps',
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                  _buildInfoChip(
                                    icon: Icons.timer,
                                    label:
                                        '${exercise.restSeconds ?? 60}s rest',
                                    color: const Color(0xFFEC4899),
                                  ),
                                ],
                        ),

                        if (exercise.notes != null &&
                            exercise.notes!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF60A5FA),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    exercise.notes!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Sets or Cardio Completion
                        if (!exercise.isCardio) ...[
                          Text(
                            'Sets',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(exercise.sets ?? 0, (index) {
                            final globalSetIndex = setStartIndex + index;
                            final currentWeight =
                                _exerciseWeights[_currentExerciseIndex]![index];
                            final currentReps =
                                _exerciseReps[_currentExerciseIndex]![index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _completedSets[globalSetIndex]
                                      ? const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.2)
                                      : const Color(0xFF1F2937),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _completedSets[globalSetIndex]
                                        ? const Color(0xFF10B981)
                                        : Colors.white10,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _completedSets[globalSetIndex] =
                                                  !_completedSets[globalSetIndex];
                                            });
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color:
                                                  _completedSets[globalSetIndex]
                                                  ? const Color(0xFF10B981)
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    _completedSets[globalSetIndex]
                                                    ? const Color(0xFF10B981)
                                                    : Colors.white30,
                                                width: 2,
                                              ),
                                            ),
                                            child:
                                                _completedSets[globalSetIndex]
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 20,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Set ${index + 1}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _completedSets[globalSetIndex]
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final shouldStack =
                                            constraints.maxWidth < 430;

                                        if (shouldStack) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildWeightAdjustControl(
                                                currentWeight: currentWeight,
                                                onTap: () => _showWeightDialog(
                                                  _currentExerciseIndex,
                                                  index,
                                                  currentWeight,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              _buildRepsAdjustControl(
                                                currentReps: currentReps,
                                                onDecrement: () {
                                                  if (currentReps > 1) {
                                                    setState(() {
                                                      _exerciseReps[_currentExerciseIndex]![index]--;
                                                    });
                                                  }
                                                },
                                                onIncrement: () {
                                                  setState(() {
                                                    _exerciseReps[_currentExerciseIndex]![index]++;
                                                  });
                                                },
                                              ),
                                            ],
                                          );
                                        }

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _buildWeightAdjustControl(
                                                currentWeight: currentWeight,
                                                onTap: () => _showWeightDialog(
                                                  _currentExerciseIndex,
                                                  index,
                                                  currentWeight,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildRepsAdjustControl(
                                                currentReps: currentReps,
                                                onDecrement: () {
                                                  if (currentReps > 1) {
                                                    setState(() {
                                                      _exerciseReps[_currentExerciseIndex]![index]--;
                                                    });
                                                  }
                                                },
                                                onIncrement: () {
                                                  setState(() {
                                                    _exerciseReps[_currentExerciseIndex]![index]++;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ] else ...[
                          // Cardio completion button
                          Text(
                            'Complete this cardio exercise when finished',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _completedSets[setStartIndex]
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _completedSets[setStartIndex]
                                    ? const Color(0xFF10B981)
                                    : Colors.white10,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _completedSets[setStartIndex] =
                                      !_completedSets[setStartIndex];
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _completedSets[setStartIndex]
                                          ? const Color(0xFF10B981)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _completedSets[setStartIndex]
                                            ? const Color(0xFF10B981)
                                            : Colors.white30,
                                        width: 2,
                                      ),
                                    ),
                                    child: _completedSets[setStartIndex]
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    _completedSets[setStartIndex]
                                        ? 'Exercise Completed!'
                                        : 'Mark as Complete',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: _completedSets[setStartIndex]
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Navigation Buttons
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, isNarrow ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentExerciseIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentExerciseIndex--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: EdgeInsets.symmetric(
                            vertical: isNarrow ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (_currentExerciseIndex > 0)
                    SizedBox(width: isNarrow ? 10 : 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_currentExerciseIndex <
                            widget.workout.exercises.length - 1) {
                          setState(() {
                            _currentExerciseIndex++;
                          });
                        } else {
                          _showCompleteDialog(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: EdgeInsets.symmetric(
                          vertical: isNarrow ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentExerciseIndex <
                                widget.workout.exercises.length - 1
                            ? 'Next Exercise'
                            : 'Finish Workout',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightAdjustControl({
    required double currentWeight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B82F6), width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.fitness_center,
              size: 16,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$currentWeight kg',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildRepsAdjustControl({
    required int currentReps,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 1),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.remove, size: 18, color: Colors.white),
            ),
          ),
          Expanded(
            child: Center(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentReps ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: 'reps',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(
    int exerciseIndex,
    int setIndex,
    double currentWeight,
  ) {
    final controller = TextEditingController(text: currentWeight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 16),
            // Quick adjustment buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAdjustButton('-5', () {
                  final current =
                      double.tryParse(controller.text) ?? currentWeight;
                  controller.text = (current - 5).clamp(0, 1000).toString();
                }),
                _buildQuickAdjustButton('-2.5', () {
                  final current =
                      double.tryParse(controller.text) ?? currentWeight;
                  controller.text = (current - 2.5).clamp(0, 1000).toString();
                }),
                _buildQuickAdjustButton('+2.5', () {
                  final current =
                      double.tryParse(controller.text) ?? currentWeight;
                  controller.text = (current + 2.5).clamp(0, 1000).toString();
                }),
                _buildQuickAdjustButton('+5', () {
                  final current =
                      double.tryParse(controller.text) ?? currentWeight;
                  controller.text = (current + 5).clamp(0, 1000).toString();
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newWeight = double.tryParse(controller.text);
              if (newWeight != null && newWeight >= 0) {
                setState(() {
                  _exerciseWeights[exerciseIndex]![setIndex] = newWeight;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdjustButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }

  Map<String, double>? _checkForNewPRs() {
    if (widget.clientProfile == null) return null;

    final currentPRs = widget.clientProfile!.strengthPRs;
    final Map<String, double> newPRs = {};

    // Check each exercise in the workout using actual weights performed
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      final exerciseName = exercise.name;

      // Get the maximum weight used across all sets for this exercise
      final weights = _exerciseWeights[i] ?? [];
      if (weights.isEmpty) continue;

      final maxWeight = weights.reduce((a, b) => a > b ? a : b);

      // Check if this weight is a new PR
      if (!currentPRs.containsKey(exerciseName) ||
          maxWeight > currentPRs[exerciseName]!) {
        newPRs[exerciseName] = maxWeight;
        print(
          '💪 New PR detected: $exerciseName = $maxWeight kg (previous: ${currentPRs[exerciseName] ?? "none"})',
        );
      }
    }

    return newPRs.isEmpty ? null : newPRs;
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close workout screen
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    int? difficultyRating;

    // Check for new PRs before showing dialog
    final newPRs = _checkForNewPRs();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Text('🎉 Workout Complete!'),
              if (newPRs != null && newPRs.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.celebration,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
              ],
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great job! You completed the workout in ${_formatTime(_elapsedSeconds)}.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Total exercises: ${widget.workout.exercises.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                // Show new PRs prominently
                if (newPRs != null && newPRs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'NEW PERSONAL RECORDS!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...newPRs.entries.map((entry) {
                          final previousPR =
                              widget.clientProfile?.strengthPRs[entry.key];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (previousPR != null)
                                      Text(
                                        '${previousPR.toStringAsFixed(1)} → ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 13,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      '${entry.value.toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Difficulty Rating
                const Text(
                  'RPE (Rate of Perceived Exertion)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(10, (index) {
                    final rating = index + 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          difficultyRating = rating;
                        });
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: difficultyRating == rating
                              ? const Color(0xFF2563EB)
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: difficultyRating == rating
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 = Very Easy',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '10 = Max Effort',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Feedback Text
                const Text(
                  'Additional Feedback (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'How did you feel? Any pain or discomfort? Notes for your instructor...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                feedbackController.dispose();
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () {
                // Create feedback string with rating and comments
                String feedback = '';
                if (difficultyRating != null) {
                  feedback += 'RPE: $difficultyRating/10\n';
                }
                feedback += 'Time: ${_formatTime(_elapsedSeconds)}\n';
                if (feedbackController.text.isNotEmpty) {
                  feedback += 'Notes: ${feedbackController.text}';
                }

                // Use the newPRs already calculated at dialog creation
                if (newPRs != null && newPRs.isNotEmpty) {
                  print('🎉 Processing ${newPRs.length} new PRs');
                  for (var entry in newPRs.entries) {
                    print('   ${entry.key}: ${entry.value} kg');
                  }
                  // Add PR info to feedback
                  feedback += '\n\n🏆 New PRs:\n';
                  for (var entry in newPRs.entries) {
                    feedback += '${entry.key}: ${entry.value} kg\n';
                  }
                } else {
                  print('   No new PRs this time');
                }

                // Create updated exercises with per-set weights and actual reps
                final updatedExercises = <Exercise>[];
                for (int i = 0; i < widget.workout.exercises.length; i++) {
                  final exercise = widget.workout.exercises[i];
                  final setWeights = _exerciseWeights[i];
                  final setReps = _exerciseReps[i];

                  if (exercise.isCardio) {
                    updatedExercises.add(
                      exercise.copyWith(
                        prescribedSets:
                            exercise.prescribedSets ?? exercise.sets,
                        prescribedReps:
                            exercise.prescribedReps ??
                            exercise.reps ??
                            Exercise.repsFromRange(exercise.repRange),
                        prescribedWeight:
                            exercise.prescribedWeight ?? exercise.weight,
                      ),
                    );
                    continue;
                  }

                  // Calculate average reps performed
                  final avgReps = setReps != null && setReps.isNotEmpty
                      ? (setReps.reduce((a, b) => a + b) / setReps.length)
                            .round()
                      : exercise.reps ??
                            Exercise.repsFromRange(exercise.repRange);

                  final updatedSets =
                      setWeights != null && setWeights.isNotEmpty
                      ? setWeights.length
                      : exercise.sets;

                  final avgWeight = setWeights != null && setWeights.isNotEmpty
                      ? setWeights.reduce((a, b) => a + b) / setWeights.length
                      : exercise.weight;

                  updatedExercises.add(
                    exercise.copyWith(
                      setWeights: setWeights,
                      setReps: setReps,
                      reps: avgReps,
                      sets: updatedSets,
                      prescribedSets: exercise.prescribedSets ?? exercise.sets,
                      prescribedReps:
                          exercise.prescribedReps ??
                          exercise.reps ??
                          Exercise.repsFromRange(exercise.repRange),
                      prescribedWeight:
                          exercise.prescribedWeight ?? exercise.weight,
                      weight: avgWeight != null
                          ? double.parse(avgWeight.toStringAsFixed(1))
                          : exercise.weight,
                    ),
                  );
                }

                // Update workout with feedback, per-set weights, and mark as completed
                final updatedWorkout = widget.workout.copyWith(
                  feedback: feedback,
                  isCompleted: true,
                  exercises: updatedExercises,
                );

                // Update PRs if any were found
                if (newPRs != null &&
                    newPRs.isNotEmpty &&
                    widget.onPRsUpdated != null) {
                  widget.onPRsUpdated!(newPRs);
                }

                // TODO: Save workout to storage and Firebase here if needed.
                feedbackController.dispose();
                Navigator.pop(context); // Close dialog
                Navigator.pop(
                  context,
                  updatedWorkout,
                ); // Close workout screen with updated workout

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Workout completed and sent to instructor for review!',
                    ),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Submit & Finish'),
            ),
          ],
        ),
      ),
    );
  }
}
