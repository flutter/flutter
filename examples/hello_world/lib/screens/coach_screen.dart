import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/workout.dart';
import '../services/training_service.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/section_header.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({
    required this.service,
    super.key,
  });

  final TrainingService service;

  @override
  Widget build(BuildContext context) {
    final List<CoachMessage> messages = service.getCoachMessages();
    final Workout next = service.getNextWorkout();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        const SectionHeader(title: 'Coach'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Personlig træningsplan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Næste workout: ${next.title} • ${next.scheduledLabel}'),
                const SizedBox(height: 6),
                Text('Fokusområder: ${next.focus}, teknik i hovedløft, stabil progression.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Dagens anbefalinger'),
        const SizedBox(height: 8),
        ...messages
            .where((CoachMessage item) => item.category == 'Plan' || item.category == 'Progression')
            .map(
              (CoachMessage item) => RecommendationCard(
                title: item.title,
                message: item.message,
                leadingIcon: Icons.tips_and_updates_outlined,
              ),
            ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Teknik, restitution og kost'),
        const SizedBox(height: 8),
        const RecommendationCard(
          title: 'Teknikråd',
          message: 'Hold 1-3 reps i reserve på hovedløft for stabil kvalitet gennem hele passet.',
          leadingIcon: Icons.sports_gymnastics,
        ),
        const RecommendationCard(
          title: 'Restitutionstip',
          message: 'Prioritér 7-9 timers søvn og planlæg en let dag efter 3-4 hårde pas.',
          leadingIcon: Icons.bedtime_outlined,
        ),
        const RecommendationCard(
          title: 'Kostråd',
          message: 'Spis protein i alle hovedmåltider og hold væskeindtaget stabilt før træning.',
          leadingIcon: Icons.restaurant_menu,
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Coachens vurdering'),
        const SizedBox(height: 8),
        ...messages
            .where((CoachMessage item) => item.category == 'Vurdering')
            .map(
              (CoachMessage item) => RecommendationCard(
                title: item.title,
                message: item.message,
                leadingIcon: Icons.analytics_outlined,
              ),
            ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Næste skridt'),
        const SizedBox(height: 8),
        ...messages
            .where((CoachMessage item) => item.category == 'Næste skridt')
            .map(
              (CoachMessage item) => RecommendationCard(
                title: item.title,
                message: item.message,
                leadingIcon: Icons.flag_outlined,
              ),
            ),
      ],
    );
  }
}
