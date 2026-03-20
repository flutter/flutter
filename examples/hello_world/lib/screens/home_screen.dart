import 'package:flutter/material.dart';

import '../models/active_workout_draft.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/workout_stats.dart';
import '../services/app_controller.dart';
import '../services/training_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/section_header.dart';
import 'workout/widgets/minimized_workout_bar.dart';
import 'workout_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final AppController controller;
  final TrainingService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final UserProfile user = widget.service.getUserProfile();
    final Workout today = widget.service.getTodayWorkout();
    final Workout next = widget.service.getNextWorkout();
    final WorkoutStats stats = widget.service.getStats();
    final List<String> recent = widget.service.getRecentExercises();
    final recommendation = widget.service.getCoachMessages().first;

    final ActiveWorkoutDraft? activeWorkout = widget.controller.activeWorkoutDraft;
    final bool hasActive = activeWorkout != null;
    final bool showMinimized = hasActive && activeWorkout.isMinimized;

    return Stack(
      children: <Widget>[
        ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, showMinimized ? 92 : 24),
          children: <Widget>[
            Text(
              'Hej ${user.name} 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Dagens fokus: ${today.focus}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Dagens træning',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('${today.title} • ${today.durationMinutes} min'),
                    const SizedBox(height: 6),
                    Text(
                      'Næste planlagte workout: ${next.title} (${next.scheduledLabel})',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openWorkout(context),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(hasActive ? 'Fortsæt træning' : 'Start træning'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: 'Ugens overblik'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              children: <Widget>[
                MetricCard(
                  label: 'Ugens træninger',
                  value: '${stats.weeklySessions}',
                  icon: Icons.calendar_today,
                ),
                MetricCard(
                  label: 'Samlet tid',
                  value: '${stats.totalMinutesThisWeek} min',
                  icon: Icons.timer_outlined,
                ),
                MetricCard(
                  label: 'Seneste PR',
                  value: stats.latestPr,
                  icon: Icons.emoji_events_outlined,
                ),
                MetricCard(
                  label: 'Næste workout',
                  value: next.title,
                  subtitle: next.scheduledLabel,
                  icon: Icons.fitness_center,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: 'Seneste øvelser'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recent.map((String exercise) => Chip(label: Text(exercise))).toList(growable: false),
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: 'Coach anbefaling'),
            const SizedBox(height: 8),
            RecommendationCard(
              title: recommendation.title,
              message: recommendation.message,
              leadingIcon: Icons.psychology_alt_outlined,
            ),
          ],
        ),
        if (showMinimized)
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: MinimizedWorkoutBar(
              startedAt: activeWorkout.startedAt,
              exerciseCount: activeWorkout.exercises.length,
              onOpen: () => _openWorkout(context),
              onFinish: () async {
                await widget.controller.finishActiveWorkout();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Træning afsluttet og gemt')),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openWorkout(BuildContext context) async {
    widget.controller.startEmptyWorkout();
    widget.controller.resumeActiveWorkout();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutSessionScreen(controller: widget.controller),
      ),
    );
  }
}
