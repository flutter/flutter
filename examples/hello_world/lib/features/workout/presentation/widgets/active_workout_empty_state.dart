import 'package:flutter/material.dart';

import '../../../../widgets/foundation/app_card.dart';
import '../../../../theme/app_spacing.dart';

class ActiveWorkoutEmptyState extends StatelessWidget {
  const ActiveWorkoutEmptyState({
    required this.onAddExercise,
    super.key,
  });

  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: <Widget>[
          const Icon(Icons.fitness_center, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Din træning er startet',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tilføj din første øvelse for at begynde.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Tilføj øvelse'),
            ),
          ),
        ],
      ),
    );
  }
}
