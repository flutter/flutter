import 'package:flutter/material.dart';

import '../../../app/state/training_controller.dart';
import '../../../app/state/training_scope.dart';
import '../../workout/domain/session_log.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TrainingController controller = TrainingScope.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<MapEntry<String, int>> topExercises = controller.topExercisesBySets.entries.take(3).toList();
    final List<SessionLog> recentSessions = controller.recentSessionHistory.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: ListTile(
            title: const Text('Sessions completed'),
            subtitle: Text('${controller.sessionHistory.length} total'),
            trailing: Text(
              '${controller.completedSessionsThisWeek} this week',
              style: textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Total sets logged'),
            trailing: Text(
              '${controller.totalSetsLogged}',
              style: textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Top exercises', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                if (topExercises.isEmpty)
                  const Text('Log a workout to see progression insights.')
                else
                  ...topExercises.map(
                    (MapEntry<String, int> entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${entry.key}: ${entry.value} sets'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Session history', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                if (recentSessions.isEmpty)
                  const Text('No completed sessions yet.')
                else
                  ...recentSessions.map(
                    (SessionLog log) {
                      final String workoutName = controller.workoutNameById(log.workoutTemplateId);
                      final int totalSets = log.setsByExercise.values.fold<int>(
                        0,
                        (int sum, int sets) => sum + sets,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(workoutName),
                                  Text(
                                    _formatDate(log.completedAt),
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text('$totalSets sets', style: textTheme.bodyMedium),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
