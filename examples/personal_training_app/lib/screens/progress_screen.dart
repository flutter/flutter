import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/client_profile.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  final List<Workout> workouts;
  final ClientProfile clientProfile;
  final Function(ClientProfile) onProfileUpdated;

  const ProgressScreen({
    super.key,
    required this.workouts,
    required this.clientProfile,
    required this.onProfileUpdated,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late List<WeightEntry> _weightEntries;

  @override
  void initState() {
    super.initState();
    // Start with empty weight entries - client must enter their first weight
    _weightEntries = [];
  }

  void _addWeightEntry(double weight) {
    setState(() {
      _weightEntries.add(WeightEntry(date: DateTime.now(), weight: weight));
      _weightEntries.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ProgressScreenView(
      workouts: widget.workouts,
      weightEntries: _weightEntries,
      onWeightAdded: _addWeightEntry,
      clientProfile: widget.clientProfile,
      onProfileUpdated: widget.onProfileUpdated,
    );
  }
}

class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});
}

class _ProgressScreenView extends StatelessWidget {
  final List<Workout> workouts;
  final List<WeightEntry> weightEntries;
  final Function(double) onWeightAdded;
  final ClientProfile clientProfile;
  final Function(ClientProfile) onProfileUpdated;

  const _ProgressScreenView({
    required this.workouts,
    required this.weightEntries,
    required this.onWeightAdded,
    required this.clientProfile,
    required this.onProfileUpdated,
  });

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  void _showStrengthPRsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StrengthPRsDialog(
        strengthPRs: clientProfile.strengthPRs,
        onStrengthPRsUpdated: (updatedPRs) {
          final updatedProfile = clientProfile.copyWith(
            strengthPRs: updatedPRs,
          );
          onProfileUpdated(updatedProfile);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    final totalWorkouts = completedWorkouts.length;

    // Weekly improvement (%): compare completed workouts in last 7 days vs previous 7 days
    final now = DateTime.now();
    final startOfThisWindow = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final startOfPreviousWindow = startOfThisWindow.subtract(
      const Duration(days: 7),
    );

    final completedThisWeek = completedWorkouts
        .where(
          (w) => !w.date.isBefore(startOfThisWindow) && !w.date.isAfter(now),
        )
        .length;

    final completedPrevWeek = completedWorkouts
        .where(
          (w) =>
              !w.date.isBefore(startOfPreviousWindow) &&
              w.date.isBefore(startOfThisWindow),
        )
        .length;

    double weeklyImprovementPercent;
    if (completedPrevWeek == 0 && completedThisWeek == 0) {
      weeklyImprovementPercent = 0;
    } else if (completedPrevWeek == 0) {
      weeklyImprovementPercent = 100;
    } else {
      weeklyImprovementPercent =
          ((completedThisWeek - completedPrevWeek) / completedPrevWeek) * 100;
    }

    final weeklyImprovementLabel =
        '${weeklyImprovementPercent >= 0 ? '+' : ''}${weeklyImprovementPercent.toStringAsFixed(0)}%';
    final weeklyImprovementColor = weeklyImprovementPercent > 0
        ? Colors.green
        : weeklyImprovementPercent < 0
        ? Colors.red
        : Colors.blueGrey;

    // Calculate cardio statistics
    final totalCardioMinutes = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + w.totalCardioMinutes,
    );
    final totalCardioDistance = completedWorkouts.fold<double>(
      0.0,
      (sum, w) => sum + w.totalCardioDistanceKm,
    );
    final totalCardioSessions = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + w.cardioExerciseCount,
    );

    // Calculate consecutive completed workouts streak
    int consecutiveWorkouts = 0;
    if (completedWorkouts.isNotEmpty) {
      final sortedCompleted = List<Workout>.from(completedWorkouts)
        ..sort((a, b) => b.date.compareTo(a.date));

      consecutiveWorkouts = 1;
      for (int i = 0; i < sortedCompleted.length - 1; i++) {
        final current = sortedCompleted[i].date;
        final next = sortedCompleted[i + 1].date;
        final daysDiff = current.difference(next).inDays;

        if (daysDiff <= 7) {
          consecutiveWorkouts++;
        } else {
          break;
        }
      }
    }

    // Exercise frequency
    final exerciseFrequency = <String, int>{};
    for (final workout in completedWorkouts) {
      for (final exercise in workout.exercises) {
        exerciseFrequency[exercise.name] =
            (exerciseFrequency[exercise.name] ?? 0) + 1;
      }
    }
    final sortedExercises = exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track training consistency, PRs, cardio, and bodyweight trends.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _ProgressCard(
                title: 'Consecutive Workouts',
                value: '$consecutiveWorkouts',
                icon: Icons.fitness_center,
                color: Colors.blue,
              ),
              GestureDetector(
                onTap: () => _showStrengthPRsDialog(context),
                child: _ProgressCard(
                  title: 'Strength PRs',
                  value: '${clientProfile.strengthPRs.length}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
              _ProgressCard(
                title: 'Completed',
                value: '$totalWorkouts',
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
              _ProgressCard(
                title: 'Weekly Improve',
                value: weeklyImprovementLabel,
                icon: Icons.query_stats,
                color: weeklyImprovementColor,
              ),
            ],
          ),

          // Cardio Stats Section (if there are any cardio workouts)
          if (totalCardioSessions > 0) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              context,
              icon: Icons.directions_run,
              title: 'Cardio Statistics',
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ProgressCard(
                  title: 'Cardio Sessions',
                  value: '$totalCardioSessions',
                  icon: Icons.directions_run,
                  color: Colors.red,
                ),
                _ProgressCard(
                  title: 'Total Time',
                  value: '$totalCardioMinutes min',
                  icon: Icons.timer,
                  color: Colors.teal,
                ),
                if (totalCardioDistance > 0)
                  _ProgressCard(
                    title: 'Total Distance',
                    value: '${totalCardioDistance.toStringAsFixed(1)} km',
                    icon: Icons.straighten,
                    color: Colors.indigo,
                  ),
                if (totalCardioDistance > 0 && totalCardioMinutes > 0)
                  _ProgressCard(
                    title: 'Avg Pace',
                    value:
                        '${(totalCardioMinutes / totalCardioDistance).toStringAsFixed(1)} min/km',
                    icon: Icons.speed,
                    color: Colors.cyan,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          _buildSectionTitle(
            context,
            icon: Icons.fitness_center,
            title: 'Most Performed Exercises',
          ),
          const SizedBox(height: 12),

          if (sortedExercises.isNotEmpty)
            ...sortedExercises
                .take(5)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Chip(
                          label: Text('${entry.value} times'),
                          backgroundColor: Colors.blue[100],
                        ),
                      ),
                    ),
                  ),
                )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No exercises logged yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),
          _buildSectionTitle(
            context,
            icon: Icons.monitor_weight,
            title: 'Weight Progression',
          ),
          const SizedBox(height: 12),
          _WeightProgressionWidget(
            weightEntries: weightEntries,
            onWeightAdded: onWeightAdded,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(
            context,
            icon: Icons.analytics,
            title: 'Statistics',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatRow(
                    label: 'Completed Workouts',
                    value: '$totalWorkouts',
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Weekly Improvement',
                    value: weeklyImprovementLabel,
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Total Exercises',
                    value: '${exerciseFrequency.length}',
                  ),
                  if (totalCardioSessions > 0) ...[
                    const Divider(),
                    _StatRow(
                      label: 'Cardio Sessions',
                      value: '$totalCardioSessions',
                    ),
                    const Divider(),
                    _StatRow(
                      label: 'Total Cardio Time',
                      value: '$totalCardioMinutes min',
                    ),
                    if (totalCardioDistance > 0) ...[
                      const Divider(),
                      _StatRow(
                        label: 'Total Distance',
                        value: '${totalCardioDistance.toStringAsFixed(1)} km',
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthPRsDialog extends StatefulWidget {
  final Map<String, double> strengthPRs;
  final Function(Map<String, double>) onStrengthPRsUpdated;

  const _StrengthPRsDialog({
    required this.strengthPRs,
    required this.onStrengthPRsUpdated,
  });

  @override
  State<_StrengthPRsDialog> createState() => _StrengthPRsDialogState();
}

class _StrengthPRsDialogState extends State<_StrengthPRsDialog> {
  late Map<String, double> _prMap;
  late TextEditingController _exerciseController;
  late TextEditingController _weightController;
  String? _editingExerciseName;

  @override
  void initState() {
    super.initState();
    _prMap = Map.from(widget.strengthPRs);
    _exerciseController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _addOrUpdatePR() {
    final exercise = _exerciseController.text.trim();
    final weight = double.tryParse(_weightController.text);

    if (exercise.isNotEmpty && weight != null && weight > 0) {
      setState(() {
        if (_editingExerciseName != null && _editingExerciseName != exercise) {
          _prMap.remove(_editingExerciseName);
        }
        _prMap[exercise] = weight;
        _editingExerciseName = null;
        _exerciseController.clear();
        _weightController.clear();
      });
    }
  }

  void _startEditPR(String exercise) {
    setState(() {
      _editingExerciseName = exercise;
      _exerciseController.text = exercise;
      _weightController.text = _prMap[exercise]?.toString() ?? '';
    });
  }

  void _removePR(String exercise) {
    setState(() {
      _prMap.remove(exercise);
      if (_editingExerciseName == exercise) {
        _editingExerciseName = null;
        _exerciseController.clear();
        _weightController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Strength PRs'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // List of existing PRs
              if (_prMap.isNotEmpty) ...[
                Text(
                  'Your PRs:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ..._prMap.entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(entry.key),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.value.toStringAsFixed(1)} kg',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit PR',
                            onPressed: () => _startEditPR(entry.key),
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 40,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removePR(entry.key),
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 40,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No PRs set yet',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Add new PR
              Text(
                _editingExerciseName == null ? 'Add New PR:' : 'Edit PR:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _exerciseController,
                decoration: const InputDecoration(
                  hintText: 'Exercise name (e.g., Bench Press)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final exercise = _exerciseController.text.trim();
            final weight = double.tryParse(_weightController.text);
            if (exercise.isNotEmpty && weight != null && weight > 0) {
              _addOrUpdatePR();
            }
          },
          child: Text(_editingExerciseName == null ? 'Add' : 'Update'),
        ),
        if (_editingExerciseName != null)
          TextButton(
            onPressed: () {
              setState(() {
                _editingExerciseName = null;
                _exerciseController.clear();
                _weightController.clear();
              });
            },
            child: const Text('Cancel Edit'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            widget.onStrengthPRsUpdated(_prMap);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated ${_prMap.length} strength PR(s)'),
                backgroundColor: const Color(0xFF059669),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _WeightProgressionWidget extends StatefulWidget {
  final List<WeightEntry> weightEntries;
  final Function(double) onWeightAdded;

  const _WeightProgressionWidget({
    required this.weightEntries,
    required this.onWeightAdded,
  });

  @override
  State<_WeightProgressionWidget> createState() =>
      _WeightProgressionWidgetState();
}

class _WeightProgressionWidgetState extends State<_WeightProgressionWidget> {
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _showAddWeightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter weight in kg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(_weightController.text);
              if (weight != null && weight > 0) {
                widget.onWeightAdded(weight);
                _weightController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Weight logged: ${weight}kg'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...widget.weightEntries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final currentWeight = widget.weightEntries.isNotEmpty
        ? widget.weightEntries.last.weight
        : 0.0;
    final startWeight = widget.weightEntries.isNotEmpty
        ? widget.weightEntries.first.weight
        : 0.0;
    final weightChange = currentWeight - startWeight;
    final weightChangeStr = weightChange > 0
        ? '+${weightChange.toStringAsFixed(1)}'
        : weightChange.toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.weightEntries.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Weight',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentWeight.toStringAsFixed(1)} kg',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2563EB),
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: weightChange > 0
                              ? Colors.red[50]
                              : weightChange < 0
                              ? Colors.green[50]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: weightChange > 0
                                ? Colors.red[300]!
                                : weightChange < 0
                                ? Colors.green[300]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Change',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              '$weightChangeStr kg',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: weightChange > 0
                                    ? Colors.red[700]
                                    : weightChange < 0
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Weight History',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(entry.date),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${entry.weight.toStringAsFixed(1)} kg',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No weight entries yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddWeightDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Log Weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
