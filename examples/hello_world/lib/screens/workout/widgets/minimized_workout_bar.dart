import 'package:flutter/material.dart';

class MinimizedWorkoutBar extends StatelessWidget {
  const MinimizedWorkoutBar({
    required this.elapsed,
    required this.exerciseCount,
    required this.onOpen,
    required this.onFinish,
    super.key,
  });

  final String elapsed;
  final int exerciseCount;
  final VoidCallback onOpen;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.fitness_center),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Workout i gang • $elapsed', style: Theme.of(context).textTheme.labelLarge),
                    Text('$exerciseCount øvelser', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              TextButton(onPressed: onFinish, child: const Text('Afslut')),
            ],
          ),
        ),
      ),
    );
  }
}
