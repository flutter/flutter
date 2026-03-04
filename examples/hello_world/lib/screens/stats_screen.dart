import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../models/workout_stats.dart';
import '../services/app_controller.dart';
import '../services/training_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/placeholder_chart_card.dart';
import '../widgets/section_header.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final AppController controller;
  final TrainingService service;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String period = 'Uge';
  String exerciseFilter = 'Alle øvelser';
  String muscleFilter = 'Alle muskelgrupper';

  @override
  Widget build(BuildContext context) {
    final List<WorkoutSession> history = widget.controller.history;
    final WorkoutStats fallback = widget.service.getStats();
    final WorkoutStats stats = history.isEmpty ? fallback : _buildStatsFromHistory(history, fallback);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        const SectionHeader(title: 'Statistik'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'Uge', label: Text('Uge')),
                ButtonSegment<String>(value: 'Måned', label: Text('Måned')),
              ],
              selected: <String>{period},
              onSelectionChanged: (Set<String> value) {
                setState(() => period = value.first);
              },
            ),
            DropdownMenu<String>(
              initialSelection: exerciseFilter,
              label: const Text('Øvelse'),
              width: 180,
              dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                DropdownMenuEntry<String>(value: 'Alle øvelser', label: 'Alle øvelser'),
                DropdownMenuEntry<String>(value: 'Bænkpres', label: 'Bænkpres'),
                DropdownMenuEntry<String>(value: 'Squat', label: 'Squat'),
                DropdownMenuEntry<String>(value: 'Dødløft', label: 'Dødløft'),
              ],
              onSelected: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() => exerciseFilter = value);
              },
            ),
            DropdownMenu<String>(
              initialSelection: muscleFilter,
              label: const Text('Muskelgruppe'),
              width: 210,
              dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                DropdownMenuEntry<String>(value: 'Alle muskelgrupper', label: 'Alle muskelgrupper'),
                DropdownMenuEntry<String>(value: 'Bryst', label: 'Bryst'),
                DropdownMenuEntry<String>(value: 'Ben', label: 'Ben'),
                DropdownMenuEntry<String>(value: 'Ryg', label: 'Ryg'),
              ],
              onSelected: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() => muscleFilter = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.45,
          children: <Widget>[
            MetricCard(label: 'Samlede træninger', value: '${stats.weeklySessions * 4}'),
            MetricCard(label: 'Samlet volumen', value: '${stats.totalVolumeKg} kg'),
            MetricCard(label: 'Mest trænede øvelse', value: stats.mostTrainedExercise),
            MetricCard(label: 'Gns. træningstid', value: '${stats.avgWorkoutMinutes} min'),
          ],
        ),
        const SizedBox(height: 14),
        PlaceholderChartCard(title: 'Vægtudvikling', data: stats.weightTrend),
        const SizedBox(height: 10),
        PlaceholderChartCard(title: 'Styrkeudvikling (bænkpres)', data: stats.strengthTrend),
        const SizedBox(height: 14),
        const SectionHeader(title: 'PR-liste'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              const ListTile(title: Text('Bænkpres'), trailing: Text('92.5 kg x 3')),
              const Divider(height: 0),
              const ListTile(title: Text('Back Squat'), trailing: Text('140 kg x 2')),
              const Divider(height: 0),
              const ListTile(title: Text('Romanian Deadlift'), trailing: Text('155 kg x 5')),
              if (history.isNotEmpty) ...<Widget>[
                const Divider(height: 0),
                ListTile(
                  title: const Text('Seneste gennemførte pas'),
                  subtitle: Text(
                    '${history.first.title} • ${history.first.durationMinutes} min • ${history.first.totalSets} sæt',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Træningshistorik'),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ingen gemte træninger endnu. Start en træning fra Home for at opbygge historik.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...history.take(12).map(
                (WorkoutSession session) => Card(
                  child: ListTile(
                    title: Text(session.title),
                    subtitle: Text(
                      '${_formatDate(session.completedAt)} • ${session.durationMinutes} min • ${session.totalSets} sæt',
                    ),
                    trailing: Text(session.focus),
                  ),
                ),
              ),
      ],
    );
  }

  WorkoutStats _buildStatsFromHistory(List<WorkoutSession> history, WorkoutStats fallback) {
    final DateTime now = DateTime.now();
    final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    final List<WorkoutSession> thisWeek = history
        .where((WorkoutSession session) => session.completedAt.isAfter(weekStart))
        .toList(growable: false);

    final int totalMinutesWeek = thisWeek.fold<int>(
      0,
      (int sum, WorkoutSession session) => sum + session.durationMinutes,
    );
    final int avgWorkoutMinutes = history.isEmpty
        ? fallback.avgWorkoutMinutes
        : history.fold<int>(0, (int sum, WorkoutSession s) => sum + s.durationMinutes) ~/ history.length;

    final Map<String, int> exerciseCount = <String, int>{};
    for (final WorkoutSession session in history) {
      for (final String exercise in session.exercises) {
        exerciseCount[exercise] = (exerciseCount[exercise] ?? 0) + 1;
      }
    }

    String mostTrained = fallback.mostTrainedExercise;
    int mostCount = 0;
    exerciseCount.forEach((String key, int value) {
      if (value > mostCount) {
        mostCount = value;
        mostTrained = key;
      }
    });

    return WorkoutStats(
      weeklySessions: thisWeek.length,
      totalMinutesThisWeek: totalMinutesWeek,
      latestPr: fallback.latestPr,
      totalVolumeKg: fallback.totalVolumeKg,
      avgWorkoutMinutes: avgWorkoutMinutes,
      mostTrainedExercise: mostTrained,
      weightTrend: fallback.weightTrend,
      strengthTrend: fallback.strengthTrend,
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
